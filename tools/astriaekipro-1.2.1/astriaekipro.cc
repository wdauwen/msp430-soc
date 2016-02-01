/**[txh]********************************************************************

  Copyright (c) 2009 Salvador E. Tropea <salvador at inti gob ar>
  Copyright (c) 2009 Instituto Nacional de Tecnología Industrial

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, version 2 of the License.

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

  Title: ASTriAEKiPro

  Description:
  Avnet Spartan 3A Eval Kit programmer.
  This program can send an FPGA configuration to the Spartan 3A, the serial
SPI flash or the parallel flash.

  Acknowledgements:
  * I took some ideas from Jason Milldrum avs3a tool.
  * Bryan Fletcher (from Avnet) provided the information needed to use the
  BPI server.
  * The bpi_server_v036.h file is the bitstream for Avnet's BPI server
  version 036. Coded by Bryan Fletcher and Ron Wright.
  * Most of the programming information comes from the following documents
  provided by Avnet:
  Spartan3A_Eval_Programming_Algorithms_v1_0.pdf
  Spartan3A_Eval_PSoC_SoftwareUserGuide_v1_0.pdf
  avt_s25fl128p_64kb.sfh

***************************************************************************/

#define CPPFIO_I
#define CPPFIO_I_stdlib
#define CPPFIO_I_unistd
#define CPPFIO_I_string
#define CPPFIO_CmdLine
#define CPPFIO_ComSerie
#define CPPFIO_PTimer
#define CPPFIO_ErrorLog
#define CPPFIO_File
#define CPPFIO_Chrono
#define CPPFIO_Helpers
#include <cppfio.h>

#include <fcntl.h>
#include <ctype.h>
#include "bitfile.h"
#include "flash_cnts.h"
#if BPI_SERVER
 #include "bpi_server.h"
#else
unsigned char bpi_server_h_data[0];
#endif

// We are inside the cppfio namespace
using namespace cppfio;

ErrorLog error(stderr);

/*****************************************************************************
  Command line stuff
*****************************************************************************/

#define VERSION "1.2.1"
#define CMD_NAME "astriaekipro"

CmdLineParser clp;

static const char *portName="/dev/ttyACM0";
static char *bitStreamName=NULL;
static char *bpiServerFile=NULL;
static bool doSlaveSerial=false;
static bool doFlashCheck=false;
static bool doReadBack=false;
static bool doReadBackBPI=false;
static bool doWrite=false;
static bool doWriteBPI=false;
static bool doErase=false;
static bool doEraseBPI=false;
static bool doVerify=false;
static bool doVerifyBPI=false;
static bool doDumpBit=false;
static bool doTerminal=false;
static bool doBPIServer=false;
static bool doBoot=false;
static bool doBootBPI=false;
static long memOffset=0;
static long bytesUsed=-1;
static const char *outputFile=NULL;
static bool dumpCMode=false;
typedef enum
{
 bpi_direct,  // Data is unchanged
 bpi_8,       // Bit reversed, for bitstreams
 bpi_16,      // Bit reversed and bytes swapped, for bitstreams and the normal
              // BPI server
 bpi_swap,    // Swap bytes
 bpi_invalid  // The user specified an invalid mode
} bpi_mode_t;
static bpi_mode_t bpiByteMode=bpi_16;

static
void PrintCopy(FILE *f)
{
 fprintf(f,"Copyright (c) 2009 Salvador E. Tropea <salvador at inti gob ar>\n");
 fprintf(f,"Copyright (c) 2009 Instituto Nacional de Tecnología Industrial\n");
 fprintf(f,"Embedded BPI server provided by Avnet Inc. http://www.em.avnet.com/\n");
}

static
void PrintPrgInfo()
{
 if (clp.GetVerbosity()<0) // Disabled when using --quiet
    return;
 fputs("Avnet Spartan 3A Eval Kit Programmer v"VERSION"\n",stderr);
 PrintCopy(stderr);
 fputc('\n',stderr);
}

static
void PrintHelp()
{
 puts("Usage:\n"CMD_NAME" [options] [operations]\n");
 puts("Operations:");
 puts("-d, --dump-bit            Dump bitstream");
 puts("-c, --flash-check         Check SPI flash ID");
 puts("-r, --read-back           Read from SPI flash");
 puts("-R, --read-back-bpi       Read from BPI flash");
 puts("-e, --erase               Erase the SPI flash");
 puts("-E, --erase-bpi           Erase the BPI flash");
 puts("-w, --write               Write to the SPI flash");
 puts("-W, --write-bpi           Write to the BPI flash");
 puts("-y, --verify              Verify SPI flash content");
 puts("-Y, --verify-bpi          Verify BPI flash content");
 puts("-f, --boot                Configure the FGA from the SPI flash");
 puts("-F, --boot-bpi            Configure the FGA from the BPI flash");
 puts("-s, --slaveser            Configure FPGA in Slave Serial mode");
 puts("-i, --send-server         Configure FPGA with the BPI server");
 puts("-t, --terminal            Terminal mode");
 puts("\nOptions:");
 puts("-p, --port=NAME           Serial port connected to eval board [/dev/ttyACM0]");
 puts("-b, --bitstream=FILE      Bitstream used to configure FPGA");
 puts("-o, --offset              Offset in SPI flash");
 puts("-B, --bytes=BYTES         Number of bytes");
 puts("-O, --output=FILENAME     Output file name");
 puts("-m, --bpi-mode=MODE       BPI byte mode: direct, 16, 8 or swap [16]");
 puts("-C, --c-dump              Dump as C code");
 puts("-S, --bpi-server=NAME     Bitstream to use as BPI server");
 puts("\nOthers:");
 clp.PrDefaultOptions(stdout);
 puts("");
 exit(1);
}

static
void PrintVersion()
{
 FILE *f=stdout;

 fputs(CMD_NAME" v"VERSION"\n",f);
 PrintCopy(f);
 clp.PrintGPL(f);
 fprintf(f,"\nAuthor: Salvador E. Tropea.\n");
}

static
void BPIModeConv(char *arg)
{
 if (strcmp(arg,"direct")==0)
    bpiByteMode=bpi_direct;
 else if (strcmp(arg,"16")==0)
    bpiByteMode=bpi_16;
 else if (strcmp(arg,"8")==0)
    bpiByteMode=bpi_8;
 else if (strcmp(arg,"swap")==0)
    bpiByteMode=bpi_swap;
 else
    bpiByteMode=bpi_invalid;
}

static
struct clpOption longopts[]=
{
  { "bitstream",     'b', argRequired, &bitStreamName, argString },
  { "bytes",         'B', argRequired, &bytesUsed,     argInteger },
  { "flash-check",   'c', argNo,       &doFlashCheck,  argBool },
  { "c-dump",        'C', argNo,       &dumpCMode,     argBool },
  { "dump-bit",      'd', argNo,       &doDumpBit,     argBool },
  { "erase",         'e', argNo,       &doErase,       argBool },
  { "erase-bpi",     'E', argNo,       &doEraseBPI,    argBool },
  { "boot",          'f', argNo,       &doBoot,        argBool },
  { "boot-bpi",      'F', argNo,       &doBootBPI,     argBool },
  { "send-server",   'i', argNo,       &doBPIServer,   argBool },
  { "bpi-mode",      'm', argRequired, (void *)BPIModeConv, argFunction },
  { "offset",        'o', argRequired, &memOffset,     argInteger },
  { "output",        'O', argRequired, &outputFile,    argString },
  { "port",          'p', argRequired, &portName,      argString },
  { "read-back",     'r', argNo,       &doReadBack,    argBool },
  { "read-back-bpi", 'R', argNo,       &doReadBackBPI, argBool },
  { "slaveser",      's', argNo,       &doSlaveSerial, argBool },
  { "bpi-server",    'S', argRequired, &bpiServerFile, argString },
  { "terminal",      't', argNo,       &doTerminal,    argBool },
  { "write",         'w', argNo,       &doWrite,       argBool },
  { "write-bpi",     'W', argNo,       &doWriteBPI,    argBool },
  { "verify",        'y', argNo,       &doVerify,      argBool },
  { "verify-bpi",    'Y', argNo,       &doVerifyBPI,   argBool },
  { NULL, 0, argNo, NULL, argBool }
};

cmdLineOpts opts=
{
 PrintPrgInfo, PrintHelp, PrintVersion, longopts, -1
};

/*****************************************************************************
  End of command line stuff
*****************************************************************************/

const unsigned maxLen=1024;
//static char b[maxLen];
static ComSerie *ser;

const int
   cmdLoadConfig=0,
   cmdDriveProg=1,
   cmdDriveMode=2,
   cmdSPIMode=3,
   cmdReadInit=4,
   cmdReadDone=5,
   cmdSFTransfer=6,
   cmdSSProgram=7,
   cmdJTAGMux=8,
   cmdGetConfig=9,
   cmdUSBBridge=10,
   cmdFPGAReset=11,
   cmdGetVer=12;
typedef enum {cfgUART=0, cfgSPI=1, cfgJTAG=2} cfg_t;
static cfg_t currentMode=cfgUART; // Assume we are in UART mode and the FPGA
                                  // can interfere.
typedef enum {drvLow=0, drvHigh=1} drv_t;
typedef enum {modMasterSerial=0, modMasterSPI=1, modBPIUp=2, modJTAG=5,
              modSlaveParallel=6, modSlaveSerial=7, modTriState=8 } mod_t;
const char *num2Str[9]={"0","1","2","3","4","5","6","7","8"};
const unsigned maxPSoCBuf=64;
const unsigned maxCmdLen=maxPSoCBuf;
typedef enum { do_read, do_verify } op_t;

static const uchar flashID[flNIDB]={flIDV0,flIDV1,flIDV2,flIDV3,flIDV4};
static const uchar flashMask[flNIDB]={flIDM0,flIDM1,flIDM2,flIDM3,flIDM4};

/*****************************************************************************
   Low level communication stuff
*****************************************************************************/

static unsigned ReadTO(char *buffer, unsigned size, bool exact=true,
                       unsigned toMult=1);

static
unsigned ReadTO(char *buffer, unsigned size, bool exact, unsigned toMult)
{
 unsigned read;
 PTimer to(100000*toMult); // 100 ms time-out
 do
   {
    read=ser->RawRead(buffer,size,exact);
    if (!read)
       usleep(1000);
    //printf("read: %d to.Reached() %d\n",read,to.Reached());
   }
 while (!read && !to.Reached());
 return read;
}

static
void DumpChars(uchar *b, unsigned off)
{
 for (unsigned i=off; (i%16)!=15; i++)
     printf("   ");
 printf(" | ");
 for (unsigned i=off&(~0xF); i<=off; i++)
     fputc((b[i]&0x7F)<32 ? '_' : b[i],stdout);
 puts("");
}
static
void DumpBytes(const char *op, uchar *b, unsigned sz)
{
 if (clp.GetVerbosity()<2)
    return;
 printf("%s %d bytes:\n",op,sz);
 unsigned i;
 for (i=0; i<sz; i++)
    {
     printf("%02X ",b[i]);
     if ((i%16)==15)
        DumpChars(b,i);
    }
 if (i%16)
    DumpChars(b,i-1);
}

static
bool GetACK()
{
 if (currentMode!=cfgUART)
   {
    char reply[4];
    unsigned read=ReadTO(reply,4);
    if (read)
      {// Verify this is ack
       if (reply[3] || strcmp(reply,"ack"))
          error.Abort("Got a reply different than ACK! <0x%02X 0x%02X 0x%02X 0x%02X>",
                      reply[0] & 0xFF,reply[1] & 0xFF,reply[2] & 0xFF,reply[3] & 0xFF);
       clp.printIfV(2,"Got <ack>\n");
       return true;
      }
   }
 else
   {// In UART mode the FPGA can send bogus data.
    // We discard it until an ACK is detected.
    char buf[maxPSoCBuf];
    unsigned read;
    while ((read=ReadTO(buf,maxPSoCBuf,false))!=0)
      {
       DumpBytes("UART data",(uchar *)buf,read);
       if (strcmp(buf+read-4,"ack")==0)
         {
          clp.printIfV(2,"Got <ack>\n");
          return true;
         }
      }
   }
 return false;
}

static
void RawWriteRead(uchar *buffer, unsigned total,
                  int (*cb)(uchar *, unsigned , void *), void *extra,
                  bool doRead)
{
 unsigned toTx;
 uchar *txb;

 txb=buffer;
 while (total)
   {
    toTx=total;
    if (toTx>maxPSoCBuf)
       toTx=maxPSoCBuf;
    // Write chunk
    ser->Send(txb,toTx);
    DumpBytes("Sending",txb,toTx);
    if (doRead)
      {// Read chunk
       unsigned bytesRcvd=ReadTO((char *)txb,toTx);
       if (bytesRcvd!=toTx)
          error.Abort("Read %d and not %d bytes\n",bytesRcvd,toTx);
       DumpBytes("Got",txb,toTx);
      }
    // Get ACK
    if (!GetACK())
       error.Abort("Time-out waiting for ACK");
    // Process
    if (cb)
       cb(txb,toTx,extra);
    // Next chunk
    total-=toTx;
    txb+=toTx;
   }
}

/*****************************************************************************
   PSoC commands
*****************************************************************************/

static void SendCommand(const char *name, const char *arg=NULL);

static
void SendCommand(const char *name, const char *arg)
{
 char command[maxCmdLen];
 unsigned len;

 if (arg)
    len=snprintf(command,maxCmdLen,"%s %s",name,arg);
 else
    len=snprintf(command,maxCmdLen,"%s",name);
 clp.printIfV(2,"Sending <%s>\n",command);

 int retry=5;
 do
   {// Send the command
    ser->Send(command,len+1);
    // Wait for ACK
    if (GetACK())
       return;
   }
 while (--retry);
 error.Abort("Time-out while sending <%s> command",command);
}

static
void LoadConfig(cfg_t config)
{
 SendCommand("load_config",num2Str[config]);
 currentMode=config;
}

static
void DriveProg(drv_t drive)
{
 SendCommand("drive_prog",num2Str[drive]);
}

static
void FPGAReset(drv_t drive)
{
 SendCommand("fpga_rst",num2Str[drive]);
}

static
void DriveMode(mod_t mode)
{
 SendCommand("drive_mode",num2Str[mode]);
}

static
void SPIMode(drv_t drive)
{
 SendCommand("spi_mode",num2Str[drive]);
}

static
bool ReadInit()
{
 SendCommand("read_init");
 char val;
 if (!ReadTO(&val,1) || !GetACK())
    error.Abort("read_init time-out");
 return bool(val);
}

static
bool ReadDone()
{
 SendCommand("read_done");
 char val;
 if (!ReadTO(&val,1) || !GetACK())
    error.Abort("read_done time-out");
 return bool(val);
}

static
void GetVer()
{
 char buf[maxPSoCBuf];
 ser->Send("get_ver",8);
 if (!ReadTO(buf,maxPSoCBuf,false))
    error.Abort("get_ver time-out");
 printf("PSoC firmware version: %s\n\n",buf);
 GetACK();
}

static
void SFTransfer(unsigned size)
{
 char buf[maxCmdLen];
 snprintf(buf,maxCmdLen,"%d",size);
 SendCommand("sf_transfer",buf);
}

static
void DoSFTransfer(uchar *buffer, unsigned total,
                  int (*cb)(uchar *, unsigned , void *)=NULL, void *extra=NULL);

static
void DoSFTransfer(uchar *buffer, unsigned total,
                  int (*cb)(uchar *, unsigned , void *), void *extra)
{
 SFTransfer(total);
 RawWriteRead(buffer,total,cb,extra,true);
 GetACK();
}

static
uchar DoSFTransfer(int command, ...)
{
 va_list argptr;

 va_start(argptr,command);
 unsigned total=1;
 while (va_arg(argptr,int)!=-1)
    total++;
 va_end(argptr);

 uchar buffer[total];
 buffer[0]=command;
 int val;
 total=1;
 va_start(argptr,command);
 while ((val=va_arg(argptr,int))!=-1)
    buffer[total++]=val;
 va_end(argptr);

 SFTransfer(total);
 RawWriteRead(buffer,total,NULL,NULL,true);
 GetACK();

 return buffer[1];
}

static
void SSProgram(unsigned size)
{
 char buf[maxCmdLen];
 snprintf(buf,maxCmdLen,"%d",size);
 SendCommand("ss_program",buf);
}

static
void DoSSProgram(uchar *buffer, unsigned total,
                 int (*cb)(uchar *, unsigned , void *), void *extra)
{
 SSProgram(total);
 RawWriteRead(buffer,total,cb,extra,false);
 GetACK();
}

/*****************************************************************************
  SPI flash helper functions
*****************************************************************************/

static
void GetFlashID(uchar *buffer)
{
 int i;
 uchar aux[flNIDB+1+4];

 aux[0]=flRDID;
 for (i=0; i<flNIDB; i++)
     aux[i+1]=flDUMB;
 DoSFTransfer(aux,flNIDB+1);
 memcpy(buffer,aux+1,flNIDB);
}

static
bool CheckFlashID()
{
 int i;
 uchar curFlashID[flNIDB];

 GetFlashID(curFlashID);
 if (clp.GetVerbosity()>0 || doFlashCheck)
   {
    printf("SPI flash ID: ");
    for (i=0; i<flNIDB; i++)
        printf("%02X ",curFlashID[i]);
    puts("");
   }
 for (i=0; i<flNIDB; i++)
     if ((curFlashID[i] & flashMask[i])!=flashID[i])
       {
        error.Error("SPI flash ID didn't match");
        return false;
       }
 if (clp.GetVerbosity()>0 || doFlashCheck)
    printf("SPI flash ID ok! (%s %s)\n",flMFCG,flDEVI);
 return true;
}

static
bool SFOStart()
{
 LoadConfig(cfgSPI);    //  1. Load SPI configuration
 DriveProg(drvLow);     //  2. Drive PROG low [The FPGA can interfere with the SPI communication]
 SPIMode(drvLow);       //  3. Drive PSOC_SPI_MODE low
 return CheckFlashID(); //  4. Read and verify device ID from serial flash
}

static
void SFOEnd()
{
 DriveProg(drvHigh);  //  6. Release PROG
 LoadConfig(cfgUART); //  7. Load UART configuration
}

static
bool SFOBoot()
{
 LoadConfig(cfgSPI);      //  1. Load SPI configuration
 DriveProg(drvLow);       //  2. Drive PROG low
 SPIMode(drvLow);         //  3. Drive PSOC_SPI_MODE low
 DriveMode(modMasterSPI); //  4. Drive M[2:0]
 DriveProg(drvHigh);      //  5. Release PROG
 DriveMode(modTriState);  //  6. Drive M[2:0] to tri-state
 LoadConfig(cfgUART);     //  7. Load UART configuration

 if (0) // I can't get it working
   {
    // Wait for a while
    usleep(1000000);
    LoadConfig(cfgSPI);
    printf("init: %d\n",ReadInit());
    bool ok=ReadDone();
    if (ok)
       error.Error("DONE didn't go high");
    else
       printf("Done!\n");
    LoadConfig(cfgUART);
    return ok;
   }
 return true;
}

static
void SFOFillAddress(uchar *buffer, uchar command, unsigned address)
{
 unsigned mask;

 buffer[0]=command;
 mask=0xFF<<((flABSZ-1)*8);
 for (unsigned i=0; i<(unsigned)flABSZ; i++)
    {
     buffer[i+1]=(address & mask)>>((flABSZ-1-i)*8);
     mask>>=8;
    }
}

static inline
void SFOWriteEnableFlash()
{
 DoSFTransfer(flWREN,-1); // Write enable flash
}

static inline
void SFOWriteEnableStatusReg()
{
 DoSFTransfer(flWESR,-1); // Write enable status register
}

static inline
void SFOWriteDisableFlash()
{
 DoSFTransfer(flWRDI,-1); // Write disable flash
}

static inline
void SFOWriteDisableStatusReg()
{
 DoSFTransfer(flWDSR,-1); // Write disable status register
}

static inline
void SFOBulkErase()
{
 DoSFTransfer(flBLKE,-1); // Bulk Erase
}

static
void WaitComplete(uchar mask, uchar expected, int times)
{
 int c;

 times*=10; // Increase the counter to reduce the delay
 for (c=0; c<times; c++)
    {
     uchar status=DoSFTransfer(flRDSR,flDUMB,-1); // Read Status Register
     if ((status & mask)==expected)
        return;
     usleep(100000);
    }
 error.Abort("Time-out waiting for PSoC completion, tried %d times",times);
}

static inline
void SFOWaitErase()
{
 WaitComplete(flESTM,flESST,flMEPI);
}

static inline
void SFOWaitProgram()
{
 WaitComplete(flPSTM,flPSST,flMPPI);
}

static
void PrintElapsed(Chrono &t, unsigned size)
{
 double elapsed=t.Stop();
 clp.printIfV(1,"Elapsed time: %5.2f s (%.2f kB/s)\n",elapsed,
              size/elapsed/1024.0);
}

/*****************************************************************************
  SPI Flash Operations
*****************************************************************************/

static
bool SFOCheck()
{
 LoadConfig(cfgSPI);
 bool res=CheckFlashID();
 LoadConfig(cfgUART);
 return res;
}

// SPI memory read structure
typedef struct
{
 int count;
 int total;
 File *f;
} rhelper_t;

// SPI memory read callback
static
int ReadHelper(uchar *data, unsigned size, void *extra)
{
 rhelper_t *p=(rhelper_t *)extra;

 if (p->count==0)
   {
    data+=flABSZ+1;
    size-=flABSZ+1;
   }
 p->count+=size;
 clp.printIfV(0,"Bytes read: %8d (%5.2f %%)\r",p->count,p->count*100.0/p->total);
 clp.printIfV(2,"\n");
 fflush(stdout);
 p->f->Write(data,size);
 return 1;
}

/* SPI memory verify structure */
typedef struct
{
 int count;
 int total;
 uchar *reference;
 int fails;
} vhelper_t;

/* SPI memory verify callback */
static
int VerifyHelper(uchar *data, unsigned size, void *extra)
{
 vhelper_t *p=(vhelper_t *)extra;

 if (p->count==0)
   {
    data+=flABSZ+1;
    size-=flABSZ+1;
   }
 if (memcmp(data,p->reference+p->count,size))
    p->fails++;
 p->count+=size;
 clp.printIfV(0,"Bytes verified: %8d (%5.2f %%) %3d failed\r",p->count,
              p->count*100.0/p->total,p->fails);
 clp.printIfV(2,"\n");
 fflush(stdout);
 return p->fails;
}

static
bool SFOReadVerify(op_t mode, uchar *data, unsigned size)
{
 unsigned offset, total;
 uchar *buffer;
 File *f=NULL;
 vhelper_t vhelper_data;
 rhelper_t rhelper_data;

 offset=memOffset;
 if (flBPRD-offset<size)
   {
    error.Error("Range is out of memory (%d+%d>%d)\n",offset,
              size,flBPRD);
    return false;
   }

 if (mode==do_read)
    f=new File(outputFile,"wb");

 bool result=false;
 if (SFOStart())
   {// Create the write/read buffer
    total=size+1+flABSZ;
    buffer=new uchar[total];
    memset(buffer,flDUMB,total);
    SFOFillAddress(buffer,flREAD,offset);
    // Do the transfer
    Chrono t;
    if (mode==do_read)
      {
       rhelper_data.count=0;
       rhelper_data.total=size;
       rhelper_data.f=f;
       DoSFTransfer(buffer,total,ReadHelper,&rhelper_data);
       // Clean up
       delete f;
       clp.printIfV(0,"\nAll read!\n");
       result=true;
      }
    else if (mode==do_verify)
      {
       vhelper_data.count=0;
       vhelper_data.total=size;
       vhelper_data.reference=data;
       vhelper_data.fails=0;
       DoSFTransfer(buffer,total,VerifyHelper,&vhelper_data);
       if (vhelper_data.fails)
          clp.printIfV(0,"\n%d blocks failed\n",vhelper_data.fails);
       else
         {
          clp.printIfV(0,"\nAll ok!\n");
          result=true;
         }
      }
    PrintElapsed(t,size);
    delete[] buffer;
   }

 SFOEnd();

 return result;
}

static
void SFOUnprotectAll()
{// Unprotect sectors
 SFOWriteEnableStatusReg();
 DoSFTransfer(flWRSR,flUABL,-1); // Write to status register: Unprotect all blocks
 SFOWaitProgram();
 SFOWriteDisableStatusReg();
}

static
void DoBulkErase()
{// Bulk Erase
 SFOWriteEnableFlash();
 SFOBulkErase();
 SFOWaitErase();
 SFOWriteDisableFlash();
}

bool SFOEraseAll()
{
 bool rc=SFOStart();
 if (rc)
   {
    SFOUnprotectAll();
    Chrono t;
    puts("Erasing the memory, be patient (>1 minute) ..."); // 1m 15s
    DoBulkErase();
    PrintElapsed(t,flBPRD);
   }
 SFOEnd();
 return rc;
}

static
void SFOEraseRange(unsigned from, unsigned size)
{
 unsigned sectorSize=flPPRS*flBPRP;
 unsigned firstSector=from/sectorSize;
 unsigned lastSector=(from+size)/sectorSize;
 unsigned sector=firstSector;
 double deltaSector=100.0/(lastSector-firstSector+1);
 uchar buffer[4];

 Chrono t;
 for (; sector<=lastSector; sector++)
    {
     clp.printIfV(0,"Erasing: sector %3d (%5.2f %%)\r",sector,
                  (sector-firstSector+1)*deltaSector);
     fflush(stdout);
     SFOWriteEnableFlash();
     SFOFillAddress(buffer,flSECE,sector*sectorSize); // Sector Erase
     DoSFTransfer(buffer,4);
     SFOWaitErase();
    }
 clp.printIfV(0,"\n");
 PrintElapsed(t,size);
}

static
bool SFOWrite(uchar *data, unsigned size)
{
 int dataIndex, page1, page2;
 uchar buffer[flMBPP+flABSZ+1];
 unsigned toWrite, offset, n, total, writeTotal, i;

 toWrite=size;
 offset=memOffset;
 if (offset+size>(unsigned)flBPRD)
   {
    error.Error("Range is out of memory (%d+%d>%d)\n",offset,size,flBPRD);
    return false;
   }

 bool result=false;
 if (SFOStart())
   {
    SFOUnprotectAll();
    SFOEraseRange(offset,size);

    Chrono t;
    // Transfer data
    writeTotal=0;
    dataIndex=0;
    while (toWrite)
      {
       SFOWriteEnableFlash();
       n=toWrite;
       // Limit to the page size
       if (n>(unsigned)flMBPP)
          n=flMBPP;
       // Avoid crossing pages
       page1=(offset+1)/flMBPP;
       page2=(offset+n)/flMBPP;
       if (page1!=page2)
          n=page2*flMBPP-offset;
       total=n+flABSZ+1;
       // Create the write/read buffer
       SFOFillAddress(buffer,flPGPM,offset);
       for (i=flABSZ; i+1<total; i++)
           buffer[i+1]=data[dataIndex++];
       // Do the transfer
       DoSFTransfer(buffer,total);
       // Next chunk
       SFOWaitProgram();
       toWrite-=n;
       offset+=n;
       writeTotal+=n;
       clp.printIfV(0,"Bytes written: %8d (%5.2f %%)\r",writeTotal,writeTotal/(float)size*100);
       fflush(stdout);
      }
    clp.printIfV(0,"\nAll written!\n");
    PrintElapsed(t,size);
    result=true;
   }
 SFOEnd();

 return result;
}

/*****************************************************************************
  BitStream dumper
*****************************************************************************/

void DumpBitStream(const char *filename, uchar *bitStream,
                   unsigned bitStreamLen)
{
 clp.printIfV(0,"Dumping bitstream to: %s\n",filename);
 if (dumpCMode)
   {
    File fp(filename,"wt");
    char *s=newStr(filename);
    for (char *t=s; *t; t++)
        if (!isalnum(*t))
           *t='_';
    fp.Print("unsigned char %s_data[%d]=\n{\n",s,bitStreamLen);
    for (unsigned i=0; i<bitStreamLen; i++)
       {
        fp.Print("0x%02X",bitStream[i]);
        if (i+1<bitStreamLen)
          {
           fp.Write(',');
           if (((i+1)%16)==0)
              fp.Write('\n');
          }
        else
           fp.Write('\n');
       }
    fp.Write("};\n",3);
   }
 else
   {
    File fp(filename,"wb");
    fp.Write(bitStream,bitStreamLen);
   }
}

/*****************************************************************************
  BitStream stuff
*****************************************************************************/

static
uchar *LoadBitStream(const char *filename, unsigned  *size)
{
 struct bithead bh;
 FILE *f;

 clp.printIfV(1,"Bitstream   : %s\n",filename);
 if (filename)
    f=fopen(filename,"rb");
 else
    f=stdin;
 if (!f)
    error.Abort("Failed to open %s",filename);

 long dataLen;
 initbh(&bh);
 if (readhead(&bh,f))
   {
    clp.printIfV(0,"Doesn't seem to be a bitstream, assuming this is a .bin\n");
    fseek(f,0,SEEK_END);
    dataLen=ftell(f);
    rewind(f);
   }
 else
   {
    dataLen=bh.length;
    clp.printIfV(1,"Source File : %s\n",bh.filename);
    clp.printIfV(1,"Build Date  : %s %s\n",bh.date,bh.time);
    clp.printIfV(1,"Device Type : %s\n",bh.part);
    if (strcmp(bh.part,"3s400aft256")!=0)
       error.Abort("Device code %s is not supported by this utility",bh.part);
   }
 freebh(&bh);
 clp.printIfV(1,"Data size   : %ld\n\n",dataLen);

 File fin(f);
 unsigned memSize=dataLen;
 if (memSize & 1)
    memSize++; // Ensure an even size
 uchar *bitData=new uchar[memSize];
 fin.Read(bitData,dataLen);
 *size=dataLen;
 if (dataLen & 1)
    bitData[dataLen]=0;

 return bitData;
}

/*****************************************************************************
  Slave Serial
*****************************************************************************/

// Slave Serial structure
typedef struct
{
 int count;
 int total;
} sshelper_t;

// Slave Serial callback
static
int SSHelper(uchar *data, unsigned size, void *extra)
{
 static int divider=0;
 sshelper_t *p=(sshelper_t *)extra;

 p->count+=size;
 if (++divider==8 || p->count==p->total)
   {
    clp.printIfV(0,"Bytes written: %8d (%5.2f %%)\r",p->count,p->count*100.0/p->total);
    fflush(stdout);
    clp.printIfV(2,"\n");
    divider=0;
   }
 return 1;
}

static
bool SlaveSerial(uchar *buffer, unsigned len)
{
 sshelper_t aux;
 bool ret=true;

 LoadConfig(cfgSPI);         //  1. Load SPI configuration
 DriveProg(drvLow);          //  2. Drive PROG low
 DriveMode(modSlaveSerial);  //  3. Drive M[2:0] to 1:1:1
 SPIMode(drvHigh);           //  4. Drive PSOC_SPI_MODE high
 DriveProg(drvHigh);         //  5. Drive PROG high
 while (!ReadInit())         //  6. Wait for INIT to go high
   usleep(1000);
 DriveMode(modTriState);     //  7. Drive M[2:0] to tri-state
 FPGAReset(drvHigh);         //  8. Assert FPGA reset
 aux.count=0;                //  9. Send bit stream size
 aux.total=len;              // 10. Send bit stream
 DoSSProgram(buffer,len,SSHelper,&aux);
 clp.printIfV(0,"\n");
 if (!ReadInit())            // 11. Check INIT still high
   {
    error.Error("INIT line isn't high");
    ret=false;
   }
 if (!ReadDone())            // 12. Check DONE is high
   {
    error.Error("DONE line isn't high");
    ret=false;
   }
 SPIMode(drvLow);            // 13. Drive PSOC_SPI_MODE low
 FPGAReset(drvLow);          // 14. Deassert FPGA reset
 LoadConfig(cfgUART);        // 15. Load UART configuration
 // Note: We let the UART mode as the last command to avoid getting confusing
 // data from the FPGA's UART.
 if (ret)
    clp.printIfV(0,"All ok!\n");

 return ret;
}

/*****************************************************************************
  Terminal mode
*****************************************************************************/

static struct termios inTermiosOrig;
static FILE *fIn=NULL;

static
void SetUpIn()
{
 struct termios inTermiosNew;
 int hIn;

 hIn=fileno(stdin);
 if (!isatty(hIn))
    error.Abort("this is an interactive application, don't redirect stdin");
 char *ttyName=ttyname(hIn);
 if (!ttyName)
    error.Abort("failed to get the name of the current terminal used for input");
 fIn=fopen(ttyName,"r+b");
 if (!fIn)
    error.Abort("failed to open the input terminal");
 hIn=fileno(fIn);
 if (tcgetattr(hIn,&inTermiosOrig))
    error.Abort("can't get input terminal attributes");
 memcpy(&inTermiosNew,&inTermiosOrig,sizeof(inTermiosNew));
 inTermiosNew.c_iflag|= (IGNBRK | BRKINT);
 inTermiosNew.c_iflag&= ~(IXOFF | IXON);
 inTermiosNew.c_lflag&= ~(ICANON | ECHO | ISIG);
 if (tcsetattr(hIn,TCSAFLUSH,&inTermiosNew))
    error.Abort("can't set input terminal attributes");
 int oldInFlags=fcntl(hIn,F_GETFL,0);
 int newInFlags=oldInFlags | O_NONBLOCK;
 fcntl(hIn,F_SETFL,newInFlags);
}

static
void RestoreIn()
{
 tcsetattr(fileno(fIn),TCSAFLUSH,&inTermiosOrig);
}

static
void DoTerminal()
{
 LoadConfig(cfgUART);
 printf("Entering terminal mode, press ESC-q to exit\n\n");
 SetUpIn();
 int key;
 bool escape=false, wasEscape=false;
 char buffer[maxPSoCBuf+1];
 do
   {
    key=fgetc(fIn);
    if (key!=-1)
      {
       wasEscape=escape;
       escape=(key==27);
       if (key=='\n') key='\r';
       char aux;
       if (wasEscape && key=='q')
          break;
       if (wasEscape)
         {
          aux=27;
          ser->Send(&aux,1);
         }
       if (!escape)
         {
          aux=key;
          ser->Send(&aux,1);
         }
      }
    unsigned read=ser->RawRead(buffer,maxPSoCBuf,false);
    if (read)
      {
       for (unsigned i=0; i<read; i++)
           if (buffer[i]=='\r')
              buffer[i]=' ';
       if (fwrite(buffer,read,1,stdout)!=1)
          error.Abort("Error writing to terminal");
      }
    usleep(1000);
   }
 while (!(wasEscape && key=='q'));
 puts("");
 RestoreIn();
}

/*****************************************************************************
  BPI flash helper functions
*****************************************************************************/

const unsigned bpiMemoryBytes=0x400000;

static
void BitReverse(uchar *b, unsigned size)
{
 for (unsigned i=0; i<size; i++)
    {
     unsigned v=b[i], nv=0;
     unsigned mask1=0x01, mask2=0x80;
     for (; mask1<0x100; mask1<<=1, mask2>>=1)
         nv|=v & mask1 ? mask2 : 0;
     b[i]=nv;
    }
}

static
void ByteSwap(uchar *b, unsigned &size)
{
 unsigned sz=size;
 if (sz & 1) sz++;
 for (unsigned i=0; i<sz; i+=2)
    {
     uchar aux=b[i];
     b[i]=b[i+1];
     b[i+1]=aux;
    }
 size=sz;
}

static
void PrepareBits(uchar *b, unsigned &size)
{
 if (bpiByteMode==bpi_16 || bpiByteMode==bpi_8)
    BitReverse(b,size);
 if (bpiByteMode==bpi_16 || bpiByteMode==bpi_swap)
    ByteSwap(b,size);
}

static
void Fill32bits(char *b, unsigned v)
{
 b[0]=v>>24;
 b[1]=v>>16;
 b[2]=v>>8;
 b[3]=v;
}

static
bool GetPrompt(bool echo, bool silent=false);

static
bool GetPrompt(bool echo, bool silent)
{
 char buffer[maxPSoCBuf+1];
 unsigned bytes, offset=0;
 do
   {
    bytes=ReadTO(buffer+offset,maxPSoCBuf-offset,false,2);
    if (echo)
      {
       buffer[bytes]=0;
       printf("%s",buffer);
      }
    DumpBytes("GetPrompt",(uchar *)buffer+offset,bytes);
    unsigned tbytes=bytes+offset;
    if (tbytes>=5 && strncmp(buffer+tbytes-5,"AVT> ",5)==0)
       return true;
    // We could get a partial prompt
    if (tbytes<5)
      {
       offset=tbytes;
       clp.printIfV(2,"New offset: %d\n",offset);
      }
    else
      {
       memcpy(buffer,buffer+tbytes-5,5);
       offset=5;
       DumpBytes("Keeping the last ",(uchar *)buffer,5);
      }
   }
 while (bytes);
 if (!silent)
    error.Error("Failed to get the BPI server prompt");
 return false;
}

static
bool VerifyBPIServer()
{
 LoadConfig(cfgUART);

 clp.printIfV(0,"Flushing BPI server data ");
 fflush(stdout);
 char buf[maxPSoCBuf];
 unsigned read;
 while ((read=ReadTO(buf,maxPSoCBuf,false))!=0)
   {
    DumpBytes("BPI bogus data",(uchar *)buf,read);
    clp.printIfV(0,".");
    fflush(stdout);
   }
 clp.printIfV(0,"\n");

 int retry=3; // I saw bizarre things replied, so we try 3 times (i.e. 0xF8 0x0D)
 while (--retry)
   {
    char aux='\r';
    ser->Send(&aux,1); // Double purpose: 1) make the server stop and 2) provide a clean prompt
    if (GetPrompt(false,true))
       return true;
    usleep(50000);
   }
 error.Error("Time-out waiting for BPI server");
 return false;
}

/*****************************************************************************
  BPI Flash Operations
*****************************************************************************/

const unsigned chunkSize=512;

static
bool BPISendCommand(char cmd)
{
 char b[3];

 b[0]=cmd;
 b[1]='\r';
 ser->Send(b,2);
 // Look for the echo.
 // Sometimes the server gets crazy and sends tons of messages, here we wait
 // until nothing is transmitted or we get the echo.
 do
   {
    if (!ReadTO(b,1,true,2))
       break;
    if (b[0]==cmd)
      {
       if (!ReadTO(b,2,true))
          break;
       if (b[0]=='\r' && b[1]=='\n')
          return true;
      }
    else
       clp.printIfV(2,"No echo yet %c\n",b[0]);
   }
 while (1);
 DumpBytes("Wrong echo",(uchar *)b,3);
 error.Error("No BPI server echo");
 return false;
}

static
bool BPIReadVerify(op_t mode, uchar *ref, unsigned size, unsigned offset)
{
 if (offset+size>bpiMemoryBytes)
   {
    error.Error("Range is out of memory (%d+%d>%d)\n",offset,
              size,bpiMemoryBytes);
    return false;
   }

 if (size & 1)
    size++;
 // Send: r\rOOOOLLLL
 // OOOO=offset LLLL=length
 if (!BPISendCommand('r'))
    return false;
 char b[chunkSize];
 // Now send the offset and length
 Fill32bits(b,offset);
 Fill32bits(b+4,size);
 ser->Send(b,8);
 // Read the data
 File *f=NULL;
 if (mode==do_read)
    f=new File(outputFile,"wb");
 unsigned toRead=size, read, extra=0, curOff=0, failed=0;
 Chrono t;
 while (toRead)
   {
    read=ReadTO(b,toRead>chunkSize ? chunkSize : toRead,true);
    if (!read)
      {
       error.Error("Unexpected end of transmission");
       return false;
      }
    if (read>toRead)
      {
       extra=read-toRead;
       read=toRead;
      }
    PrepareBits((uchar *)b,read);
    toRead-=read;
    if (mode==do_read)
      {
       f->Write(b,read);
       clp.printIfV(0,"Bytes read: %8d (%5.2f %%)\r",size-toRead,
                    (size-toRead)*100.0/size);
      }
    else
      {
       if (memcmp(ref+curOff,b,read))
          failed++;
       curOff+=read;
       clp.printIfV(0,"Bytes verified: %8d (%5.2f %%) %3d failed\r",curOff,
                    curOff*100.0/size,failed);
      }
    fflush(stdout);
   }
 if (0 && extra)
   {
    b[read+extra]=0;
    printf("%s",b+read);
   }
 if (mode==do_read)
   {
    clp.printIfV(0,"\nAll read!\n");
    delete f;
   }
 else
   {
    if (failed)
      {
       clp.printIfV(0,"\n%d blocks failed\n",failed);
       GetPrompt(false);
       return false;
      }
    else
       clp.printIfV(0,"\nAll ok!\n");
   }
 PrintElapsed(t,size);
 return GetPrompt(false);
}

static
bool BPIWrite(unsigned offset, uchar *data, unsigned size)
{
 if (offset+size>bpiMemoryBytes)
   {
    error.Error("Range is out of memory (%d+%d>%d)\n",offset,
              size,bpiMemoryBytes);
    return false;
   }
 // Send: w\rOOOOLLLLBBBB
 // OOOO=offset LLLL=length BBBB=burst size
 if (!BPISendCommand('w'))
    return false;
 char b[chunkSize];
 // Now send the offset, length and burst size
 Fill32bits(b,offset);
 Fill32bits(b+4,size);
 Fill32bits(b+8,chunkSize);
 ser->Send(b,12);
 // Write the data
 unsigned total=size, toWrite, curOff=0;
 Chrono t;
 while (total)
   {
    toWrite=total;
    if (toWrite>chunkSize)
       toWrite=chunkSize;
    ser->Send(data+curOff,toWrite);
    if (!ReadTO(b,1,true,3))
      {
       clp.printIfV(0,"\n");
       error.Error("BPI server didn't send A, did you erase the memory?");
       return false;
      }
    total-=toWrite;
    curOff+=toWrite;
    clp.printIfV(0,"Bytes written: %8d (%5.2f %%)\r",curOff,
                 curOff*100.0/size);
    fflush(stdout);
   }
 clp.printIfV(0,"\nAll written!\n");
 PrintElapsed(t,size);
 return GetPrompt(false);
}

static
bool BPIEraseAll()
{
 // Send: e\r
 char b[maxPSoCBuf];
 if (!BPISendCommand('e'))
    return false;
 // Read the starting message
 if (!ReadTO(b,32,true))
   {
    error.Error("BPI server didn't start erasing");
    return false;
   }
 if (strncmp(b,"Erasing 64 blocks, starting...",30))
   {
    error.Error("Wrong BPI erase message <%s>",b);
    return false;
   }
 // Read the progress
 int cur=-1, len=2;
 do
   {
    if (!ReadTO(b,len,true,10))
      {
       error.Error("BPI progress time-out");
       return false;
      }
    cur=atoi(b);
    clp.printIfV(0,"Erasing: block %2d (%5.2f %%)\r",cur,(cur+1)*100.0/64);
    fflush(stdout);
    if (cur==9)
       len=3;
   }
 while (cur!=63);
 clp.printIfV(0,"\nAll erased!\nVerifying ...\n");
 // End message
 if (!ReadTO(b,58,true,20))
   {
    error.Error("End message time-out");
    return false;
   }
 if (strncmp(b,"\n\rSectors 0-63 erased\n\r\n\rChip Erase complete - verifying\n\r",58))
   {
    error.Error("No end message %s",b);
    return false;
   }
 // Verify message
 if (!ReadTO(b,24,true,20))
   {
    error.Error("Verify time-out");
    return false;
   }
 if (strncmp(b,"Chip Erased successfully",24)==0)
   {
    printf("Ok!\n");
    return GetPrompt(false);
   }
 // Verify failed
 printf("%s",b);
 GetPrompt(true);
 return false;
}

static
bool BPIBoot()
{
 LoadConfig(cfgSPI);      //  1. Load SPI configuration
 DriveProg(drvLow);       //  2. Drive PROG low
 SPIMode(drvLow);         //  3. Drive PSOC_SPI_MODE low
 DriveMode(modBPIUp);     //  4. Drive M[2:0]
 DriveProg(drvHigh);      //  5. Release PROG
 DriveMode(modTriState);  //  7. Drive M[2:0] to tri-state
 LoadConfig(cfgUART);

 return false;
}

int main(int argc, char *argv[])
{
 // Parse the command line
 clp.Run(argc,argv,&opts);
 int firstFile=clp.GetFirstFile();
 int numFiles=argc-firstFile;
 // Arguments validation
 bool IsSPIOperation=doReadBack || doWrite || doErase || doVerify || doBoot;
 bool IsBPIOp1=doReadBackBPI || doWriteBPI || doEraseBPI || doVerifyBPI ||
               doBPIServer;
 bool IsBPIOperation=IsBPIOp1 || doBootBPI;
 bool needsBit=doSlaveSerial || doWrite || doVerify || doDumpBit ||
               doWriteBPI || doVerifyBPI;
 bool needsOut=doDumpBit || doReadBack || doReadBackBPI;
 // Options sanity check
 if ((doSlaveSerial && (IsSPIOperation || IsBPIOperation)) ||
     (IsSPIOperation && IsBPIOperation))
    error.Abort("Incompatible operations selected");
 if (!(doSlaveSerial || doFlashCheck || IsSPIOperation || IsBPIOperation ||
     doDumpBit || doTerminal))
    error.Abort("You must specify at least one operation");
 if (needsBit && !bitStreamName)
   {
    if (numFiles>0)
      {
       bitStreamName=argv[firstFile++];
       numFiles--;
      }
    else if (isatty(fileno(stdin)))
       // We support stdin as bitstream, but not if this is tty
       error.Abort("You must provide a bitstream");
   }
 if (bpiByteMode==bpi_invalid)
    error.Abort("Invalid BPI byte mode");
 if (needsOut && !outputFile)
   {
    if (numFiles>0)
      {
       outputFile=argv[firstFile++];
       numFiles--;
      }
    else if (isatty(fileno(stdout)))
      {
       if (doDumpBit)
          outputFile="bitstream.bin";
       else if (doReadBack)
          outputFile="spi_flash_dump.bin";
       else if (doReadBackBPI)
          outputFile="bpi_flash_dump.bin";
      }
    else
       clp.SetVerbosity(-1); // Be quiet if we will dump data to stdout
   }
 if (bytesUsed<0)
    bytesUsed=IsSPIOperation ? flBPRD : bpiMemoryBytes;
 if (numFiles>0)
    error.Warning("Ignoring extra filenames found in the command line");

 // Load bitstream
 uchar *bitStream=NULL;
 unsigned configSize=0;
 if (needsBit)
    bitStream=LoadBitStream(bitStreamName,&configSize);

 // Serial port initialization
 ComSerie s(-1,ComSerieB115200,maxLen,portName);
 s.Initialize();
 ser=&s;

 if (clp.GetVerbosity()>0)
   {
    LoadConfig(cfgSPI);
    GetVer();
    LoadConfig(cfgUART);
   }

 bool goOn=true;
 if (doDumpBit)
    DumpBitStream(outputFile,bitStream,configSize);
 if (doSlaveSerial)
    goOn=SlaveSerial(bitStream,configSize);

 //****************************************************************************
 // SPI Flah Operations
 // i.e. ./avtest -rwy -b ledflash4_cclk_33.bit -B 10000
 //****************************************************************************
 if (doFlashCheck && !(doReadBack || doWrite || doErase || doVerify))
   {
    clp.printIfV(0,"Verifying the serial flash model\n");
    goOn=SFOCheck();
   }
 if (doReadBack && goOn)
   {
    clp.printIfV(0,"Reading %u bytes from the serial flash, offset 0x%07X\n"
                   "Output file %s\n",
                 bytesUsed,memOffset,outputFile);
    goOn=SFOReadVerify(do_read,NULL,bytesUsed);
   }
 if (doErase && goOn)
    goOn=SFOEraseAll();
 if (doWrite && goOn)
   {
    clp.printIfV(0,"Writing %u bytes to the serial flash, offset 0x%07X\n",
                 configSize,memOffset);
    goOn=SFOWrite(bitStream,configSize);
   }
 if (doVerify && goOn)
   {
    clp.printIfV(0,"Verifying %u bytes from the serial flash, offset 0x%07X\n",
                 configSize,memOffset);
    goOn=SFOReadVerify(do_verify,bitStream,configSize);
   }
 if (doBoot && goOn)
   {
    clp.printIfV(0,"Configuring the FPGA using the serial flash content\n");
    goOn=SFOBoot();
   }

 //****************************************************************************
 // BPI Flash Operations
 // i.e. avtest -iREWYF -b ledflash4_cclk_6.bit -B 10000
 //****************************************************************************
 if (doBPIServer && goOn)
   {// Send the BPI server to the FPGA
    unsigned bpiServerSize;
    uchar *bpiServerData;
    bool allocated=true;
    if (bpiServerFile)
       // From a file
       bpiServerData=LoadBitStream(bpiServerFile,&bpiServerSize);
    else
      {// From internal data
       if (!BPI_SERVER)
          error.Abort("You must specify a BPI server file with -S");
       bpiServerData=bpi_server_h_data;
       bpiServerSize=sizeof(bpi_server_h_data);
       allocated=false;
      }
    clp.printIfV(0,"Sending the BPI server to the FPGA\n");
    goOn=SlaveSerial(bpiServerData,bpiServerSize);
    if (allocated)
       delete[] bpiServerData;
   }
 if (IsBPIOp1)
    goOn=VerifyBPIServer();
 if (doReadBackBPI && goOn)
   {
    clp.printIfV(0,"Reading %u bytes from the parallel flash, offset 0x%07X\n"
                   "Output file %s\n",
                 bytesUsed,memOffset,outputFile);
    goOn=BPIReadVerify(do_read,NULL,bytesUsed,memOffset);
   }
 if (doEraseBPI && goOn)
   {
    clp.printIfV(0,"Erasing the whole parallel flash\n");
    goOn=BPIEraseAll();
   }
 if (doWriteBPI && goOn)
   {
    PrepareBits(bitStream,configSize);
    clp.printIfV(0,"Writing %u bytes to the parallel flash, offset 0x%07X\n",
                 configSize,memOffset);
    goOn=BPIWrite(memOffset,bitStream,configSize);
    if (doVerifyBPI && goOn)
       PrepareBits(bitStream,configSize); // Revert the changes
   }
 if (doVerifyBPI && goOn)
   {
    clp.printIfV(0,"Verifying %u bytes from the parallel flash, offset 0x%07X\n",
                 configSize,memOffset);
    goOn=BPIReadVerify(do_verify,bitStream,configSize,memOffset);
   }
 if (doBootBPI && goOn)
   {
    clp.printIfV(0,"Configuring the FPGA using the parallel flash content\n");
    goOn=BPIBoot();
   }

 if (doTerminal && goOn)
    DoTerminal();

 delete[] bitStream;
 return goOn ? 0 : 1;
}


/*****************************************************************************
   Flash constants
*****************************************************************************/
// Op-Codes
const int flWREN=0x06;            // Write Enable Flash
const int flWESR=0x06;            // Write Enable Status Register
const int flWRDI=0x04;            // Write Disable
const int flWDSR=0x04;            // Write Disable Status Register
const int flRDID=0x9F;            // Read Identification
const int flRDSR=0x05;            // Read Status Register
const int flWRSR=0x01;            // Write Status Register
const int flREAD=0x03;            // Read Data Bytes
const int flFAST=0x0B;            // Read Data Bytes at Higher Speed
const int flPGPM=0x02;            // Page Program
const int flSECE=0xD8;            // Sector Erase
const int flBLKE=0xC7;            // Bulk Erase
const int flDEEP=0xB9;            // Deep Power-down
const int flREDS=0xAB;            // Read 8-bit Electronic Signature and/or Release from Deep power-down
// SF Status Register masks
const int flESTM=0x01;            // Erase status mask
const int flESST=0x00;            // Erase success state
const int flPSTM=0x01;            // Program status mask
const int flPSST=0x00;            // Program success state
const int flWELM=0x02;            // Write enable latch mask
const int flWEST=0x01;            // Write enable state
const int flBPRM=0x3C;            // Block protect mask
const int flUABL=0x00;            // Unprotect all blocks
// RDID options
const int flNIDB=0x05;            // Number of ID bytes
const int flIDM0=0xFF;            // ID byte 0 mask
const int flIDV0=0x01;            // ID byte 0 expected value
const int flIDM1=0xFF;            // ID byte 1 mask
const int flIDV1=0x20;            // ID byte 1 expected value
const int flIDM2=0xFF;            // ID byte 2 mask
const int flIDV2=0x18;            // ID byte 2 expected value
const int flIDM3=0xFF;            // ID byte 3 mask
const int flIDV3=0x03;            // ID byte 3 expected value
const int flIDM4=0xFF;            // ID byte 4 mask
const int flIDV4=0x01;            // ID byte 4 expected value
// Page Program options
const int flMBPP=0x100;           // Max bytes during Page Program
// Device parameters
const char *flDEVI="S25FL128P_64KB";// Device part number
const char *flMFCG="SPANSION";      // Manufacturer
const int flABSZ=0x03;              // Address byte size
const int flSECT=0x100;             // Number of sectors per device
const int flPPRS=0x100;             // Pages per sector
const int flBPRP=0x100;             // Bytes per page
const int flBPRD=0x1000000;         // Total number of bytes per device
const int flMEPI=0xC8;              // Max erase poll iterations
const int flMPPI=0x0A;              // Max program poll iterations
const int flDUMB=0xAA;

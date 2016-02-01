Title: ASTriAEKiPro
Operating System: Linux, maybe other POSIX compliant OSs.

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


 1. Introduction
 2. How to compile
 3. Configuring the FPGA directly
 4. Using the serial flash
 5. Using the parallel flash
 6. Terminal mode
 7. Dumping bitstreams
 8. Abreviated usage and pipes
 9. Known issues
10. Acknowledgements
11. Contacting the author


1. Introduction
---------------

This program is used to configure the Avnet Spartan 3A Eval Kit
(AES-SP3A-EVAL400-G). This evaluation kit contains an Spartan 3A 400 without
any Xilinx's PROM. You can configure the FPGA using a JTAG cable and Xilinx's
iMPACT. The problem is that this configuration will go away when you turn off
the board.

The kit contains two Spansion flash memories. One 128 Mb serial flash and a
parallel 32 Mb parallel flash. The serial flash uses SPI. Spartan 3A FPGA's can
"boot" (be configured) from both memories.

To access to these memories and to communicate with the FPGA using USB the kit
includes a Cypress Cy8C24894 PSoC. This is an x51 compatible microcontroller
with some interesting peripherals, including full speed USB.

The PSoC contains a firmware that can:

* Forwards serial data from the FPGA.
* Control the programming, reset, mode, etc. pins of the FPGA.
* Access to the SPI bus where the serial memory is located.
* More stuff not important for this document ;-)

This program was designed to work with PSoC's firmware v1.0.1.

The purpose of this program is to allow the user to access both memories using
the USB cable.

In order to use this program you should ensure the kit jumpers are installed as
described in the "Spartan-3A Evaluation Kit Quick Start" provided by Avnet
(s3aeval_quick_start_10_1_01.pdf). This is:

* JP1: 1-2 open. No flash write protect
* JP2: 1-2 closed. Power from USB.
* JP3: 1-2 open. No power-on reset, PROG released
* JP4: 1-2 open, 3-4 closed, 5-6 closed, 7-8 open. Master SPI Mode, no pull-ups
  during config.
* JP5: 2-3 closed. Disable suspend mode.
* JP6: 1-2 closed. Disable external SPI.
* JP7: 1-2 closed. Power from USB.

Other configurations may work, but they weren't tested.

When you connect the USB cable to a Linux machine you'll get something like
this logged (use dmesg):

usb 2-1: new full speed USB device using uhci_hcd and address 4
usb 2-1: configuration #1 chosen from 1 choice
drivers/usb/class/cdc-acm.c: This device cannot do calls on its own. It is no modem.
cdc_acm 2-1:1.0: ttyACM0: USB ACM device

The PSoC firmware implements some kind of basic USB modem. In this case the
name of the device is /dev/ttyACM0. This program assumes this name as default.
If your system assigns other name you can tell it to the program using the -p
or --port command line option.

Using this program you can:

* Configure the FPGA directly.
* Read, erase, write and verify data from/to the SPI flash.
* Read, erase, write and verify data from/to the parallel flash.
* Boot the FPGA from the SPI or parallel flash without changing the JP4
settings.
* Run a simple terminal to use the serial data forwarded from/to the FPGA.
* Dump a .bit file to a .bin or C .h file.

The command line is GNU compliant and supports short and long options. The help
option is -h or --help. Using -v or --verbose you can increase the ammount of
information printed by the program, -vvv will output the maximum ammount of
information. Using -q or --quite you can reduce the printed information. The
-V or --version option provides version and copyright information. The return
value from the program is 0 for success and any other value means something
went wrong.

If you interrupt the program in the middle of a transaction the PSoC firmware
could be left in an unknown state. The next run will probably fail. If the
problem persist just unplug the USB cable and try again.


2. How to compile
-----------------

Ideally you just need to run make and all will be compiled and you'll get the
astriaekipro binary. Then you just need to move the binary to some useful place
in your system i.e. /usr/bin/ (you'll need to change to root superuser).

Please report any compilation problems.


3. Configuring the FPGA directly
--------------------------------

You can send a bitstream to the FPGA's configuration memory (SRAM ...
memristors would be nice ;-).

$ astriaekipro -s -b Spartan3AEval_FPGA_Firmware_V10.bit

This will load the Spartan3AEval_FPGA_Firmware_V10.bit bitstream (factory test)
to the FPGA and automatically start.


4. Using the serial flash
-------------------------

The available operations are:

-r, --read-back
Reads the SPI flash memory. You should specify how many bytes to read using -B
and where to put the result using -O. You could also specify an offset using
-o. By default the number of bytes is 16 MB (128 Mb), the offset is 0 and the
output file is named spi_flash_dump.bin. Note that 16 MB is a lot! (13 minutes
in my system, at ~21 kB/s)

-e, --erase
Erases the whole flash. This is a slow process and isn't needed for the write
operation. Is implemented only in case you need it for some particular reason.

-w, --write
Writes the SPI flash memory. You must specify a bitstream using -b option. You
can optionally specify an offset with -o. You can also provide a .bin (pure
binary data). Note that this command will erase the 64 kB pages needed to write
the data.

-y, -verify
Verifies the SPI flash content. The options are the same provided for -w.

Important!
Note that in order to use the SPI bus the PSoC must keep the FPGA off. For this
reason the above mentioned commands will reset the FPGA and then start it
according JP4 settings.

-c, --flash-check
Just verifies the SPI flash ID is correct. This is used for debug purposes.

-f, --boot
Loads the FPGA using the SPI flash configuration. This command should be able
to boot the FPGA from the serial memory even if JP4 indicates other mode.

You can specify various operations in the same run. The program will do the
operations in an order that makes sense (at least for me ;-). Here is an
example:

$ astriaekipro -rwy -b ledflash4_cclk_33.bit -B 10000

It will:

1) Dump the first 10000 bytes to the spi_flash_dump.bin file.
2) Write ledflash4_cclk_33.bit at offset 0.
3) Verify the content of the memory.


5. Using the parallel flash
---------------------------

The available options are similar to the serial flash, but the process is a
little bit trickier. The problem is that this program talks to the PSoC and it
doesn't have direct access to the parallel flash. The solution is to load a
"BPI Server" in the FPGA. This server will be the one to access the parallel
memory and we will communicate with it using the USB to serial feature of the
PSoC.

It means that you must first load a bitstream in the FPGA and after it you'll
be able to tell to the server what you want. You can do it in the same run or
first load the server and in different runs use it.
If you fail to load the server the program will complain about time-outs
contacting the server. One way to verify the server is running is to use the
terminal mode (-t), after pressing ENTER you should get the server prompt:
AVT>

Another tricky detail is related to the bits and bytes order. The FPGA needs
the bits in the reverse order and the server uses 16 bits writes and needs the
words in reverse order (bytes swapped). The program takes care of it, but if
you need to write other kind of data (not a bitstream) you should take a look
at the -m command line option described below.

-R, --read-back-bpi
Reads the parallel flash memory. You should specify how many bytes to read
using -B and where to put the result using -O. You could also specify an offset
using -o. By default the number of bytes is 4 MB (32 Mb), the offset is 0 and
the output file is named bpi_flash_dump.bin. Note that 4 MB is a lot! (6 minutes
in my system, at ~11 kB/s)

-E, --erase-bpi
Erases the whole flash. This must be done in order to write the flash.

-W, --write-bpi
Writes the parallel flash memory. You must specify a bitstream using -b option.
You can optionally specify an offset with -o. You can also provide a .bin (pure
binary data). You must erase the memory before writing.

-Y, -verify-bpi
Verifies the pararllel flash content. The options are the same provided for -W.

Important!
In this case the FPGA won't be reset (is running the server ;-). For this
reason the above mentioned commands won't reconfigure the FPGA after
completion.

-F, --boot-bpi
Loads the FPGA using the parallel flash configuration. This command should be
able to boot the FPGA from the parallel memory even if JP4 indicates other
mode.

-i, --send-server
Loads the FPGA configuration with the bitstream indicated using the -S option.
This should be the BPI server.

-m, --bpi-mode=MODE
This option affects the read, write and verify operations. The default mode of
operation (16) alters the data doing a bit reverse operation (needed for the
FPGA) and a byte swap (needed for the server). This is ok for bitstreams, but
for data you could need a different methode. The following modes are available:
direct: The program doesn't change anything.
16:     Bits reversed and bytes swapped.
8:      Bits reversed.
swap:   Bytes swapped.

As with the serial flash you can specify various operations in the same run.
Here is an example:

$ astriaekipro -iREWYF -b ledflash4_cclk_6.bit -B 10000 -S bpi_server_v036.bit

It will:

1) Transfer the bpi_server_v036.bit to the FPGA.
2) Dump the first 10000 bytes to the bpi_flash_dump.bin file.
3) Write ledflash4_cclk_6.bit at offset 0.
4) Verify the content of the memory.
5) Boot the FPGA (removing the server!)


6. Terminal mode
----------------

When the FPGA have some stuff that uses the serial link with the PSoC you can
talk to the FPGA using a simple terminal emulator. The factory default
configuration (stored in the SPI flash memory) is an example. It uses a
MicroBlaze for that.

The -t or --terminal command line option provides a very dumb terminal where
you can type and see the FPGA replies.

Once stated you can exit using ESC-q


7. Dumping bitstreams
---------------------

You can extract the bitstream content from a .bit and store it in a pure binary
file (.bin) or generate a C header.

-d, --dump-bit
Dumps the content of the bitstream specified using -b option. The content will
be dumped to the filed specified using -o (bitstream.bin if none specified).
The default is binary format, a C header is obtained using -C.


8. Abreviated usage and pipes
-----------------------------

If you need to use ASTriAEKiPro as a filter or just provide the bitstream from
stdin or pass the dumped data to stdout you can call the program without
specifying the input and/or output filenames. ASTriAEKiPro will check if its
input/output is redirected and use it. Here is an example:

$ cat file.bit | astriaekipro -d > file.bin

This will extract the real bitstream contained in file.bit and put it in
file.bin.

If you want to abreviate the command line, avoiding to explicitly indicate the
-b and -O switches you can let ASTriAEKiPro try to be smart. Here is an
example:

$ astriaekipro -d file.bit file.bin

This will do the same as the previous example. ASTriAEKiPro will use the last
names as replacements for -b and/or -O.


9. Known issues
---------------

* When using -f/-F the program can't tell you if the FPGA succesfully booted.
In theory you can read the DONE line using PSoC commands, but I failed to do
it.

* Some times the Linux kernel blocks when writing to the device. Looks like a
bug in the ACM code. In this case you must terminate the program using
Control+C or kill. After it you'll need to unplug the USB cable and plug it
again. I'm not sure when it happends, could be related with the PSoC hanging.

* Some times the program fails to get a reply from the PSoC or the FPGA and
informs an error. You need to retry.


10. Acknowledgements
--------------------

* I took some ideas from Jason Milldrum avs3a tool.
* The bpi_server.h file is the bitstream for Avnet's BPI server version 036.
Coded by Bryan Fletcher and Ron Wright. This file is included in the AvProg
ditribution. You can download AvProg from Avnet's site:
http://www.em.avnet.com/
* Bryan Fletcher (from Avnet) provided all the information needed to use the
BPI server.
* Most of the programming information comes from the following documents
provided by Avnet:
Spartan3A_Eval_Programming_Algorithms_v1_0.pdf
Spartan3A_Eval_PSoC_SoftwareUserGuide_v1_0.pdf
avt_s25fl128p_64kb.sfh


11. Contacting the author
-------------------------

You can contact me by e-mail. To avoid SPAM I altered the e-mails, just replace
_ by .:
                   user      server
Main e-mail:       salvador  inti_gob_ar
Source Forge:      set       users_sf_net
IEEE:              set       ieee_org
Computer Society:  set       computer_org

If it doesn't work and you want to contact me by phone (please speak slowly!):

Work: +54 11 4724 6315
Home: +54 11 4623 4099

54 is for Argentina and 11 is for Buenos Aires.


Enjoy, SET


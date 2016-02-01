Copyright (c) 2005-2009 Salvador E. Tropea <salvador en inti gov ar>
Copyright (c) 2005-2009 Instituto Nacional de Tecnología Industrial

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 2.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA

This package contains a very simple example showing how to make a small VHDL
and download it to the FPGA using the Avnet Spartan 3A Eval Kit
and ISE WebPack on Linux.
The code should be easily adaptable to be used with other Xilinx's FPGAs.

We assume you have installed:
* ISE WebPack
* ASTriAEKiPro
Notr: Consult http://fpgalibre.sourceforge.net/

We assume you have:
* Avnet Spartan 3A Eval Kit board.
  Note: The examples should be easily adapted with other boards.
* USB cable to connect the board to the PC.

Normal development flow:

1) We write our design and validate it using simulation. It depends on the
tools we use. In our example we define a component called "Led". It can be
found in the led.vhdl file. It just divides the FPGA clock to blink a led.

2) We write the "top level" where we interconnect the components with the
real world. This source is FPGA dependent. It can be compiled with GHDL to
verify its syntax but won't do anything because it needs external signals.
It can be found in the FPGA/ejemplo/led_top.vhdl file.

3) We create an XST project. It can be done using ISE (ugh!) or by hand.
The syntax is quite simple we just need to add lines like it:

vhdl work SOURCE

In this case we use FPGA/ejemplo/led.prj
The first column is the language (vhdl o verilog), the second is the name of
the library for the module and the last is the source file. Use a relative
path using as reference the place where the .prj resides.

4) We create a file with XST options. We usually use a name with .xst. It
can be generated with ISE when we ask to synthetize or we can create it by
hand using another file as base. In this case we use led.xst The most relevant
fields are:

set -tmpdir tmp
  Temporal directory.
set -xsthdpdir ./xst
  Directory where XST will store information about what was analized. Some
  kind of cache.
-ifn ../led.prj
  The name of our project. Note: We add ../ because the file will be
  generated in FPGA/ejemplo/gen
-ofn led
  Base name for output files (i.e. led.syr)
-p xc3s400aft256
  The target FPGA.
-top LedTop
  Name of the "top level" entity
-opt_mode Speed
  Optimize for speed (we could choose for Area)
-uc led.xcf
  The name of the constrains file.

The other options are less relevant and most of them are used to fine tune
the optimization process.

5) We create a makefile based on FPGA/ejemplo/Makefile. In this makefile we
just need to specify a couple of things::
a) The name of the project (PRJ)
b) The path to Xilinx tools (SET_XIL_BASE)
and, if the makefile isn't in FPA/xxxxx/ RELSRC

6) We run "make -C FPGA/ejemplo". If we are lucky and all worked we'll get
a bitstream and it will be transferred to the FPGA.

7) We take a look at the XST output stored in led.syr These are the most
relevant details for our example:
Note: Report files can be found in the FPGA/ejemplos/gen directory.


<----------
Synthesizing Unit <Led>.
    Related source file is "...led.vhdl".
    Found 1-bit register for signal <ast>.
    Found 23-bit adder for signal <ast$addsub0000> created at line 35.
    Found 23-bit up counter for signal <conta>.
    Summary:
	inferred   1 Counter(s).
	inferred   1 D-type flip-flop(s).
	inferred   1 Adder/Subtractor(s).
Unit <Led> synthesized.

=========================================================================
HDL Synthesis Report

Macro Statistics
# Adders/Subtractors                                   : 1
 23-bit adder                                          : 1
# Counters                                             : 1
 23-bit up counter                                     : 1
# Registers                                            : 1
 1-bit register                                        : 1

=========================================================================

Device utilization summary:
---------------------------

Selected Device : 3s400aft256-5 

 Number of Slices:                      28  out of   3584     0%  
 Number of Slice Flip Flops:            24  out of   7168     0%  
 Number of 4 input LUTs:                53  out of   7168     0%  
 Number of IOs:                          2
 Number of bonded IOBs:                  2  out of    195     1%  
    IOB Flip Flops:                      1
 Number of GCLKs:                        1  out of     24     4%  

<----------



In led.par we can see the final results:



<----------
Design Summary Report:

 Number of External IOBs                           2 out of 195     1%

   Number of External Input IOBs                  1

      Number of External Input IBUFs              1
        Number of LOCed External Input IBUFs      1 out of 1     100%


   Number of External Output IOBs                 1

      Number of External Output IOBs              1
        Number of LOCed External Output IOBs      1 out of 1     100%


   Number of External Bidir IOBs                  0


   Number of BUFGMUXs                        1 out of 24      4%
   Number of Slices                         28 out of 3584    1%
      Number of SLICEMs                      0 out of 1792    0%
<----------



If we take a look at led_map.mrp



<----------
Design Summary
--------------
Number of errors:      0
Number of warnings:    1
Logic Utilization:
  Number of Slice Flip Flops:          24 out of   7,168    1%
  Number of 4 input LUTs:               8 out of   7,168    1%
Logic Distribution:
  Number of occupied Slices:                           28 out of   3,584    1%
    Number of Slices containing only related logic:      28 out of      28  100%
    Number of Slices containing unrelated logic:          0 out of      28    0%
      *See NOTES below for an explanation of the effects of unrelated logic
Total Number of 4 input LUTs:             52 out of   7,168    1%
  Number used as logic:                  8
  Number used as a route-thru:          44
  Number of bonded IOBs:                2 out of     195    1%
    IOB Flip Flops:                     1
  Number of GCLKs:                     1 out of      24    4%
<----------


We can see it used 24 F/F: 23 for the counter and 1 for the led.

8) A synthesis summary can be found in FPGA/ejemplo/led.txt

9) Using ASTriAEKiPro we send the led.bit to the FPGA (FPGA/ejemplo/led.bit)

$ astriaekipro -s -b FPGA/ejemplo/gen/led.bit

Note 1: if ASTriAEKiPro isn't installed at system level you'll need to provide
the full path, i.e. ../astriaekipro
Note 2: Read the ASTriAEKiPro documentation to ensure your board is properly
jumped.


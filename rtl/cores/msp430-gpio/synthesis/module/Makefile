# this file describes the build process for an FPGA project
# without using the IDE
# Create from the msp430-gpio API a netlist that can be used later on
# (Written by Sven Gulikers 2012)

ifndef TARGET
# define FPGA specific stuff 
#TARGET=xc3s700an-5-fgg484
endif

# define the directory to build the project in
COMPILER=xilinx

# where to find sources that do not live here
DIR_USER_VHDL=$(CURDIR)/../../rtl/vhdl

# general build commands
all: ${COMPILER}/msp_gpio.ngc

# top design
${COMPILER}/msp_gpio.ngc: ${COMPILER}/msp_gpio.top

### GPIO core
XST_FLAGS_msp_gpio = -opt_mode area -opt_level 1
XST_FLAGS_msp_gpio+= -iobuf no
${COMPILER}/msp_gpio.ngc: $(DIR_USER_VHDL)/msp_gpio.vhd

include $(ROOT)/xilinx-build/Makefile.defs

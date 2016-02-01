# this file describes the build process for an FPGA project
# without using the IDE
# Create from the msp430-serial API a netlist that can be used later on
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
all: $(COMPILER)/msp_serial.ngc

# top design
$(COMPILER)/msp_serial.ngc: $(COMPILER)/msp_serial.top

### UART core
XST_FLAGS_msp_serial = -opt_mode speed -opt_level 1
XST_FLAGS_msp_serial+= -iobuf no
HDL_SRC += $(DIR_USER_VHDL)/msp_serial.vhd
HDL_SRC += $(DIR_USER_VHDL)/pkg_helpers.vhd
HDL_SRC += $(DIR_USER_VHDL)/resync.vhd
HDL_SRC += $(DIR_USER_VHDL)/flancter.vhd
HDL_SRC += $(DIR_USER_VHDL)/pulse.vhd
HDL_SRC += $(DIR_USER_VHDL)/baudgen.vhd
HDL_SRC += $(DIR_USER_VHDL)/tx.vhd
HDL_SRC += $(DIR_USER_VHDL)/rx.vhd
HDL_SRC += $(DIR_USER_VHDL)/fifo.vhd

$(COMPILER)/msp_serial.ngc: $(HDL_SRC)
#$(eval $(call TEMPLATE_CREATE_NETLIST,msp_serial,$(HDL_SRC)))

include $(ROOT)/xilinx-build/Makefile.defs

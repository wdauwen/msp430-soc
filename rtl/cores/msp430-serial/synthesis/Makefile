#
# this file describes the build process for a CPLD project
# without using the IDE
#

# define CPLD/FPGA specific stuff 
TARGET=xc3s700an-4-fgg484
BOARD=SPARTAN3AN-STARTER-KIT
PROJECT=serial.elf

# define the directory to build the project in
COMPILER=xilinx
SIMDIR=sim
BENCHDIR=$(PWD)/../bench

# where to find sources that do not live here
DIR_USER_VHDL=$(PWD)/../rtl/vhdl
DIR_BENCH_VHDL=$(PWD)/../bench/vhdl
DIR_COMPILED=$(PWD)/$(COMPILER)

# general build commands
all: $(COMPILER)/serial.bit

# include the build rules
include xilinx-build/Makefile.defs

# top design
HDL_SRC += $(COMPILER)/serial.top  
HDL_SRC += $(DIR_USER_VHDL)/serial.vhd       

HDL_SRC += $(DIR_USER_VHDL)/pkg_helpers.vhd         
HDL_SRC += $(DIR_USER_VHDL)/resync.vhd
HDL_SRC += $(DIR_USER_VHDL)/flancter.vhd
HDL_SRC += $(DIR_USER_VHDL)/pulse.vhd
HDL_SRC += $(DIR_USER_VHDL)/baudgen.vhd
HDL_SRC += $(DIR_USER_VHDL)/tx.vhd
HDL_SRC += $(DIR_USER_VHDL)/rx.vhd
HDL_SRC += $(DIR_USER_VHDL)/fifo.vhd

# netlist needed for this project, make sure that the toplevel 
# netlist is the firstone in the list
NET_SRC += $(COMPILER)/serial.ngc

# Building the netlists
$(eval $(call TEMPLATE_CREATE_NETLIST,serial,$(HDL_SRC)))
$(eval $(call TEMPLATE_CREATE_DESIGN,serial,$(NET_SRC),design.ucf))

#
# simulation things
#
SRC_LIBRARY += $(DIR_USER_VHDL)/pkg_helpers.vhd
SRC_LIBRARY += $(DIR_USER_VHDL)/resync.vhd
SRC_LIBRARY += $(DIR_USER_VHDL)/flancter.vhd
SRC_LIBRARY += $(DIR_USER_VHDL)/pulse.vhd

SRC_test_wb += $(DIR_BENCH_VHDL)/test_wb.vhd
SRC_test_wb += $(SRC_LIBRARY)
SRC_test_wb += $(DIR_USER_VHDL)/serial_msp.vhd
SRC_test_wb += $(DIR_USER_VHDL)/baudgen.vhd
SRC_test_wb += $(DIR_USER_VHDL)/tx.vhd
SRC_test_wb += $(DIR_USER_VHDL)/rx.vhd
SRC_test_wb += $(DIR_USER_VHDL)/fifo.vhd
$(eval $(call TEMPLATE_SIMULATE,test_wb))

#SRC_test_loopback += $(DIR_COMPILED)/serial.vhd
SRC_test_loopback += $(DIR_BENCH_VHDL)/test_loopback.vhd
SRC_test_loopback += $(SRC_LIBRARY)
SRC_test_loopback += $(DIR_USER_VHDL)/serial.vhd
SRC_test_loopback += $(DIR_USER_VHDL)/baudgen.vhd
SRC_test_loopback += $(DIR_USER_VHDL)/tx.vhd
SRC_test_loopback += $(DIR_USER_VHDL)/rx.vhd
SRC_test_loopback += $(DIR_USER_VHDL)/fifo.vhd
$(eval $(call TEMPLATE_SIMULATE,test_loopback))

SRC_test_transmit = $(SRC_LIBRARY) test_transmit.vhd baudgen.vhd tx.vhd
$(eval $(call TEMPLATE_SIMULATE,test_transmit))

SRC_test_receiver += $(DIR_BENCH_VHDL)/test_receiver.vhd
SRC_test_receiver += $(SRC_LIBRARY)
SRC_test_receiver += $(DIR_USER_VHDL)/baudgen.vhd
SRC_test_receiver += $(DIR_USER_VHDL)/rx.vhd
$(eval $(call TEMPLATE_SIMULATE,test_receiver))

SRC_test_fifo = test_fifo.vhd fifo_8x16.vhd
$(eval $(call TEMPLATE_SIMULATE,test_fifo))

SRC_test_baudrate = test_baudrate.vhd baudgen.vhd
$(eval $(call TEMPLATE_SIMULATE,test_baudrate))


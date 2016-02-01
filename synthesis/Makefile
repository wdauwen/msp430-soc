# this file describes the build process for an FPGA project
# without using the IDE
# (Written by Sven Gulikers 2012)

# define FPGA specific stuff 
BOARD=SPARTAN3AN-STARTER-KIT
#BOARD=SPARTAN3A-EVAL-KIT
#BOARD=NEXYS4

ifeq ($(BOARD),SPARTAN3AN-STARTER-KIT)
#TARGET=xc3s700an-5-fgg484
TARGET=xc3s700a-4-fg484
UCF_FILE=openMSP430_fpga.ucf
endif
ifeq ($(BOARD),SPARTAN3A-EVAL-KIT)
TARGET=xc3s400a-4-ft256
UCF_FILE=openMSP430_fpga_3a400.ucf
endif
ifeq ($(BOARD),NEXYS4)
TARGET=xc7a100t-1-csg324
UCF_FILE=openMSP430_fpga_xc7a100t.ucf
endif

MEMORYMAP=memory.bmm
# Optimize design, but it takes a lot of time
#TIMING_MODE=1

# define the directory to build the project in
COMPILER=xilinx
SIMDIR=sim
BENCHDIR=$(PWD)/../bench

# where to find sources that do not live here
DIR_USER_VHDL=$(PWD)/../rtl/vhdl
DIR_BENCH_VHDL=$(PWD)/../bench/vhdl
DIR_USER_VERI=$(PWD)/../rtl/verilog
DIR_USER_VERI_COREGEN=$(PWD)/../rtl/verilog/coregen
DIR_CORE_MSP430=$(PWD)/../rtl/cores/openmsp430/core/rtl/verilog
DIR_CORE_GPIO=$(PWD)/../rtl/cores/msp430-gpio
DIR_CORE_UART=$(PWD)/../rtl/cores/msp430-serial
DIR_CORE_DAC=$(PWD)/../rtl/cores/msp430-audio
DIR_CORE_LCD=$(PWD)/../rtl/cores/msp430-lcd
DIR_CORE_ETH=$(PWD)/../rtl/cores/msp430-eth
	
# include the build rules
include xilinx-build/Makefile.defs

# rule to cleanup the mess
clean:: module_clean
	rm -rf *.bit

ifeq ($(BOARD),SPARTAN3AN-STARTER-KIT)
download-impact: $(COMPILER)/impact.cfg
	data2mem -bm $(MEMORYMAP:%.bmm=%_bd.bmm) -bt ${COMPILER}/mspsoc.bit \
		-bd ../software/$(notdir $(PROJECT:%.elf=%))/$(PROJECT:%.elf=%.mem) \
		-o b $(notdir $(PROJECT:%.elf=%)).bit
	@impact -batch $(COMPILER)/impact.cfg
endif
ifeq ($(BOARD),SPARTAN3A-EVAL-KIT)
download-impact:
	data2mem -bm $(MEMORYMAP:%.bmm=%_bd.bmm) -bt ${COMPILER}/mspsoc.bit \
		-bd ../software/$(notdir $(PROJECT:%.elf=%))/$(PROJECT:%.elf=%.mem) \
		-o b $(notdir $(PROJECT:%.elf=%)).bit
	@../tools/astriaekipro-1.2.1/astriaekipro -s $(notdir $(PROJECT:%.elf=%)).bit 
endif

# top design
HDL_SRC += $(COMPILER)/openMSP430_fpga.top  
HDL_SRC += $(DIR_USER_VHDL)/pkg_soc.vhd         
ifeq ($(BOARD),SPARTAN3AN-STARTER-KIT)
HDL_SRC += $(DIR_USER_VHDL)/soc_fpga.vhd       
endif
ifeq ($(BOARD),SPARTAN3A-EVAL-KIT)
HDL_SRC += $(DIR_USER_VHDL)/soc_fpga_400.vhd       
endif
ifeq ($(BOARD),NEXYS4)
HDL_SRC += $(DIR_USER_VHDL)/soc_fpga_xc7a100t.vhd
endif

### MSP430 core
CORE_SRC += omsp_alu.v         
CORE_SRC += omsp_and_gate.v         
CORE_SRC += omsp_clock_module.v
CORE_SRC += omsp_dbg.v         
CORE_SRC += omsp_dbg_hwbrk.v
CORE_SRC += omsp_dbg_uart.v    
CORE_SRC += omsp_execution_unit.v
CORE_SRC += omsp_frontend.v    
CORE_SRC += omsp_mem_backbone.v
CORE_SRC += omsp_multiplier.v
CORE_SRC += omsp_register_file.v
CORE_SRC += omsp_sfr.v     
CORE_SRC += omsp_sync_cell.v
CORE_SRC += omsp_sync_reset.v
CORE_SRC += omsp_watchdog.v   
CORE_SRC += openMSP430.v       
CORE_SRC += openMSP430_undefines.v 
## Rules for putting the sources on the right place
$(foreach src, $(CORE_SRC), $(eval $(call TEMPLATE_COPY_HDLSRC,HDL_CORE_SRC,$(src),$(DIR_CORE_MSP430),$(DIR_USER_VERI))))
HDL_CORE_SRC += $(DIR_USER_VERI)/openMSP430_defines.v
HDL_SRC += $(HDL_CORE_SRC)

### processor memory
HDL_SRC += $(DIR_USER_VHDL)/ram_8bit.vhd

### VGA code
HDL_SRC += $(DIR_USER_VHDL)/vga_example.vhd

# Rules for building other modules
$(eval $(call TEMPLATE_CREATE_MODULE,NET_SRC,msp_gpio,$(DIR_CORE_GPIO)))
$(eval $(call TEMPLATE_CREATE_MODULE,NET_SRC,msp_serial,$(DIR_CORE_UART)))
#$(eval $(call TEMPLATE_CREATE_MODULE,NET_SRC,msp_dac,$(DIR_CORE_DAC)))
#$(eval $(call TEMPLATE_CREATE_MODULE,NET_SRC,msp_lcd,$(DIR_CORE_LCD)))
#$(eval $(call TEMPLATE_CREATE_MODULE,NET_SRC,msp_ethernet,$(DIR_CORE_ETH)))

# Building the netlists
$(eval $(call TEMPLATE_CREATE_NETLIST,mspsoc,$(HDL_SRC)))

# Combining the netlists
$(eval $(call TEMPLATE_CREATE_DESIGN,mspsoc,$(NET_SRC),$(UCF_FILE)))

#
# Include the automatically generated dependency files.
#
ifneq ($(MAKECMDGOALS),clean)
-include ${wildcard $(COMPILER)/*.d} __dummy__
endif

#
# simulation things
#
SRC_test_sys += $(DIR_BENCH_VHDL)/test_sys.vhd
SRC_test_sys += $(HDL_CORE_SRC)
SRC_test_sys += $(DIR_BENCH_VHDL)/ram_8x512_hi.vhd
SRC_test_sys += $(DIR_BENCH_VHDL)/ram_8x512_lo.vhd
SRC_test_sys += $(DIR_BENCH_VHDL)/rom_8x2k_hi.vhd
SRC_test_sys += $(DIR_BENCH_VHDL)/rom_8x2k_lo.vhd
SRC_test_sys += $(HDL_SRC_MOD_msp_gpio)
SRC_test_sys += $(HDL_SRC_MOD_msp_serial)
$(eval $(call TEMPLATE_SIMULATE,test_sys))


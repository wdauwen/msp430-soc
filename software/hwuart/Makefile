PROJECT = hwuart
CPU = msp430f2330       # 8KB + 1024B
ROM_OFFSET = 0xE000

include ../Makefile.defs

all:: $(COMPILER)/$(PROJECT).elf

IPATH+=-I.
IPATH+=-I../../rtl/cores/msp430-serial/soft/include
IPATH+=-I../../rtl/cores/msp430-gpio/soft/include
IPATH+=-I../generic/include

VPATH+=../../rtl/cores/msp430-serial/soft
	
# Sources to compile
$(COMPILER)/$(PROJECT).elf: $(COMPILER)/main.o
$(COMPILER)/$(PROJECT).elf: $(COMPILER)/mspserial.o

# Include project dependencies
ifneq (${MAKECMDGOALS},clean)
-include ${wildcard ${COMPILER}/*.d} __dummy__
endif

all: .subprojectinit
all: synthesis/xilinx/mspsoc.bit

.subprojectinit:
	@git submodule update --init
	@touch $(@)

synthesis/xilinx/mspsoc.bit:
	@cd synthesis; $(MAKE)

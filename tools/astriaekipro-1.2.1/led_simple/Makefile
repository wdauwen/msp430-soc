#!/usr/bin/make
VERSION=2.0.0
PROJECT=ISE-examples-$(VERSION)

all: synth

synth:
	make -C FPGA/ejemplo

clean:
	rm -rf .*~
	$(MAKE) -C FPGA/ejemplo clean

tarball:
	-mkdir $(PROJECT) 2> /dev/null
	cp *.sh *.vhdl *.txt *.prj *.xst $(PROJECT)
	cp /usr/share/common-licenses/GPL $(PROJECT)/LICENSE
	tar zcvf ../$(PROJECT).tar.gz $(PROJECT)
	rm -r $(PROJECT)


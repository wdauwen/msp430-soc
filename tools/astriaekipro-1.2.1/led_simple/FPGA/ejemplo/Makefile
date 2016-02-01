#!/usr/bin/make
##############################################################################
#
#  Led example [Makefile]
#
#  Internal file, can't be downloaded.
#
#  Description:
#  That's a GNU Make's Makefile used synthetize the led example.
#
#  To Do:
#  -
#
#  Author:
#    - Salvador E. Tropea, salvador@inti.gov.ar
#
##############################################################################
#
#  Copyright (c) 2007 Salvador E. Tropea <salvador@inti.gov.ar>
#  Copyright (c) 2007 Instituto Nacional de Tecnología Industrial
#
#  For internal use, all rights reserved.
#
##############################################################################

# Configurar
# Configuration
PRJ=led
RELSRC=../..

# Parámetros
# Arguments
SET_XIL_BASE=/usr/local/ISEWb
GENDIR=gen
TARGETB=$(GENDIR)/$(PRJ)
TARGET=$(TARGETB).bit
DEPE=$(wildcard *.vhdl) $(wildcard $(RELSRC)/*.vhdl) $(PRJ).xst $(PRJ).prj

all: $(GENDIR) $(GENDIR)/xst $(GENDIR)/tmp $(TARGET) $(PRJ).txt

$(GENDIR):
	mkdir $@

$(GENDIR)/xst:
	mkdir $@

$(GENDIR)/tmp:
	mkdir $@

$(TARGETB).ngc: $(DEPE)
	. $(SET_XIL_BASE)/settings.sh ; cd $(GENDIR) ; \
	xst -intstyle ise -ifn ../$(PRJ).xst -ofn $(PRJ).syr

$(TARGETB).ngd: $(TARGETB).ngc
	. $(SET_XIL_BASE)/settings.sh ; cd $(GENDIR) ; \
	ngdbuild $(PRJ)

$(TARGETB)_map.ncd: $(TARGETB).ngd
	. $(SET_XIL_BASE)/settings.sh ; cd $(GENDIR) ; \
	map -o $(PRJ)_map.ncd $(PRJ)

$(TARGETB).ncd: $(TARGETB)_map.ncd
	. $(SET_XIL_BASE)/settings.sh ; cd $(GENDIR) ; \
	par -w -ol high $(PRJ)_map.ncd $(PRJ).ncd

$(TARGETB).twr: $(TARGETB).ncd
	. $(SET_XIL_BASE)/settings.sh ; cd $(GENDIR) ; \
	trce -u -a $(PRJ) $(PRJ)_map

$(TARGET): $(TARGETB).ncd
	. $(SET_XIL_BASE)/settings.sh ; cd $(GENDIR) ; \
	bitgen -g startupclk:Cclk -g Compress -w $(PRJ) $(PRJ).bit

$(PRJ).txt: $(TARGETB)_map.ncd $(TARGETB).twr
	./resumen_xil.pl $(PRJ) $(GENDIR) $(RELSRC)/Changelog

clean:
	rm -rf .*~ $(GENDIR)

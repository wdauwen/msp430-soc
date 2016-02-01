CPPFIO=cppfio
BITINFO=bitinfo-0.3

ifdef DEBUG
CFLAGS=-O2 -Wall -Werror -g3
else
CFLAGS=-O2
endif

CXXFLAGS=$(CFLAGS) -I$(CPPFIO) -L$(CPPFIO) -I$(BITINFO)
VERSION=$(shell perl version.pl astriaekipro.cc)
PKG=astriaekipro-$(VERSION)
DPKG=astriaekipro_$(VERSION)
export

.PHONY: cppfio bitfile clean

all: cppfio bitfile astriaekipro

astriaekipro.o: astriaekipro.cc bpi_server.h
	$(CXX) -o $@ -c $(CXXFLAGS) -DBPI_SERVER=1 $<

bpi_server.h:
	$(MAKE) -f bpi_server.mak

astriaekipro: astriaekipro.o $(BITINFO)/bitfile.o $(CPPFIO)/libcppfio.a
	$(CXX) -o $@ $(CXXFLAGS) astriaekipro.o $(BITINFO)/bitfile.o `cppfio/cppfio_config --dlibs`

cppfio:
	$(MAKE) -C $(CPPFIO)

$(CPPFIO)/libcppfio.a:
	$(MAKE) -C $(CPPFIO)

bitfile:
	$(MAKE) -C bitinfo-0.3

$(BITINFO)/bitfile.o:
	$(MAKE) -C bitinfo-0.3

$(BPISERVER):
	make -C bitstreams

clean:
	rm -f *.o astriaekipro astriaekipro-base .*~
	$(MAKE) -C $(CPPFIO) clean
	$(MAKE) -C $(BITINFO) clean
	$(MAKE) -C led_simple clean

debian/control: debian/packages debian/yada
	debian/yada rebuild control

debian/rules: debian/packages debian/yada
	debian/yada rebuild rules

deb: clean debian/control debian/rules
	COMPRESS=1 $(MAKE) astriaekipro
	fakeroot dpkg-buildpackage -b -uc

upload: deb tarball
	scp $(PKG).tar.bz2 ../$(DPKG)*.deb set@frs.sf.net:uploads

tarball:
	$(MAKE) -C $(CPPFIO) clean
	$(MAKE) -C $(BITINFO) clean
	$(MAKE) -C led_simple clean
	mkdir $(PKG)
	cp -rL $(BITINFO) $(PKG)
	cp -rL $(CPPFIO) $(PKG)
	cp -r led_simple $(PKG)
	cp *.c* *.h 0README.txt Makefile version.pl $(PKG)
	rm `find $(PKG)/led_simple -name .cvsignore`
	rm -rf `find $(PKG) -name CVS`
	rm $(PKG)/led_simple/*.epr $(PKG)/led_simple/.*.dst $(PKG)/led_simple/Changelog
	rm $(PKG)/$(BITINFO)/lista $(PKG)/$(CPPFIO)/lista $(PKG)/*/.cvsignore
	rm $(PKG)/$(BITINFO)/COPYING $(PKG)/$(BITINFO)/Changelog
	cp /usr/share/common-licenses/GPL-2 $(PKG)/LICENSE
	tar jcvf $(PKG).tar.bz2 $(PKG)
	rm -r $(PKG)


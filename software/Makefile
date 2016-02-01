# libraries to build
DIRS += utils

# applications
DIRS += dac
DIRS += hwuart
DIRS += leds
DIRS += midi_leds
DIRS += server

all::
	@for i in ${DIRS};                  \
	 do                                 \
	     if [ -f $${i}/Makefile ];      \
	     then                           \
	         make -C $${i} || exit $$?; \
	     fi;                            \
	 done

clean::
	@for i in ${DIRS};                  \
	 do                                 \
	     if [ -f $${i}/Makefile ];      \
	     then                           \
	         make -C $${i} clean || exit $$?; \
	     fi;                            \
	 done


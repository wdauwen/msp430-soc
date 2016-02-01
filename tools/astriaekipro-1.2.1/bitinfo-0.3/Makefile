# Makefile for bitfile routines

ifdef DEBUG
CFLAGS=-O2 -Wall -Werror -g3
else
CFLAGS=-O2
endif
OBJECTS = bitinfo.o bitfile.o
# Avoid inheriting a list of libs, I really need it
LDLIBS =

all: bitinfo

bitinfo.o: bitinfo.c bitfile.h
bitfile.o: bitfile.c bitfile.h
bitinfo: bitinfo.o bitfile.o

clean:
	rm -f ${OBJECTS} bitinfo .*~

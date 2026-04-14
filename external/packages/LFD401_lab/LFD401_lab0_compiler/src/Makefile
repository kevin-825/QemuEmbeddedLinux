# Auto-generated Makefile for LFD401_lab0_compiler
CC ?= gcc
CFLAGS ?= -Wall -O2 -pthread
LDFLAGS ?= -lpthread

# Resolve all source files
MODULE_SRCs := $(wildcard *.c)
MODULE_ASMs := $(wildcard *.S) $(wildcard *.s)

# Map sources to objects modularly
MODULE_OBJs := $(MODULE_SRCs:.c=.o)
MODULE_OBJs += $(MODULE_ASMs:.S=.o)
MODULE_OBJs := $(MODULE_OBJs:.s=.o)

.PHONY: all clean

all: LFD401_lab0_compiler

LFD401_lab0_compiler: $(MODULE_OBJs)
	$(CC) $(LDFLAGS) -o $@ $^

# Implicit Pattern Rules
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.s
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f *.o LFD401_lab0_compiler

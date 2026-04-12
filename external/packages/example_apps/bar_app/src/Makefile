# Auto-generated Makefile for bar_app
CC ?= gcc
CFLAGS ?= -Wall -O2
MODULE_SRCs := $(wildcard *.c)
MODULE_ASMs := $(wildcard *.S)
MODULE_ASMs += $(wildcard *.s)
MODULE_OBJs := $(MODULE_SRCs:.c=.o) $(MODULE_ASMs:.S=.o)

.PHONY: all clean

all: bar_app

bar_app: $(MODULE_OBJs)
	$(CC) $(LDFLAGS) -o $@ $^

$(MODULE_OBJs): %.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(MODULE_OBJs): %.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<
$(MODULE_OBJs): %.o: %.s
    $(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f *.o bar_app

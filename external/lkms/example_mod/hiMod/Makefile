# ==============================================================================
# Out-of-Tree Kernel Module Makefile
# ==============================================================================

# Module definition
MODULE_NAME := hiMod
obj-m += $(MODULE_NAME).o
MODULE_SRCs := $(wildcard src/*.c)
MODULE_OBJs := $(MODULE_SRCs:.c=.o)
$(MODULE_NAME)-y := $(MODULE_OBJs)

# Build environment paths
KDIR        ?= $(KBUILD_OUT_DIR)
PWD         := $(shell pwd)
# ==============================================================================
# Build Targets
# ==============================================================================
.PHONY: all clean install $(MODULE_NAME)

all: $(MODULE_NAME)

$(MODULE_NAME):
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install

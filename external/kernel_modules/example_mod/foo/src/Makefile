MODULE_NAME = foo

# ------------------------------------------------------------------------------
# PATH 1: Kbuild Context (Invoked by Buildroot)
# ------------------------------------------------------------------------------
ifneq ($(KERNELRELEASE),)

$(info ">>> [Info] Running in Kbuild context. Building foo as a kernel module.")

obj-m += $(MODULE_NAME).o

# Kbuild sets $(src) to the absolute path of this directory
MODULE_SRCs := $(wildcard $(src)/*.c)
MODULE_OBJs := $(patsubst $(src)/%.c,%.o,$(MODULE_SRCs))

$(MODULE_NAME)-y := $(MODULE_OBJs)

# ------------------------------------------------------------------------------
# PATH 2: Manual GNU Make Context (Invoked directly by the user)
# ------------------------------------------------------------------------------
else
$(info ">>> [Info] Running in manual make context.")
$(info ">>> [Info] Exported variables: ARCH=$(ARCH), CROSS_COMPILE=$(CROSS_COMPILE), PRE_BUILT_KERNEL_OUT_DIR=$(PRE_BUILT_KERNEL_OUT_DIR)")

# --- Strict Environment Checks ---
ifndef ARCH
$(error [FATAL] ARCH is not exported in the environment. Please run your setup script first.)
endif

ifndef CROSS_COMPILE
$(error [FATAL] CROSS_COMPILE is not exported in the environment. Please run your setup script first.)
endif

ifndef PRE_BUILT_KERNEL_OUT_DIR
$(error [FATAL] PRE_BUILT_KERNEL_OUT_DIR is not exported in the environment. Please run your setup script first.)
endif

PWD := $(shell pwd)

.PHONY: all clean install

all:
	$(MAKE) -C $(PRE_BUILT_KERNEL_OUT_DIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

clean:
	$(MAKE) -C $(PRE_BUILT_KERNEL_OUT_DIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean

install:
	$(MAKE) -C $(PRE_BUILT_KERNEL_OUT_DIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) INSTALL_MOD_PATH=$(INSTALL_DIR) modules_install

endif

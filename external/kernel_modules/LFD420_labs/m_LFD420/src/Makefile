# ==============================================================================
# Enterprise Kernel Module Makefile
# ==============================================================================

MODULE_NAME := m_LFD420

# --- Versioning ---
VERSION_MAJOR := 1
VERSION_MINOR := 0
VERSION_PATCH := 0
DRIVER_VERSION := $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)

# ------------------------------------------------------------------------------
# PHASE 1: Kbuild Context (Kernel Build System)
# ------------------------------------------------------------------------------
ifneq ($(KERNELRELEASE),)

    # 1. Base Compiler Flags
    $(info ################src:$(src)##################)
    ccflags-y := -I$(src)/uapi -I$(src) -Wall -Werror \
                 -DDRIVER_VERSION_MAJOR=$(VERSION_MAJOR) \
                 -DDRIVER_VERSION_MINOR=$(VERSION_MINOR) \
                 -DDRIVER_VERSION_PATCH=$(VERSION_PATCH) \
                 -DDRIVER_VERSION=\"$(DRIVER_VERSION)\"


    # 3. In-Tree / Out-of-Tree Configuration Switch (M or Y)
    CONFIG_M_LFD420 ?= m

    # 4. Define the core module
    obj-$(CONFIG_M_LFD420) += $(MODULE_NAME).o m_LFD420_task.o m_LFD420_mod_param.o

    # 5. Core source files always compiled (Renamed as requested)
    $(MODULE_NAME)-y := $(MODULE_NAME)_core.o

    m_LFD420_task-y := m_LFD420_l6_task.o
    m_LFD420_mod_param-y := m_LFD420_l7_mod_param.o
    
	# 6. Conditional Feature Flags (e.g., make DEBUG_ENABLE=y)
    ifeq ($(DEBUG_ENABLE),y)
        ccflags-y += -DDEBUG_MODE_ENABLED
        $(MODULE_NAME)-y += $(MODULE_NAME)_debug.o
    endif

# ------------------------------------------------------------------------------
# PHASE 2: Standard Make Context (User Terminal)
# ------------------------------------------------------------------------------
else

    # --- Paths & Toolchain ---
    KDIR ?= /lib/modules/$(shell uname -r)/build
    PWD := $(shell pwd)

    # --- Dependencies & Deployment ---
    DEPENDENCY_DIRS := 
    
    # Dynamically generate the absolute paths to all Module.symvers files
    KBUILD_EXTRA_SYMBOLS := $(foreach dir, $(DEPENDENCY_DIRS), $(abspath $(dir)/Module.symvers))

    # Deployment paths for cross-compiled rootfs
    INSTALL_MOD_PATH ?= $(PWD)/deploy
    INSTALL_MOD_DIR ?= extra
    DESTDIR ?= /

    # Cross-Compile Guardrail
    ifeq ($(ARCH),)
        $(warning WARNING: ARCH is not set. Building for native host architecture!)
    endif

# --- Standard Build Targets ---

.PHONY: all
all: modules

.PHONY: modules
modules:
	$(MAKE) -C $(KDIR) M=$(PWD) \
		KBUILD_EXTRA_SYMBOLS="$(KBUILD_EXTRA_SYMBOLS)" \
		modules

.PHONY: clean
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	rm -f *.dtb *.dtbo
	# Guardrail: Never run rm -rf $(INSTALL_MOD_PATH) here!

.PHONY: install
install:
	@echo "Installing modules to $(INSTALL_MOD_PATH)/lib/modules/..."
	$(MAKE) -C $(KDIR) M=$(PWD) \
		INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) \
		INSTALL_MOD_DIR=$(INSTALL_MOD_DIR) \
		modules_install

# --- Enterprise Developer Targets ---

.PHONY: install_headers
install_headers:
	@echo "Exporting UAPI headers to User-Space..."
	install -d $(DESTDIR)/usr/include/linux
	install -m 644 uapi/$(MODULE_NAME)_uapi.h $(DESTDIR)/usr/include/linux/$(MODULE_NAME)_uapi.h

.PHONY: dtbs
dtbs:
	@echo "Compiling Device Tree Overlay..."
	$(KDIR)/scripts/dtc/dtc -@ -I dts -O dtb -o $(MODULE_NAME)_overlay.dtbo dts/$(MODULE_NAME).dts

.PHONY: checkpatch
checkpatch:
	@echo "Running Linux checkpatch..."
	$(KDIR)/scripts/checkpatch.pl --no-tree -f $(wildcard *.c uapi/*.h)

.PHONY: sparse
sparse:
	@echo "Running Sparse static analysis..."
	$(MAKE) -C $(KDIR) M=$(PWD) C=1 CF="-D__CHECK_ENDIAN__" modules

# --- Secure Boot Signing (Commented out for future use) ---
# SIGN_KEY ?= $(KDIR)/certs/signing_key.pem
# SIGN_CERT ?= $(KDIR)/certs/signing_key.x509
#
# .PHONY: sign
# sign:
# 	@echo "Signing $(MODULE_NAME).ko for Secure Boot..."
# 	$(KDIR)/scripts/sign-file sha256 $(SIGN_KEY) $(SIGN_CERT) $(MODULE_NAME).ko

endif

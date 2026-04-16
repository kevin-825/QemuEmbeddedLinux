################################################################################
# LAB0_PRIMITIVE
################################################################################

LAB0_PRIMITIVE_VERSION = 1.0.0
LAB0_PRIMITIVE_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/LFD420_labs/lab0_primitive/src
LAB0_PRIMITIVE_SITE_METHOD = local

# --- Hierarchical Debug Logic ---
# Default to OFF
LAB0_PRIMITIVE_DEBUG_FLAG = DEBUG_ENABLE=n

# Turn ON if the Global override is active
ifeq ($(BR2_GLOBAL_KMOD_DEBUG),y)
    LAB0_PRIMITIVE_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# Turn ON if this specific module's debug is active
ifeq ($(BR2_PACKAGE_LAB0_PRIMITIVE_DEBUG),y)
    LAB0_PRIMITIVE_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# 1. Tell Buildroot this package exports public files to other packages
LAB0_PRIMITIVE_INSTALL_STAGING = YES


# --- Kernel Module Configuration ---
LAB0_PRIMITIVE_MODULE_MAKE_OPTS = \
    CONFIG_LAB0_PRIMITIVE=m \
    $( LAB0_PRIMITIVE_DEBUG_FLAG ) \
    DEPENDENCY_DIRS=""


# 2. Tell Buildroot HOW to install the header into the staging sysroot
define LAB0_PRIMITIVE_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install_headers
endef

# --- Package Evaluation ---
$(eval $(kernel-module))
$(eval $(generic-package))

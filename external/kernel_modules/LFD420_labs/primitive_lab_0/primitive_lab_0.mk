################################################################################
# PRIMITIVE_LAB_0
################################################################################

PRIMITIVE_LAB_0_VERSION = 1.0.0
PRIMITIVE_LAB_0_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/LFD420_labs/primitive_lab_0/src
PRIMITIVE_LAB_0_SITE_METHOD = local

# --- Hierarchical Debug Logic ---
# Default to OFF
PRIMITIVE_LAB_0_DEBUG_FLAG = DEBUG_ENABLE=n

# Turn ON if the Global override is active
ifeq ($(BR2_GLOBAL_KMOD_DEBUG),y)
    PRIMITIVE_LAB_0_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# Turn ON if this specific module's debug is active
ifeq ($(BR2_PACKAGE_PRIMITIVE_LAB_0_DEBUG),y)
    PRIMITIVE_LAB_0_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# 1. Tell Buildroot this package exports public files to other packages
PRIMITIVE_LAB_0_INSTALL_STAGING = YES


# --- Kernel Module Configuration ---
PRIMITIVE_LAB_0_MODULE_MAKE_OPTS = \
    CONFIG_PRIMITIVE_LAB_0=m \
    $( PRIMITIVE_LAB_0_DEBUG_FLAG ) \
    DEPENDENCY_DIRS=""


# 2. Tell Buildroot HOW to install the header into the staging sysroot
define PRIMITIVE_LAB_0_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install_headers
endef

# --- Package Evaluation ---
$(eval $(kernel-module))
$(eval $(generic-package))

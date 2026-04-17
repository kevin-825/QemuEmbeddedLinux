################################################################################
# M_LFD420_L5_PRODUCER
################################################################################

M_LFD420_L5_PRODUCER_VERSION = 1.0.0
M_LFD420_L5_PRODUCER_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/LFD420_labs/m_LFD420_l5_producer/src
M_LFD420_L5_PRODUCER_SITE_METHOD = local

# --- Hierarchical Debug Logic ---
# Default to OFF
M_LFD420_L5_PRODUCER_DEBUG_FLAG = DEBUG_ENABLE=n

# Turn ON if the Global override is active
ifeq ($(BR2_GLOBAL_KMOD_DEBUG),y)
    M_LFD420_L5_PRODUCER_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# Turn ON if this specific module's debug is active
ifeq ($(BR2_PACKAGE_M_LFD420_L5_PRODUCER_DEBUG),y)
    M_LFD420_L5_PRODUCER_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# 1. Tell Buildroot this package exports public files to other packages
M_LFD420_L5_PRODUCER_INSTALL_STAGING = YES


# --- Kernel Module Configuration ---
M_LFD420_L5_PRODUCER_MODULE_MAKE_OPTS = \
    CONFIG_M_LFD420_L5_PRODUCER=m \
    $( M_LFD420_L5_PRODUCER_DEBUG_FLAG ) \
    DEPENDENCY_DIRS="" \
    KBUILD_EXTRA_SYMBOLS=""


# 2. Tell Buildroot HOW to install the header into the staging sysroot
define M_LFD420_L5_PRODUCER_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install_headers
endef

# --- Package Evaluation ---
$(eval $(kernel-module))
$(eval $(generic-package))

################################################################################
# M_HELLOMOD
################################################################################

M_HELLOMOD_VERSION = 1.0.0
M_HELLOMOD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/example_mod/m_HelloMod/src
M_HELLOMOD_SITE_METHOD = local

# --- Hierarchical Debug Logic ---
# Default to OFF
M_HELLOMOD_DEBUG_FLAG = DEBUG_ENABLE=n

# Turn ON if the Global override is active
ifeq ($(BR2_GLOBAL_KMOD_DEBUG),y)
    M_HELLOMOD_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# Turn ON if this specific module's debug is active
ifeq ($(BR2_PACKAGE_M_HELLOMOD_DEBUG),y)
    M_HELLOMOD_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# 1. Tell Buildroot this package exports public files to other packages
M_HELLOMOD_INSTALL_STAGING = YES


# --- Kernel Module Configuration ---
M_HELLOMOD_MODULE_MAKE_OPTS = \
    CONFIG_M_HELLOMOD=m \
    $( M_HELLOMOD_DEBUG_FLAG ) \
    DEPENDENCY_DIRS=""


# 2. Tell Buildroot HOW to install the header into the staging sysroot
define M_HELLOMOD_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install_headers
endef

# --- Package Evaluation ---
$(eval $(kernel-module))
$(eval $(generic-package))

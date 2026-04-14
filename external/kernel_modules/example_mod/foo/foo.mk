################################################################################
# FOO
################################################################################

FOO_VERSION = 1.0.0
FOO_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/example_mod/foo/src
FOO_SITE_METHOD = local

# --- Hierarchical Debug Logic ---
# Default to OFF
FOO_DEBUG_FLAG = DEBUG_ENABLE=n

# Turn ON if the Global override is active
ifeq ($(BR2_GLOBAL_KMOD_DEBUG),y)
    FOO_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# Turn ON if this specific module's debug is active
ifeq ($(BR2_PACKAGE_FOO_DEBUG),y)
    FOO_DEBUG_FLAG = DEBUG_ENABLE=y
endif

# 1. Tell Buildroot this package exports public files to other packages
FOO_INSTALL_STAGING = YES


# --- Kernel Module Configuration ---
FOO_MODULE_MAKE_OPTS = \
    CONFIG_FOO=m \
    $( FOO_DEBUG_FLAG ) \
    DEPENDENCY_DIRS=""


# 2. Tell Buildroot HOW to install the header into the staging sysroot
define FOO_INSTALL_STAGING_CMDS
	$(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) install_headers
endef

# --- Package Evaluation ---
$(eval $(kernel-module))
$(eval $(generic-package))

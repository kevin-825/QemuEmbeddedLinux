HELLLO_VERSION = local
HELLLO_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/package/example_apps/helllo/src
HELLLO_SITE_METHOD = local

define HELLLO_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) all
endef

define HELLLO_INSTALL_TARGET_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))

HELLO_VERSION = local
HELLO_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/package/apps/hello/src
HELLO_SITE_METHOD = local

define HELLO_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) all
endef

define HELLO_INSTALL_TARGET_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))

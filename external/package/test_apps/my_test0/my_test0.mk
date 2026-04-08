MY_TEST0_VERSION = local
MY_TEST0_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/package/test_apps/my_test0/src
MY_TEST0_SITE_METHOD = local

define MY_TEST0_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) all
endef

define MY_TEST0_INSTALL_TARGET_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))

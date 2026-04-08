TEMP_TEST_VERSION = local
TEMP_TEST_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/package/test_apps/temp_test/src
TEMP_TEST_SITE_METHOD = local

define TEMP_TEST_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) all
endef

define TEMP_TEST_INSTALL_TARGET_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(\@D) DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))

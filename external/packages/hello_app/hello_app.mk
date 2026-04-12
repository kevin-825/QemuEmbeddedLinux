################################################################################
# hello_app
################################################################################

HELLO_APP_VERSION = 1.0
HELLO_APP_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/hello_app/src
HELLO_APP_SITE_METHOD = local

define HELLO_APP_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define HELLO_APP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/hello_app $(TARGET_DIR)/usr/bin/hello_app
endef

$(eval $(generic-package))

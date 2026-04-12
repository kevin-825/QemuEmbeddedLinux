################################################################################
# foo_app
################################################################################

FOO_APP_VERSION = 1.0
FOO_APP_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/example_apps/foo_app/src
FOO_APP_SITE_METHOD = local

define FOO_APP_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define FOO_APP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/foo_app $(TARGET_DIR)/usr/bin/foo_app
endef

$(eval $(generic-package))

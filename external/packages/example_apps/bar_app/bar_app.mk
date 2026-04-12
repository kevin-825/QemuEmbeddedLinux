################################################################################
# bar_app
################################################################################

BAR_APP_VERSION = 1.0
BAR_APP_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/example_apps/bar_app/src
BAR_APP_SITE_METHOD = local

define BAR_APP_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define BAR_APP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bar_app $(TARGET_DIR)/usr/bin/bar_app
endef

$(eval $(generic-package))

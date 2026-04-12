################################################################################
# hello_world
################################################################################

HELLO_WORLD_VERSION = 1.0
HELLO_WORLD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/example_apps/hello_world/src
HELLO_WORLD_SITE_METHOD = local

define HELLO_WORLD_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define HELLO_WORLD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/hello_world $(TARGET_DIR)/usr/bin/hello_world
endef

$(eval $(generic-package))

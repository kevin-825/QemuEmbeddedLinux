################################################################################
# a_hello_world
################################################################################

A_HELLO_WORLD_VERSION = 1.0
A_HELLO_WORLD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/example_apps/a_hello_world/src
A_HELLO_WORLD_SITE_METHOD = local

define A_HELLO_WORLD_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define A_HELLO_WORLD_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/a_hello_world $(TARGET_DIR)/usr/bin/a_hello_world
endef

$(eval $(generic-package))

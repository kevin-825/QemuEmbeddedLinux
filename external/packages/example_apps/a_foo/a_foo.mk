################################################################################
# a_foo
################################################################################

A_FOO_VERSION = 1.0
A_FOO_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/example_apps/a_foo/src
A_FOO_SITE_METHOD = local

define A_FOO_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define A_FOO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/a_foo $(TARGET_DIR)/usr/bin/a_foo
endef

$(eval $(generic-package))

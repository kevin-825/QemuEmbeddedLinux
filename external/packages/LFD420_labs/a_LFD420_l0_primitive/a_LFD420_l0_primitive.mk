################################################################################
# a_LFD420_l0_primitive
################################################################################

A_LFD420_L0_PRIMITIVE_VERSION = 1.0
A_LFD420_L0_PRIMITIVE_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/LFD420_labs/a_LFD420_l0_primitive/src
A_LFD420_L0_PRIMITIVE_SITE_METHOD = local

define A_LFD420_L0_PRIMITIVE_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define A_LFD420_L0_PRIMITIVE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/a_LFD420_l0_primitive $(TARGET_DIR)/usr/bin/a_LFD420_l0_primitive
endef

$(eval $(generic-package))

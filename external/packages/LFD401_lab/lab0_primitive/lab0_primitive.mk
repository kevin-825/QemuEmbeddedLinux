################################################################################
# lab0_primitive
################################################################################

LAB0_PRIMITIVE_VERSION = 1.0
LAB0_PRIMITIVE_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/LFD401_lab/lab0_primitive/src
LAB0_PRIMITIVE_SITE_METHOD = local

define LAB0_PRIMITIVE_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define LAB0_PRIMITIVE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/lab0_primitive $(TARGET_DIR)/usr/bin/lab0_primitive
endef

$(eval $(generic-package))

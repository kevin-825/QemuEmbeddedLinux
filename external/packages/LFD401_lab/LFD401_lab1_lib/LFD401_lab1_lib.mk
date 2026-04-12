################################################################################
# LFD401_lab1_lib
################################################################################

LFD401_LAB1_LIB_VERSION = 1.0
LFD401_LAB1_LIB_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/LFD401_lab/LFD401_lab1_lib/src
LFD401_LAB1_LIB_SITE_METHOD = local

define LFD401_LAB1_LIB_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define LFD401_LAB1_LIB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/LFD401_lab1_lib $(TARGET_DIR)/usr/bin/LFD401_lab1_lib
endef

$(eval $(generic-package))

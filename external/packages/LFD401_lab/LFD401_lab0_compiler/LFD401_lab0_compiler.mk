################################################################################
# LFD401_lab0_compiler
################################################################################

LFD401_LAB0_COMPILER_VERSION = 1.0
LFD401_LAB0_COMPILER_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages/LFD401_lab/LFD401_lab0_compiler/src
LFD401_LAB0_COMPILER_SITE_METHOD = local

define LFD401_LAB0_COMPILER_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) all
endef

define LFD401_LAB0_COMPILER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/LFD401_lab0_compiler $(TARGET_DIR)/usr/bin/LFD401_lab0_compiler
endef

$(eval $(generic-package))

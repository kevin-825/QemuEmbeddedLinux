KEVINSMOD_VERSION = local
KEVINSMOD_KCONFIG_VAR = BR2_EXT_KERNEL_MODULES_KEVINSMOD
KEVINSMOD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/lkms/example_mod/KevinsMod
KEVINSMOD_SITE_METHOD = local

# Assumes kernel-module infrastructure. Requires Kbuild/Makefile in src/
$(eval $(kernel-module))
$(eval $(generic-package))

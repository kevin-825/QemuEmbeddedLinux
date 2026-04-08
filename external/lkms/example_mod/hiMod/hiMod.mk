HIMOD_VERSION = local
HIMOD_KCONFIG_VAR = BR2_EXT_KERNEL_MODULES_HIMOD
HIMOD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/lkms/example_mod/hiMod
HIMOD_SITE_METHOD = local

# Assumes kernel-module infrastructure. Requires Kbuild/Makefile in src/
$(eval $(kernel-module))
$(eval $(generic-package))

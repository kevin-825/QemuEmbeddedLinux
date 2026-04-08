HELLOMOD_VERSION = local
HELLOMOD_KCONFIG_VAR = BR2_EXT_KERNEL_MODULES_HELLOMOD
HELLOMOD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/lkms/example_mod/helloMod
HELLOMOD_SITE_METHOD = local

# Assumes kernel-module infrastructure. Requires Kbuild/Makefile in src/
$(eval $(kernel-module))
$(eval $(generic-package))

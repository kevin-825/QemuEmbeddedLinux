EXAMPLE_KERNEL_MOD_VERSION = local
EXAMPLE_KERNEL_MOD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/linux/example_kernel_mod/src
EXAMPLE_KERNEL_MOD_SITE_METHOD = local

# Assumes kernel-module infrastructure. Requires Kbuild/Makefile in src/
$(eval $(kernel-module))
$(eval $(generic-package))

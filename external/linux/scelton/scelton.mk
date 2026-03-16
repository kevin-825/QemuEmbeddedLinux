SCELTON_VERSION = local
SCELTON_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/linux/scelton/src
SCELTON_SITE_METHOD = local

# Assumes kernel-module infrastructure. Requires Kbuild/Makefile in src/
$(eval $(kernel-module))
$(eval $(generic-package))

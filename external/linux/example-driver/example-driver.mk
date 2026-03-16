EXAMPLE_DRIVER_VERSION = local
EXAMPLE_DRIVER_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/linux/example-driver/src
EXAMPLE_DRIVER_SITE_METHOD = local

# Assumes kernel-module infrastructure. Requires Kbuild/Makefile in src/
$(eval $(kernel-module))
$(eval $(generic-package))

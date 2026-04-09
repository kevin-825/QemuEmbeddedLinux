################################################################################
# helloMod
################################################################################

HELLOMOD_VERSION = 1.0
HELLOMOD_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/example_mod/helloMod
HELLOMOD_SITE_METHOD = local
HELLOMOD_MODULE_SUBDIR = src

# Optional: Add custom compiler flags here
HELLOMOD_MODULE_MAKE_OPTS =     KCFLAGS="-Werror"

$(eval $(kernel-module))
$(eval $(generic-package))

################################################################################
# foo
################################################################################

FOO_VERSION = 1.0
FOO_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/example_mod/foo
FOO_SITE_METHOD = local
FOO_MODULE_SUBDIR = src

# Optional: Add custom compiler flags here
FOO_MODULE_MAKE_OPTS =     KCFLAGS="-Werror"

$(eval $(kernel-module))
$(eval $(generic-package))

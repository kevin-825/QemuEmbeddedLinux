################################################################################
# primitive_lab_0
################################################################################

PRIMITIVE_LAB_0_VERSION = 1.0
PRIMITIVE_LAB_0_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/LFD420_labs/primitive_lab_0
PRIMITIVE_LAB_0_SITE_METHOD = local
PRIMITIVE_LAB_0_MODULE_SUBDIRS = src

# Optional: Add custom compiler flags here
PRIMITIVE_LAB_0_MODULE_MAKE_OPTS =     KCFLAGS="-Werror"

$(eval $(kernel-module))
$(eval $(generic-package))

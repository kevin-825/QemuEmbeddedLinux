################################################################################
# primitive_lab_1
################################################################################

PRIMITIVE_LAB_1_VERSION = 1.0
PRIMITIVE_LAB_1_SITE = $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules/LFD420_labs/primitive_lab_1
PRIMITIVE_LAB_1_SITE_METHOD = local
PRIMITIVE_LAB_1_MODULE_SUBDIRS = src

# Optional: Add custom compiler flags here
PRIMITIVE_LAB_1_MODULE_MAKE_OPTS =     KCFLAGS="-Werror"

$(eval $(kernel-module))
$(eval $(generic-package))

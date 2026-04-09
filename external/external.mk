# Auto-generated external external.mk

# Include linux kernel modules
include $(sort $(shell find $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/kernel_modules -name "*.mk" 2>/dev/null))

# Include standard packages
include $(sort $(shell find $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/packages -name "*.mk" 2>/dev/null))

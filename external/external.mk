# Include standard packages (using find for infinite depth)
include $(sort $(shell find $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/package -name "*.mk"))

# Include linux kernel extensions (using find for infinite depth)
include $(sort $(shell find $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/lkms -name "*.mk"))

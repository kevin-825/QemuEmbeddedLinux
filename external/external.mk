# Include standard packages
include $(sort $(wildcard $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/package/*/*/*.mk))

# Include linux kernel extensions
include $(sort $(wildcard $(BR2_EXTERNAL_QEMUEMBEDDEDLINUX_PATH)/linux/*/*.mk))

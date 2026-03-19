#!/bin/bash
set -e

BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

echo "=========== Running post-image.sh for qemu_riscv64_virt_board ==========="

# --- THE MAGIC BRIDGE ---
# Check if your build script passed in a custom kernel path
echo "PRE_BUILT_KERNEL_IMAGE: $PRE_BUILT_KERNEL_IMAGE"

if [[ -n "${PRE_BUILT_KERNEL_IMAGE}" ]] && [[ -f "${PRE_BUILT_KERNEL_IMAGE}" ]]; then
    echo ">>> External kernel detected! Injecting into Buildroot images directory..."
    cp "${PRE_BUILT_KERNEL_IMAGE}" "${BINARIES_DIR}/Image"
else
    echo ">>> No external kernel provided. Assuming Buildroot built it natively."
fi
# ------------------------

# Clean up any old temporary genimage files
rm -rf "${GENIMAGE_TMP}"

# Run genimage to construct the sdcard.img
genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

echo ">>> SUCCESS: Bootable SD Card image generated at:"
echo ">>> ${BINARIES_DIR}/sdcard.img"

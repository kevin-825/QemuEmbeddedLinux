#!/bin/bash
set -e

# Buildroot typically passes the binaries directory as the first argument
BINARIES_DIR="${1:-${BINARIES_DIR}}"
BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

echo "=========== Running post-image.sh for qemu_aarch64_virt_board ==========="

# --- MODULES ---

deploy_extlinux() {
    local board_dir="$1"
    local bin_dir="$2"
    local conf_name="extlinux.conf"
    local out_dir="${bin_dir}/extlinux"

    echo ">>> [INFO] Checking for U-Boot Distro Boot configuration..."

    if [[ ! -f "${board_dir}/${conf_name}" ]]; then
        echo ">>> [WARNING] ${conf_name} not found in ${board_dir}. Skipping U-Boot config deployment."
        return 0
    fi

    mkdir -p "${out_dir}"
    cp "${board_dir}/${conf_name}" "${out_dir}/"
    echo ">>> [SUCCESS] Deployed ${conf_name} to ${out_dir}/"
}

# --- EXECUTION ---

# 1. External Kernel Injection
echo "PRE_BUILT_KERNEL_IMAGE: $PRE_BUILT_KERNEL_IMAGE"
if [[ -n "${PRE_BUILT_KERNEL_IMAGE}" ]] && [[ -f "${PRE_BUILT_KERNEL_IMAGE}" ]]; then
    echo ">>> [INFO] External kernel detected! Injecting into Buildroot images directory..."
    cp "${PRE_BUILT_KERNEL_IMAGE}" "${BINARIES_DIR}/Image"
else
    echo ">>> [INFO] No external kernel provided. Assuming Buildroot built it natively."
fi

# 2. Deploy extlinux configuration
deploy_extlinux "${BOARD_DIR}" "${BINARIES_DIR}"

# 3. Image Generation
echo ">>> [INFO] Cleaning up old temporary genimage files..."
rm -rf "${GENIMAGE_TMP}"

echo ">>> [INFO] Running genimage to construct the sdcard.img..."
genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

echo ">>> [SUCCESS] Bootable SD Card image generated at:"
echo ">>> ${BINARIES_DIR}/sdcard.img"

create_flash_bin() {

    echo ">>> [POST-IMAGE] Stitching TF-A and FIP into QEMU flash.bin..."

    # 1. Create a blank 64MB flash chip
    dd if=/dev/zero of="${BINARIES_DIR}/flash.bin" bs=1M count=64 status=none

    # 2. Inject BL1 at the very beginning (0x0)
    dd if="${BINARIES_DIR}/bl1.bin" of="${BINARIES_DIR}/flash.bin" conv=notrunc status=none

    # 3. Inject the FIP (BL2 + BL31 + U-Boot) at offset 0x40000 (block 256 of 1K)
    dd if="${BINARIES_DIR}/fip.bin" of="${BINARIES_DIR}/flash.bin" seek=256 bs=1K conv=notrunc status=none

    echo ">>> [POST-IMAGE] flash.bin created successfully!"
}

create_flash_bin
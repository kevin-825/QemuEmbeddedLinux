#!/bin/bash
set -e

run_qemu_arm64() {
    local kernel_path="$1"
    local sdcard_path="$2"
    shift 2 # Strip the first two args so "$@" only contains the extra flags

    if [[ ! -f "$kernel_path" || ! -f "$sdcard_path" ]]; then
        echo ">>> [ERROR] Kernel path or SD Card image missing!"
        return 1
    fi

    echo ">>> [INFO] Assembling QEMU ARM64 Machine Configuration..."

    # 1. Base Machine Configuration
    local base_args=(
        -M virt
        -cpu cortex-a53
        -m 1024M
        -nographic
        -kernel "$kernel_path"
    )

    # 2. Boot-Specific Configuration
    local boot_args=()
    if [[ "$(basename "$kernel_path")" == *"Image"* ]]; then
        echo ">>> [INFO] Direct Linux boot detected. Injecting bootargs."
        boot_args=( -append "root=/dev/vda2 rw rootwait console=ttyAMA0" )
    else
        echo ">>> [INFO] Bootloader detected. Delegating bootargs to extlinux.conf."
    fi

    # 3. Storage Configuration
    local storage_args=(
        -drive file="$sdcard_path",format=raw,id=hd0,if=none
        -device virtio-blk-device,drive=hd0
    )

    # 4. Network Configuration
    local net_args=(
        -netdev user,id=net0
        -device virtio-net-device,netdev=net0
    )

    echo ">>> [EXEC] Booting QEMU with extra flags: $@"
    echo "----------------------------------------------------------------------"
    
    qemu-system-aarch64 \
        "${base_args[@]}" \
        "${boot_args[@]}" \
        "${storage_args[@]}" \
        "${net_args[@]}" \
        "$@"
}

# --- Execution Block ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then 
        echo "Usage: $0 <kernel_path> <sdcard_path> [extra_qemu_args...]"
        exit 1
    fi
    # Pass all arguments to the modular function
    run_qemu_arm64 "$@"
fi

run_qemu() {
    local output_dir="$1"
    local kernel_path="$output_dir"/images/flash.bin
    local sdcard_path="$output_dir"/images/sdcard.img

    shift 1 # Strip the first arg so "$@" only contains the extra flags

    echo ">>> [INFO] Initializing QEMU Environment..."

    if [[ ! -f "$kernel_path" || ! -f "$sdcard_path" ]]; then
        echo ">>> [ERROR] Kernel or SD Card image missing! kernel_path=$kernel_path, sdcard_path=$sdcard_path"
        return 1
    fi


    # Build the base QEMU arguments
    local qemu_args=(
        -M virt,virtualization=on,secure=on
        -cpu cortex-a53
        -m 1024M
        -nographic
        -drive if=pflash,file="${output_dir}/images/flash.bin",format=raw,readonly=on
        -drive file="${output_dir}/images/sdcard.img",format=raw,id=hd0,if=none
        -device virtio-blk-device,drive=hd0
        -netdev user,id=net0
        -device virtio-net-device,netdev=net0
        "$@" # <--- Inject all passed-through flags here natively!
    )

    echo ">>> [EXEC] Booting QEMU with extra flags: $@"
    echo "----------------------------------------------------------------------"
    echo ">>> [INFO] Final QEMU arguments:"
    for arg in "${qemu_args[@]}"; do
        echo "  $arg"
    done
    echo "----------------------------------------------------------------------"
    qemu-system-aarch64 "${qemu_args[@]}"
}

# Execution block
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then 
        echo "Usage: $0 <output_dir> [extra_qemu_args...]"
        exit 1
    fi
    # Pass all arguments to the function
    run_qemu "$@"
fi

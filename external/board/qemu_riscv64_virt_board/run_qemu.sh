run_qemu() {
    local output_dir="$1"
    local kernel_path="$output_dir"/images/u-boot.bin
    local sdcard_path="$output_dir"/images/sdcard.img
    shift 1 # Strip the first arg so "$@" only contains the extra flags

    echo ">>> [INFO] Initializing QEMU Environment..."

    if [[ ! -f "$kernel_path" || ! -f "$sdcard_path" ]]; then
        echo ">>> [ERROR] Kernel or SD Card image missing!"
        return 1
    fi

    # Build the base QEMU arguments
    local qemu_args=(
        -M virt
        -m 1024M
        -nographic
        -drive file="$sdcard_path",format=raw,id=hd0,if=none
        -device virtio-blk-device,drive=hd0
        -netdev user,id=net0
        -device virtio-net-device,netdev=net0
        -kernel "$kernel_path" -append "root=/dev/vda2 rw rootwait initcall_debug console=ttyS0 earlycon=sbi"
        "$@" # <--- Inject all passed-through flags here natively!
    )

    echo ">>> [EXEC] Booting QEMU with extra flags: $@"
    echo "----------------------------------------------------------------------"
    echo ">>> [INFO] Final QEMU arguments:"
    for arg in "${qemu_args[@]}"; do
        echo "  $arg"
    done
    echo "----------------------------------------------------------------------"
    qemu-system-riscv64 "${qemu_args[@]}"
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

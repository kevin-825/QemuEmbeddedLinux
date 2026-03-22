run_qemu() {
    local kernel_path="$1"
    local sdcard_path="$2"
    shift 2 # Strip the first two args so "$@" only contains the extra flags

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
        -kernel "$kernel_path"
        -drive file="$sdcard_path",format=raw,id=hd0,if=none
        -device virtio-blk-device,drive=hd0
        -netdev user,id=net0
        -device virtio-net-device,netdev=net0
        -append "root=/dev/vda2 rw rootwait console=ttyS0 earlycon=sbi"
        "$@" # <--- Inject all passed-through flags here natively!
    )

    echo ">>> [EXEC] Booting QEMU with extra flags: $@"
    echo "----------------------------------------------------------------------"
    
    qemu-system-riscv64 "${qemu_args[@]}"
}

# Execution block
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then 
        echo "Usage: $0 <kernel_path> <sdcard_path> [extra_qemu_args...]"
        exit 1
    fi
    # Pass all arguments to the function
    run_qemu "$@"
fi

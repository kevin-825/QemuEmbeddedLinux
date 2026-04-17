#!/bin/bash

alias run_in_docker='docker run -it -e TERM=${TERM} --rm ${dockerVolumes} -w $(pwd -P) kflyn825/rvdev:latest'


build_minimal_rv_virt() {
    #export KBUILD_OUT_DIR="/mnt/wsl/ramdisk5/kbuild_out/riscv_virt_minimal_DEBUG_1"
    export PROJECT_ROOT="/mnt/wsl/ramdisk5/QemuEmbeddedLinux"
    export KERNEL_SRC_PATH="/mnt/wsl/ramdisk5/linux"
    mkdir -p "/mnt/wsl/ramdisk5/kbuild_out/riscv"
    cp "$PROJECT_ROOT/external/board/qemu_riscv64_virt_board/kernel_configs/riscv_virt_minimal_DEBUG_defconfig" "/mnt/wsl/ramdisk5/kbuild_out/riscv/.config"
    ./kmake ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- olddefconfig
    ./kmake ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j$(nproc) all

    local rootfs_path="/mnt/wsl/disk2/.br2_output/qemu_riscv64_virt_board/customBuild/images/rootfs.ext4"

    run_in_docker qemu-system-riscv64 \
    -M virt \
    -cpu rv64 \
    -m 1G \
    -smp 4 \
    -nographic \
    -kernel /mnt/wsl/ramdisk5/kbuild_out/riscv/arch/riscv/boot/Image \
    -append "console=ttyS0 root=/dev/vda ro earlycon" \
    -drive file=$rootfs_path,format=raw,id=hd0,if=none \
    -device virtio-blk-device,drive=hd0

}



build_minimal_arm64_virt() {
    export PROJECT_ROOT="/mnt/wsl/ramdisk5/QemuEmbeddedLinux"
    export KERNEL_SRC_PATH="/mnt/wsl/ramdisk5/linux"
    mkdir -p "/mnt/wsl/ramdisk5/kbuild_out/arm64"
    cp "$PROJECT_ROOT/external/board/qemu_aarch64_virt_board/kernel_configs/arm64_virt_minimal_DEBUG_defconfig" "/mnt/wsl/ramdisk5/kbuild_out/arm64/.config"
    ./kmake ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- olddefconfig
    ./kmake ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- -j$(nproc) all

    local rootfs_path="/mnt/wsl/disk2/.br2_output/qemu_aarch64_virt_board/customBuild/images/rootfs.ext4"

    run_in_docker \
    qemu-system-aarch64 \
        -M virt \
        -cpu max \
        -smp 4 \
        -m 2G \
        -kernel /mnt/wsl/ramdisk5/kbuild_out/arm64/arch/arm64/boot/Image \
        -append "root=/dev/vda rw console=ttyAMA0 earlycon" \
        -drive if=none,file=$rootfs_path,id=hd0,format=raw \
        -device virtio-blk-device,drive=hd0 \
        -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
        -nographic

}

add_my_kernel_modules_and_packages() {      

    
    ./setup_external.sh -m external/kernel_modules/LFD420_labs/m_LFD420_l0_primitive
    ./setup_external.sh -m external/kernel_modules/example_mod/m_HelloMod
    ./setup_external.sh -m external/kernel_modules/example_mod/m_foo
    ./setup_external.sh -m external/kernel_modules/LFD420_labs/m_LFD420_l5_producer
    ./setup_external.sh -m external/kernel_modules/LFD420_labs/m_LFD420_l5_consumer



    ./setup_external.sh -p external/packages/example_apps/a_hello_world
    ./setup_external.sh -p external/packages/example_apps/a_foo
    ./setup_external.sh -p external/packages/LFD420_labs/a_LFD420_l0_primitive
    
}


#!/bin/bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export TARGET_BOARD="qemu_riscv64_virt_board"
export BUILD_PROFILE="rootfsOnlyBuild"
echo "script_dir: ${script_dir}"

run_qemu_script="${script_dir}/../external/board/${TARGET_BOARD}/run_qemu.sh"

output_dir="$(${script_dir}/json_resolve_scripts/resolver.sh "${script_dir}/../env.json" "build.output_dir")"
kernel_path="${output_dir}/../kernel/my_linux_DEBUG_defconfig/arch/riscv/boot/Image"
sdcard_path="${output_dir}/images/sdcard.img"

main() {

    echo " run_qemu_script: $run_qemu_script"
    echo " kernel_path: $kernel_path"
    echo " sdcard_path: $sdcard_path"
    #"$run_qemu_script" "$kernel_path" "$sdcard_path" -s -S
    "$run_qemu_script" "$kernel_path" "$sdcard_path" -s -S
}

main 


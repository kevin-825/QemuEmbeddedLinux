#!/bin/bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export PROJECT_ROOT="${script_dir}/../"
echo "script_dir: ${script_dir}"



main() {
    if [[ $# -eq 0 ]]; then
        export TARGET_BOARD="qemu_riscv64_virt_board"
        export BUILD_PROFILE="rootfsOnlyBuild"
    elif [[ $1 == "0" ]]; then
        export TARGET_BOARD="qemu_riscv64_virt_board"
        export BUILD_PROFILE="rootfsOnlyBuild"
    elif [[ $1 == "1" ]]; then
        export TARGET_BOARD="qemu_aarch64_virt_board"
        export BUILD_PROFILE="rootfsOnlyBuild"
    elif [[ $1 == "2" ]]; then
        export TARGET_BOARD="qemu_raspi4b_board"
        export BUILD_PROFILE="rootfsOnlyBuild"
    fi
    run_qemu_script="${script_dir}/../external/board/${TARGET_BOARD}/run_qemu.sh"

    output_dir="$(${script_dir}/json_resolve_scripts/resolver.sh "${script_dir}/../env.json" "build.output_dir")"

    docker_base_cmd="$(${script_dir}/json_resolve_scripts/resolver.sh "${script_dir}/../env.json" "environment.BASE_DOCKER_CMD")"
    docker_img="$(${script_dir}/json_resolve_scripts/resolver.sh "${script_dir}/../env.json" "boards.${TARGET_BOARD}.DOCKER_IMAGE")"
    kernel_defconfig="$(${script_dir}/json_resolve_scripts/resolver.sh "${script_dir}/../env.json" "boards.${TARGET_BOARD}.KERNEL_DEFCONFIG")"

    docker_cmd="${docker_base_cmd} --name debug0  $docker_img"

    kernel_path="$(${script_dir}/json_resolve_scripts/resolver.sh "${script_dir}/../env.json" "build.profiles.${BUILD_PROFILE}.kernel_img_path")"
    sdcard_path="${output_dir}/images/sdcard.img"

    echo "target_board: $TARGET_BOARD"
    echo "build_profile: $BUILD_PROFILE"
    echo "output_dir: $output_dir"
    echo " run_qemu_script: $run_qemu_script"
    echo " kernel_path: $kernel_path"
    echo " sdcard_path: $sdcard_path"
    echo " docker_cmd: $docker_cmd"
    if [[ -f /.dockerenv ]]; then
        # Already in container: Run directly
        "$run_qemu_script" "$kernel_path" "$sdcard_path" -S -s
    else
        # In WSL: Ensure container is running and pass the environment
        $docker_cmd "$run_qemu_script" "$kernel_path" "$sdcard_path" -s -S
    fi
}

main "$@"


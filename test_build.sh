#!/bin/bash

# Source your existing exception handling core
source ./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh

# --- Configuration & Defaults ---
JSON_CFG="./env.json"
jSON_RESOLVER="./scripts/json_resolve_scripts/resolver.sh"
jSON_FILE_RESOLVER="./scripts/json_resolve_scripts/json_resolve_file.sh"
temp(){
    local profile="$1"
    # Use mapfile/readarray to fetch the command array from the resolver
    # We assume resolver.sh handles the .join() logic and returns newline-separated commands
    build_cmds=()
    build_cmd_key="build.${BUILD_PROFILE}.build_cmds.join('    ')"  # This key should resolve to a string of commands separated by '    '
    echo "build_cmd_key: $build_cmd_key" >&2
    build_cmds=($jSON_RESOLVER "$JSON_CFG" "$build_cmd_key")

    if [[ ${#build_cmds[@]} -eq 0 ]]; then
        echo ">>> [ERROR] No build_cmds found for profile: $profile"
        exit 1
    fi
    echo -e ">>> [INFO] Full Buildroot command:\n $BUILD_CMD " | sed -r 's/[[:space:]]{4,}/    \n  /g'
}

resolve_file(){
    local resolved_obj=$($jSON_FILE_RESOLVER -i "$JSON_CFG")
    echo -e ">>> [INFO] Resolved JSON Object:\n" >&2
    echo "xxxxxxxxxxx"
    echo "$resolved_obj"
    echo "xxxxxxxxxxx"
}

main() {
    PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
    echo "Project Root: $PROJECT_ROOT"
    export PROJECT_ROOT
    TARGET_BOARD="qemu_riscv64_virt_board"
    BUILD_PROFILE="rootfsOnlyBuild"
    export TARGET_BOARD BUILD_PROFILE
    #echo "main called with args: $*"

        rebuild_target_str=$($jSON_RESOLVER "$JSON_CFG" "build.rebuild_target_str")
    echo "rebuild_target_str: $rebuild_target_str" >&2
    someTest=$($jSON_RESOLVER "$JSON_CFG" "build.someTest")
    echo "someTest: $someTest" >&2

    local qemu_cmd
    #qemu_cmd=$($jSON_RESOLVER "$JSON_CFG" "build.${BUILD_PROFILE}.qemu_run_cmd")
    #echo -e "qemu_cmd: $qemu_cmd" >&2

    #local rootfsOnly_BR2_OPT
    #rootfsOnly_BR2_OPT=$($jSON_RESOLVER "$JSON_CFG" "${targets.qemu_riscv64_virt_board.rootfsOnly_BR2_OPT.join('    ')}")
    #echo -e "rootfsOnly_BR2_OPT: $rootfsOnly_BR2_OPT" >&2


    #bo=$($jSON_RESOLVER "$JSON_CFG" "build.${BUILD_PROFILE}.build_options")
    #bo=$($jSON_RESOLVER "$JSON_CFG" "targets[]" -k)
    #echo -e "build_options: $bo" >&2

    #local build_cmds
    #build_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.${BUILD_PROFILE}.build_cmds")
    #echo -e "build_cmds: $build_cmds" >&2

    local docker_wrapper
    docker_wrapper=$($jSON_RESOLVER "$JSON_CFG" "environment.DOCKER_WRAPPER" -d)
    echo -e "docker_wrapper: $docker_wrapper" >&2
}

main "$@"

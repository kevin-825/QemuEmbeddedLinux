#!/bin/bash

# Source your existing exception handling core
#source ./script/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh

# --- Configuration & Defaults ---
JSON_CFG="./build_env.json"
jSON_RESOLVER="./scripts/json_resolve_scripts/resolver.sh"
jSON_FILE_RESOLVER="./scripts/json_resolve_scripts/json_resolve_file.sh"
temp(){
    local profile="$1"
    # Use mapfile/readarray to fetch the command array from the resolver
    # We assume resolver.sh handles the .join() logic and returns newline-separated commands
    build_cmds=()
    build_cmd_key="build.${profile}.build_cmds.join('    ')"  # This key should resolve to a string of commands separated by '    '
    echo "build_cmd_key: $build_cmd_key" >&2
    build_cmds=($jSON_RESOLVER "$JSON_CFG" "$build_cmd_key")

    if [[ ${#build_cmds[@]} -eq 0 ]]; then
        echo ">>> [ERROR] No build_cmds found for profile: $profile"
        exit 1
    fi
    echo -e ">>> [INFO] Full Buildroot command:\n $BUILD_CMD " | sed -r 's/[[:space:]]{4,}/    \n  /g'
}

main() {
    PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
    echo "Project Root: $PROJECT_ROOT"
    export PROJECT_ROOT
    TARGET_BOARD="qemu_riscv64_virt_board"
    BUILD_PROFILE="rootfsOnlyBuild"
    export TARGET_BOARD BUILD_PROFILE
    #echo "main called with args: $*"
    local resolved_obj=$($jSON_FILE_RESOLVER -i "$JSON_CFG")
    echo -e ">>> [INFO] Resolved JSON Object:\n" >&2
    echo "xxxxxxxxxxx"
    echo "$resolved_obj"
    echo "xxxxxxxxxxx"
    
    local qemu_cmd
    local profile="rootfsOnlyBuild"
    #qemu_cmd=$($jSON_RESOLVER "$JSON_CFG" "build.${profile}.qemu_run_cmd")
    local tempinfo
    local build_cmds
    local rootfsOnly_BR2_OPT
    #rootfsOnly_BR2_OPT=$($jSON_RESOLVER "$JSON_CFG" "${targets.qemu_riscv64_virt_board.rootfsOnly_BR2_OPT.join('    ')}")
    #tempinfo=$($jSON_RESOLVER "$JSON_CFG" "build.${profile}.qemu_run_cmd")
    #tempinfo=$($jSON_RESOLVER "$JSON_CFG" "build.${profile}.build_cmds")
    #bo=$($jSON_RESOLVER "$JSON_CFG" "build.${profile}.build_options")
    bo=$($jSON_RESOLVER "$JSON_CFG" "targets[]" -k)
    echo -e "tempinfo: $tempinfo" >&2
    echo -e "build_cmds: $build_cmds" >&2
    echo -e "build_options: $bo" >&2
    echo -e "rootfsOnly_BR2_OPT: $rootfsOnly_BR2_OPT" >&2

    

}

main "$@"

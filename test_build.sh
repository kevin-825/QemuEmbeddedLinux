#!/bin/bash

# Source your existing exception handling core
source ./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh

# --- Configuration & Defaults ---
JSON_CFG="./env.json"
jSON_RESOLVER="./scripts/json_resolve_scripts/resolver.sh"
jSON_FILE_RESOLVER="./scripts/json_resolve_scripts/json_resolve_file.sh"

json_resolver_test() {
    PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
    echo "Project Root: $PROJECT_ROOT"
    export PROJECT_ROOT
    TARGET_BOARD="qemu_riscv64_virt_board"
    BUILD_PROFILE="rootfsOnlyBuild"
    export TARGET_BOARD BUILD_PROFILE

    rebuild_target_str=$($jSON_RESOLVER "$JSON_CFG" "build.rebuild_target_str")
    echo "rebuild_target_str: $rebuild_target_str" >&2

    local docker_wrapper
    docker_wrapper=$($jSON_RESOLVER "$JSON_CFG" "environment.DOCKER_WRAPPER" -d)
    echo -e "docker_wrapper: $docker_wrapper" >&2
}

build_all_boards(){
    ./build.sh -b qemu_riscv64_virt_board -p customBuild -t all
    ./build.sh -b qemu_aarch64_virt_board -p customBuild -t all
}

main() {
    #echo "main called with args: $*"
    json_resolver_test

    build_all_boards
}

main "$@"

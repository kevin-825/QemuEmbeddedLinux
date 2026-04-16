#!/bin/bash

# Source your existing exception handling core
source ./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh
PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
export PROJECT_ROOT
# --- Configuration & Defaults ---
JSON_CFG="./env.json"
jSON_RESOLVER="./scripts/json_resolve_scripts/resolver.sh"
jSON_FILE_RESOLVER="./scripts/json_resolve_scripts/json_resolve_file.sh"

TARGET_BOARD="qemu_riscv64_virt_board"
BUILD_PROFILE="customBuild"
export TARGET_BOARD BUILD_PROFILE PROJECT_ROOT

declare -A test_build=(
    ["0"]="./build.sh -b qemu_riscv64_virt_board -p customBuild -t all"
    ["1"]="./build.sh -b qemu_aarch64_virt_board -p customBuild -t all"
)

json_resolver_test() {
    
    build_target_str=$($jSON_RESOLVER "$JSON_CFG" "build.build_target_str")
    echo "build_target_str: $build_target_str" >&2

    local docker_wrapper
    docker_wrapper=$($jSON_RESOLVER "$JSON_CFG" "environment.DOCKER_WRAPPER" -d)
    echo -e "docker_wrapper: $docker_wrapper" >&2
}

build_all_boards(){

    ${test_build["0"]}
    ${test_build["1"]}
    
    
}

main() {
    #echo "main called with args: $*"
    local build_index=$1
    echo "build_index: $build_index" >&2
    

    if [[ -n $build_index ]]; then
        if [[ $build_index -ge 0 && $build_index -le 1 ]]; then
            echo "building ${test_build[$build_index]}" >&2
            eval "${test_build[$build_index]}"
        else 
            echo "Invalid build_index: $build_index" >&2
        fi
    else
        json_resolver_test
        build_all_boards
    fi
}

main "$@"

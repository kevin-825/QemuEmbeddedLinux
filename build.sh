#!/bin/bash

PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
echo "Project Root: $PROJECT_ROOT"
export PROJECT_ROOT
cd $PROJECT_ROOT
# Source your existing exception handling core
source $PROJECT_ROOT/scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh

# --- Configuration & Defaults ---
JSON_CFG="$PROJECT_ROOT/build_env.json"
jSON_RESOLVER="$PROJECT_ROOT/scripts/json_resolve_scripts/resolver.sh"
DRY_RUN=false
RUN_QEMU=false

# --- Module: Profile Execution ---
# @description: Iterates through the build_cmds array within the selected build_profile.
run_build_profile() {
    local target="$1"
    local profile="$2"

    echo ">>> [INFO] Initiating Build Profile: $profile for Target: $target"
    
    # Use mapfile/readarray to fetch the command array from the resolver
    # We assume resolver.sh handles the .join() logic and returns newline-separated commands
    build_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.${profile}.build_cmds[]" -d)

    if [[ ${#build_cmds[@]} -eq 0 ]]; then
        echo ">>> [ERROR] No build_cmds found for profile: $profile"
        exit 1
    fi
    echo -e ">>> [INFO] Full Buildroot command:\n $build_cmds " | sed -r 's/[[:space:]]{4,}/    \n  /g'

    for cmd in "${build_cmds[@]}"; do
        if [[ "$DRY_RUN" = true ]]; then
            echo ">>> [DRY RUN] Command: $cmd"
        else
            echo ">>> [EXEC] $cmd"
            eval "$cmd"
            
            # Error handling per command
            if [[ $? -ne 0 ]]; then
                echo ">>> [ERROR] Build step failed. Terminating."
                exit 1
            fi
        fi
    done
}

# --- Module: QEMU Runner ---
run_qemu_logic() {
    local profile="$1"
    
    if [[ "$RUN_QEMU" == true ]]; then
        local qemu_cmd
        qemu_cmd=$($jSON_RESOLVER "$JSON_CFG" "build.${profile}.qemu_run_cmd")

        if [[ -n "$qemu_cmd" && "$qemu_cmd" != "null" ]]; then
            echo ">>> [INFO] Launching QEMU..."
            eval "$qemu_cmd"
        else
            echo ">>> [WARN] -r flag provided, but qemu_run_cmd is missing in $profile."
        fi
    fi
}

# --- Argument Parsing ---
parse_args() {

    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--target)  TARGET_BOARD="$2"; shift 2 ;;
            -p|--build-profile) BUILD_PROFILE="$2"; shift 2 ;; 
            -d|--dry-run) DRY_RUN=true; shift ;;
            -r|--run-qemu) RUN_QEMU=true; shift ;;
            *) echo "Error: Unknown option '$1'"; usage; exit 1 ;;
        esac
    done
}

# --- Module: Dynamic Help ---
# @description: Queries JSON to list available targets and profiles
usage() {
    echo "Usage: $0 -t <target_board> -p <build_profile> [-d] [-r]"
    echo ""
    echo "Available Targets (-t):"
    # Query keys under the 'targets' object
    jq -r '.targets | keys | .[]' "$JSON_CFG" | sed 's/^/  - /'
    
    echo ""
    echo "Available Build Profiles (-p):"
    # Query keys under the 'build' object, excluding 'base_options'
    jq -r '.build | keys | .[] | select(. != "base_options")' "$JSON_CFG" | sed 's/^/  - /'
    echo ""
    exit 1
}

main() {
    # Defaults
    TARGET_BOARD="qemu_riscv64_virt_board"
    BUILD_PROFILE="rootfsOnlyBuild"
    parse_args "$@"
    export TARGET_BOARD BUILD_PROFILE
    export ARCH_NAME=$($jSON_RESOLVER "$JSON_CFG" "targets.${TARGET_BOARD}.ARCH_NAME")
    echo "Selected Target: $TARGET_BOARD, Build Profile: $BUILD_PROFILE, ARCH_NAME: $ARCH_NAME"

    run_build_profile "$TARGET_BOARD" "$BUILD_PROFILE"

    run_qemu_logic "$BUILD_PROFILE"
    
    echo ">>> [SUCCESS] Pipeline for $TARGET_BOARD using $BUILD_PROFILE finished."
    OUT_DIR=$($jSON_RESOLVER "$JSON_CFG" "environment.OUTPUT_BASE_DIR")"/$TARGET_BOARD/$BUILD_PROFILE"
    mkdir -p "$OUT_DIR/images/extracted_rootfs"
    tar -xf $OUT_DIR/images/rootfs.tar -C $OUT_DIR/images/extracted_rootfs
}

main "$@"
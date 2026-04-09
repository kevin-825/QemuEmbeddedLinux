#!/bin/bash

PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
# Source your existing exception handling core
source $PROJECT_ROOT/scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh
# --- Configuration & Defaults ---
JSON_CFG="$PROJECT_ROOT/env.json"
jSON_RESOLVER="$PROJECT_ROOT/scripts/json_resolve_scripts/resolver.sh"

TARGET_BOARD="qemu_riscv64_virt_board"
BUILD_PROFILE="rootfsOnlyBuild"
BUILD_TARGETS=() # Initialize as an array to hold multiple build targets if needed
BUILD_KERNEL=false
DRY_RUN=false
RUN_QEMU=false
RUN_QEMU_ONLY=false
declare -a QEMU_ARGS=() # Initialize as an array to preserve spaces

init(){
    echo "init"

}
setup_environment() {
    echo "--- Setting up Shell Environment ---"
    export BUILD_PROFILE TARGET_BOARD PROJECT_ROOT BUILD_TARGETS_BR2="${BUILD_TARGETS[@]}"
    echo "Project Root: $PROJECT_ROOT"
    # 1. Export variables from the global environment section
    # Note: Using 'env' as a temp variable to avoid conflicts
    if [[ -z "$TARGET_BR2_DEFCONFIG" ]]; then
        TARGET_BR2_DEFCONFIG=$($jSON_RESOLVER "$JSON_CFG" "targets.${TARGET_BOARD}.BR_DEFCONFIG")
    fi

    export TARGET_BR2_DEFCONFIG

    # 2. Export the env_exports array from the build scope
    # We read the array and loop through it to export each string
    while IFS= read -r line; do
        # Evaluate variables inside the string (e.g., ${PROJECT_ROOT})
        echo "line: $line"
        eval "export $line"
        echo "Exported: $line"
    done < <($jSON_RESOLVER "$JSON_CFG" "build.env_exports[]")

    while IFS= read -r line; do
        # Evaluate variables inside the string (e.g., ${PROJECT_ROOT})
        echo "line: $line"
        eval "export $line"
        echo "Exported: $line"
    done < <($jSON_RESOLVER "$JSON_CFG" "build.profiles.${BUILD_PROFILE}.profile_env_exports[]")

    echo -e "Selected Target: $TARGET_BOARD\n \
        Build Profile: $BUILD_PROFILE\n \
        TARGET_BR2_DEFCONFIG: $TARGET_BR2_DEFCONFIG \n \
        PRE_BUILT_KERNEL_IMAGE: $PRE_BUILT_KERNEL_IMAGE \n"
}


# --- Module: Profile Execution ---
# @description: Iterates through the build_cmds array within the selected build_profile.
run_cmds() {
    local cmd_name="$1"
    shift # Removes $1. Now $@ contains ONLY the commands.
    local cmds=("$@") 

    for cmd in "${cmds[@]}"; do
        # Use a local check, allowing DRY_RUN to be passed safely via the environment
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            echo ">>> [DRY RUN] [$cmd_name] Command: $cmd"
        else
            echo ">>> [EXEC] [$cmd_name] $cmd"
            eval "$cmd"
            
            # Error handling per command
            if [[ $? -ne 0 ]]; then
                echo ">>> [ERROR] [$cmd_name] Build step failed on: $cmd"
                return 1 
            fi
        fi
    done
}

# How to call it:
# build_cmds=("npm install" "npm run build")
# run_cmds "${build_cmds[@]}"
run_build_profile() {
    local target="$1"
    local profile="$2"

    local pre_cmds
    local build_cmds
    local post_cmds
    # Only run the build steps if -ro was NOT passed
    if [[ "$RUN_QEMU_ONLY" == true ]]; then
        echo ">>> [INFO] Skipping build phase (--run-qemu-only requested)."
        return 0
    fi
    pre_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.profiles.${profile}.pre_cmds[]")
    build_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.profiles.${profile}.build_cmds[]")
    post_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.profiles.${profile}.post_cmds[]")

    run_cmds "pre_cmds" "${pre_cmds[@]}"
    if [[ "$BUILD_KERNEL" == true ]]; then
        kernel_build_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.profiles.${profile}.kernel_build_cmds[]")
        run_cmds "kernel_build_cmds" "${kernel_build_cmds[@]}"
    fi
    if [[ ${#build_cmds[@]} -eq 0 ]]; then
        echo ">>> [ERROR] No build_cmds found for profile: $profile"
        exit 1
    fi
    echo ">>> [INFO] Initiating Build Profile: $profile for Target: $target"
    echo -e ">>> [INFO] Full Buildroot command:\n $build_cmds " | sed -r 's/[[:space:]]{4,}/    \n  /g'
    run_cmds "build_cmds" "${build_cmds[@]}"


    run_cmds "post_cmds" "${post_cmds[@]}"
    
}

# --- Module: QEMU Runner ---
run_qemu_logic() {
    local profile="$1"
    echo ">>> [INFO] Checking if QEMU run is requested for profile: $profile"
    if [[ "$RUN_QEMU" == true ]]; then
        local qemu_cmd
        local qemu_pre_cmds
        qemu_pre_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.profiles.${profile}.qemu_pre_cmds[]")
        qemu_cmd=$($jSON_RESOLVER "$JSON_CFG" "build.profiles.${profile}.qemu_run_cmd")
        qemu_post_cmds=$($jSON_RESOLVER "$JSON_CFG" "build.profiles.${profile}.qemu_post_cmds[]")
        run_cmds "qemu_pre_cmds" "${qemu_pre_cmds[@]}"
        
        echo -e "qemu_cmd: $qemu_cmd" >&2

        if [[ -n "$qemu_cmd" && "$qemu_cmd" != "null" ]]; then
            echo ">>> [INFO] Launching QEMU..."
            eval "$qemu_cmd ${QEMU_ARGS[*]}"
            if [[ $? -ne 0 ]]; then
                echo ">>> [ERROR] QEMU execution failed."
                exit 1
            fi
            run_cmds "qemu_post_cmds" "${qemu_post_cmds[@]}"
        else
            echo ">>> [WARN] -r flag provided, but qemu_run_cmd is missing in $profile."
        fi
    else
        echo ">>> [INFO] QEMU run not requested. Skipping QEMU execution."
    fi
}

# --- Argument Parsing ---
parse_args() {

    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--target-board)  TARGET_BOARD="$2"; shift 2 ;;
            -p|--build-profile) BUILD_PROFILE="$2"; shift 2 ;; 
            -def|--defconfig) TARGET_BR2_DEFCONFIG="$2"; shift 2 ;;
            -t|--build-target)
                if [[ -n "$2" && ! "$2" == -* ]]; then
                    BUILD_TARGETS+=("$2")
                    shift 2
                else
                    shift 1
                fi
                ;;
            -d|--dry-run) DRY_RUN=true; shift ;;
            -r|--run-qemu) 
                RUN_QEMU=true
                shift
                QEMU_ARGS=("$@") # Capture all remaining arguments into an array
                break            # Stop parsing so build.sh doesn't crash on QEMU flags
                ;;
            -ro|--run-qemu-only) 
                RUN_QEMU_ONLY=true
                RUN_QEMU=true      # We still need the QEMU logic to trigger
                shift
                QEMU_ARGS=("$@")
                break
                ;;
            -k|--build-kernel) 
                BUILD_KERNEL=true
                shift
                ;;
            *) echo "Error: Unknown option '$1'"; usage; exit 1 ;;
        esac
    done
}

# --- Module: Dynamic Help ---
# @description: Queries JSON to list available targets, profiles, and documents script flags.
usage() {
    echo "Usage: $(basename "$0") -b <target_board> -p <build_profile> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -b,  --target-board <board>     Set the target board (Required)"
    echo "  -p,  --build-profile <profile>  Set the build profile (Required)"
    echo "  -def,--defconfig <config>       Override the default BR2_DEFCONFIG"
    echo "  -d,  --dry-run                  Enable dry run (print commands without executing)"
    echo "  -r,  --run-qemu                 Run in QEMU after building."
    echo "                                  * Must be the LAST script option."
    echo "                                  * All subsequent arguments are passed directly to QEMU."
    echo "  -ro, --run-qemu-only            Skip the build phase and ONLY run QEMU."
    echo "                                  * Must be the LAST script option."
    echo "                                  * All subsequent arguments are passed directly to QEMU."
    echo "  -h,  --help                     Show this help message and exit."
    echo ""
    echo "Available Targets (-b):"
    # Query keys under the 'targets' object
    jq -r '.targets | keys | .[]' "$JSON_CFG" | sed 's/^/   - /'
    
    echo ""
    echo "Available Build Profiles (-p):"
    # Query keys under the 'build' object, excluding 'base_options'
    jq -r '.build.profiles | keys | .[] | select(. != "base_options")' "$JSON_CFG" | sed 's/^/   - /'
    echo ""
    
    # Exit cleanly if help was requested, otherwise exit with error status
    if [[ "${1:-}" == "help" ]]; then
        exit 0
    else
        exit 1
    fi
}

main() {
    # Defaults
    init
    parse_args "$@"
    setup_environment


    ./scripts/generate_local_mk.sh "$JSON_CFG" "$BUILD_PROFILE"

    run_build_profile "$TARGET_BOARD" "$BUILD_PROFILE"

    run_qemu_logic "$BUILD_PROFILE"
    
    echo ">>> [SUCCESS] Pipeline for $TARGET_BOARD using $BUILD_PROFILE finished."
    OUT_DIR=$($jSON_RESOLVER "$JSON_CFG" "environment.OUTPUT_BASE_DIR")"/$TARGET_BOARD/$BUILD_PROFILE"
    mkdir -p "$OUT_DIR/images/extracted_rootfs"
    tar -xf $OUT_DIR/images/rootfs.tar -C $OUT_DIR/images/extracted_rootfs
}

main "$@"
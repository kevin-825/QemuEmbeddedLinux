#!/bin/bash
# ==============================================================================
# MODULE: config_mgr.sh
# DESCRIPTION: Sequential Buildroot Config Manager via Docker
# ==============================================================================
source "./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh"
# --- Global Variables ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)
export PROJECT_ROOT="${SCRIPT_DIR}"

JSON_CFG="$PROJECT_ROOT/env.json"
JSON_RESOLVER="$PROJECT_ROOT/scripts/json_resolve_scripts/resolver.sh"

# Global paths
BUILDROOT_DIR=""
EXTERNAL_DIR=""
OUTPUT_DIR=""
BR_CMD=""

# Execution Flags
DO_CLEAN=false
DO_LOAD=false
DO_MENUCONFIG=false
DO_SAVE_CONFIG=false
LOAD_TARGET=""
SAVE_TARGET=""
TARGET_BOARD=""
BUILD_PROFILE="rootfsOnlyBuild"
# --- Module: Initialization ---
init_globals() {
    export TARGET_BOARD="$TARGET_BOARD"  # Export for use in config save/load
    export BUILD_PROFILE="$BUILD_PROFILE"
    if [[ ! -f "$JSON_RESOLVER" ]]; then
        echo ">>> [ERROR] Resolver not found at: $JSON_RESOLVER"
        exit 1
    fi

    BUILDROOT_DIR=$($JSON_RESOLVER "$JSON_CFG" "environment.BUILDROOT_DIR")
    EXTERNAL_DIR=$($JSON_RESOLVER "$JSON_CFG" "environment.EXTERNAL_DIR")
    OUTPUT_DIR=$($JSON_RESOLVER "$JSON_CFG" "environment.OUTPUT_BASE_DIR")"/config_manager/${LOAD_TARGET}"
    
    DOCKER_WRAPPER=$("$JSON_RESOLVER" "$JSON_CFG" "environment.DOCKER_WRAPPER")
    echo "DOCKER_WRAPPER: $DOCKER_WRAPPER"
    # Prevent 'null' string execution if the key is missing in json
    [[ "$DOCKER_WRAPPER" == "null" ]] && DOCKER_WRAPPER=""
    #if [[ "$DOCKER_WRAPPER" != *"-it"* ]]; then
    #    DOCKER_WRAPPER="${DOCKER_WRAPPER/run /run -it }"
    #fi

    BR_CMD="$DOCKER_WRAPPER make -C $BUILDROOT_DIR O=$OUTPUT_DIR BR2_EXTERNAL=$EXTERNAL_DIR"
   
    echo "BuildRoot Command: $BR_CMD"
    mkdir -p "$OUTPUT_DIR"
}

# --- Module: Core Functions ---
defconfig_clean() {
    echo ">>> [CLEAN] Wiping output directory: $OUTPUT_DIR"
    rm -rf "$OUTPUT_DIR"/*
}

defconfig_load() {
    local cfg="$1"
    if [[ -z "$cfg" ]]; then
        echo ">>> [ERROR] No config specified for loading."
        exit 1
    fi
    echo ">>> [LOAD] Loading $cfg..."
    eval "$BR_CMD $cfg"
}

defconfig_menuconfig() {
    echo ">>> [EDIT] Launching menuconfig..."
    eval "$BR_CMD menuconfig"
}

defconfig_save() {
    local dest_name="$1"
    
    if [[ -z "$dest_name" ]]; then
        if [[ -f "$OUTPUT_DIR/.config" ]]; then
            dest_name=$(grep "^BR2_DEFCONFIG=" "$OUTPUT_DIR/.config" | cut -d '=' -f 2 | tr -d '"' | xargs basename)
        fi
    fi

    if [[ -z "$dest_name" ]]; then
        echo ">>> [ERROR] Could not auto-detect active config. Specify a name."
        exit 1
    fi

    [[ "$dest_name" != *"_defconfig" ]] && dest_name="${dest_name}_defconfig"
    local save_path="$EXTERNAL_DIR/configs/$dest_name"
    
    echo ">>> [SAVE] Saving minimal defconfig to $save_path..."
    eval "$BR_CMD savedefconfig BR2_DEFCONFIG=\"$save_path\""
}

show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo "Options can be chained (e.g., -l my_defconfig -m -s)"
    echo "  -b | --board <name>                  Specify target board (e.g., rpi4)"
    echo "  -p | --profile <name>                Specify build profile (default: rootfsOnlyBuild)"
    echo "  -c | --clean                          Wipe output directory"
    echo "  -l | -ld | -load | --load <name>            Load a defconfig"
    echo "  -m | -edit | --menuconfig             Open menuconfig"
    echo "  -s | -save | --save [name]            Save config (name optional)"
    echo "  -h | --help                           Show this help message"
    echo ""
    echo "Available boards (-b):"
    local boards=()
    for line in $(jq -r '.boards | keys | .[]' "$JSON_CFG"); do
        boards+=("$line")
    done
    # Query keys under the 'boards' object
    jq -r '.boards | keys | .[]' "$JSON_CFG" | sed 's/^/   - /'
    
    echo ""
    echo "Available Build Profiles (-p):"
    # Query keys under the 'build' object, excluding 'base_options'
    local profiles=()
    for line in $(jq -r '.build.profiles | keys | .[] | select(. != "base_options")' "$JSON_CFG"); do
        profiles+=("$line")
    done
    jq -r '.build.profiles | keys | .[] | select(. != "base_options")' "$JSON_CFG" | sed 's/^/   - /'
    echo ""
    echo "Example Usage:"
    for board in "${boards[@]}"; do
        for profile in "${profiles[@]}"; do
            echo "  ./$(basename "$0") -b $board -p $profile -c -m -s -l my_defconfig"
        done
        echo ""
    done

    exit 0
}

# --- Module: Argument Parsing ---
parse_args() {
    if [[ $# -eq 0 ]]; then
        show_help
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b|--board)                 TARGET_BOARD="$2"; shift 2 ;;
            -p|--profile)               BUILD_PROFILE="$2"; shift 2 ;;
            -c|--clean)
                DO_CLEAN=true
                shift
                ;;
            -l|-ld|-load|--load)
                DO_LOAD=true
                LOAD_TARGET="$2"
                LOAD_TARGET=${LOAD_TARGET#external/configs/}  # Remove path if provided
                shift 2
                ;;
            -m|-e|-edit|--menuconfig)
                DO_MENUCONFIG=true
                shift
                ;;
            -s|-save|--save)
                DO_SAVE_CONFIG=true
                # Check if next argument exists and is not another flag
                if [[ -n "$2" && "$2" != -* ]]; then
                    SAVE_TARGET="$2"
                    shift 2
                else
                    shift 1
                fi
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo ">>> [ERROR] Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# --- Main Execution ---
main() {
    parse_args "$@"
    init_globals

    # Execute sequentially based on flags
    if [[ "$DO_CLEAN" == true ]]; then
        defconfig_clean
    fi

    if [[ "$DO_LOAD" == true ]]; then
        defconfig_load "$LOAD_TARGET"
    fi

    if [[ "$DO_MENUCONFIG" == true ]]; then
        defconfig_menuconfig
    fi

    if [[ "$DO_SAVE_CONFIG" == true ]]; then
        defconfig_save "$SAVE_TARGET"
    fi
    
    echo "--> Configuration operations complete."
}

main "$@"

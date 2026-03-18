#!/bin/bash
# ==============================================================================
# MODULE: kbuild_wrapper.sh
# DESCRIPTION: Out-of-tree kernel build wrapper with JSON config integration
# ==============================================================================
source "./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh"

# --- Global Variables ---
#KERNEL_SRC="$HOME/d2/OffRepos/linux"
KERNEL_SRC="/mnt/wsl/ramdisk5/linux"
RELEASE_BUILD=false

OUTPUT_DIR=""
KBUILD_OUT_DIR=""
ARCH=""
CROSS_COMPILE=""
MODE="build"
TARGET_DEFCONFIG=""
TARGET_BOARD=""
BUILD_PROFILE=""
SAVE_AS=""
DOCKER_WRAPPER=""  # <--- ADDED THIS

# --- JSON Configuration ---
JSON_RESOLVER="./scripts/json_resolve_scripts/resolver.sh"
JSON_CFG="./env.json"
AUTO_BACKUP_DIR="${HOME}/kbuild_backups"
# --- Actions ---
DO_MENUCONFIG=false
DO_SAVE_CONFIG=false
DO_CLEAN=false

# --- 1. Global Setup ---
get_global_vars() {
    export TARGET_BOARD="$TARGET_BOARD"  # Export for use in config save/load
    PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
    echo "Project Root: $PROJECT_ROOT"
    export PROJECT_ROOT

    if [[ -x "$JSON_RESOLVER" && -f "$JSON_CFG" ]]; then
        local resolved_dir
        resolved_dir=$("$JSON_RESOLVER" "$JSON_CFG" "environment.OUTPUT_BASE_DIR")
        
        if [[ -z "$OUTPUT_DIR" && -n "$resolved_dir" ]]; then
            OUTPUT_DIR="${resolved_dir}/${TARGET_BOARD:-default_board}"
        fi

        DOCKER_WRAPPER=$("$JSON_RESOLVER" "$JSON_CFG" "environment.DOCKER_WRAPPER")
        # Prevent 'null' string execution if the key is missing in json
        [[ "$DOCKER_WRAPPER" == "null" ]] && DOCKER_WRAPPER=""

        local available_boards
        available_boards=$("$JSON_RESOLVER" "$JSON_CFG" "targets | keys")
        
        if [[ -n "$available_boards" && -n "$TARGET_BOARD" ]]; then
            if echo "$available_boards" | grep -q "$TARGET_BOARD"; then
                # Only overwrite ARCH/CROSS_COMPILE if not provided by CLI
                [[ -z "$ARCH" ]] && ARCH=$("$JSON_RESOLVER" "$JSON_CFG" "targets.${TARGET_BOARD}.ARCH")
                [[ -z "$CROSS_COMPILE" ]] && CROSS_COMPILE=$("$JSON_RESOLVER" "$JSON_CFG" "targets.${TARGET_BOARD}.HOST_TOOLCHAIN_PREFIX")-
                
                # Auto-fetch defconfig if not explicitly overridden by CLI
                if [[ -z "$TARGET_DEFCONFIG" ]]; then
                    TARGET_DEFCONFIG=$("$JSON_RESOLVER" "$JSON_CFG" "targets.${TARGET_BOARD}.KERNEL_DEFCONFIG")
                fi
                echo "--> Loaded from env.json: Board='$TARGET_BOARD' Arch='$ARCH' Defconfig='$TARGET_DEFCONFIG'"
            else
                echo "Error: TARGET_BOARD '$TARGET_BOARD' not found in env.json."
                exit 1
            fi
        fi
        
    fi

    if [[ -f "$TARGET_DEFCONFIG" ]]; then
        basename_defconfig=$(basename "$TARGET_DEFCONFIG")
        KBUILD_OUT_DIR="${OUTPUT_DIR}/kernel/${basename_defconfig}"
    else
        # If it's not a file path, assume it's a built-in kernel target (e.g., multi_v7_defconfig)
        KBUILD_OUT_DIR="${OUTPUT_DIR}/kernel/${TARGET_DEFCONFIG:-default_defconfig}"
    fi
}

# --- 2. Helper Functions ---
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -b, --board <name>           Target board (fetches architecture and defconfig from env.json)"
    echo "  -p, --profile <name>         Build profile (defined in env.json, for example "rootfsOnlyBuild")"
    echo "  -d, --defconfig <name>       Explicitly set the target defconfig (Required if no board is set)"
    echo "  -a, --arch <arch>            Override/Set Architecture manually"
    echo "  -cc, --cross-toolchain <pre> Override/Set Cross-compiler prefix manually"
    echo "  -o, --output <dir>           Output build directory (overrides env.json)"
    echo "  -r, --release-build          Optimized release build"
    echo "  -c, --clean                  Wipe the active .config to force a fresh defconfig load"
    echo "  -m, -edit, --menuconfig      Open kernel configuration menu"
    echo "  -s, -save, --savedefconfig [name] Save config to a minimal defconfig (optional name)"
    echo "  -ld, -load, --load-config <name>  Load a specific defconfig and enter config mode"
    echo "  -h, --help                   Show this menu"
}

# --- 3. Core Engine ---
kmake() {
    local cmd=($DOCKER_WRAPPER make -C "$KERNEL_SRC" O="$KBUILD_OUT_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" V=1)
    echo "[exec] ${cmd[*]} $*"
    "${cmd[@]}" "$@"
}

# --- 4. Configuration Management Modules ---
# --- 4. Configuration Management Modules ---
kernel_config_load() {
    echo "--> Forcing deterministic configuration: $TARGET_DEFCONFIG"
    
    # Check if TARGET_DEFCONFIG is an actual file path on your PC
    if [[ -f "$TARGET_DEFCONFIG" ]]; then
        echo "--> External config detected. Copying to build directory..."
        cp "$TARGET_DEFCONFIG" "${KBUILD_OUT_DIR}/.config"
        
        # Expand it into a full config silently
        kmake olddefconfig
    else
        # If it's not a file path, assume it's a built-in kernel target (e.g., multi_v7_defconfig)
        echo "--> Using built-in Internal kernel config: $TARGET_DEFCONFIG "
        kmake "$TARGET_DEFCONFIG"
    fi
}

kernel_config_edit() {
    echo "--> Opening kernel menuconfig..."
    
    # Only run the backup if menuconfig finishes successfully
    if kmake menuconfig; then
        echo "--> Configuration complete. .config file updated at ${KBUILD_OUT_DIR}/.config"
        
        echo "--> Creating auto-backup of minimal config..."
        kmake savedefconfig
        
        # 1. Ensure the backup directory actually exists
        mkdir -p "$AUTO_BACKUP_DIR"
        # 2. Extract just the filename to prevent slash-injection errors
        local clean_defconfig_name
        clean_defconfig_name=$(basename "$TARGET_DEFCONFIG")
        
        # Generate a unique timestamp (Format: YYYYMMDD_HHMMSS)
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_file="${AUTO_BACKUP_DIR}/auto_${clean_defconfig_name}_${timestamp}"
        
        cp "${KBUILD_OUT_DIR}/defconfig" "$backup_file"
        echo "--> Auto-backup saved to: $backup_file"
    else
        echo "--> Menuconfig aborted. Skipping auto-backup."
    fi
}

kernel_config_save() {
    local external_dir
    external_dir=$("$JSON_RESOLVER" "$JSON_CFG" "environment.EXTERNAL_DIR")
    
    # SAFETY FALLBACK: Prevent writing to root /board/ if JSON fails
    if [[ -z "$external_dir" || "$external_dir" == "null" ]]; then
        echo "Warning: environment.EXTERNAL_DIR not found. Defaulting to output directory."
        external_dir="$OUTPUT_DIR"
    fi

    # SAFETY FALLBACK: If no board is specified, use a default folder
    local safe_board_name="${TARGET_BOARD:-custom_board}"
    local save_path="${external_dir}/board/${safe_board_name}/kernel_configs"

    echo "--> Generating minimal defconfig..."
    kmake savedefconfig

    local save_name
    if [[ -n "$SAVE_AS" ]]; then
        save_name="${save_path}/${SAVE_AS}"
    else
        if [[ -f "$TARGET_DEFCONFIG" ]]; then
            save_name="${save_path}/$(basename "$TARGET_DEFCONFIG")"
        else
            save_name="${save_path}/${TARGET_DEFCONFIG}"
        fi
    fi
    
    echo "--> Saving deterministic config to $save_name"
    mkdir -p "$save_path"
    cp "${KBUILD_OUT_DIR}/defconfig" "$save_name"
}

config_kernel() {
    # Always anchor the config session with the deterministic defconfig first
    kernel_config_load

    if [[ "$DO_MENUCONFIG" == true ]]; then
        kernel_config_edit
    fi

    if [[ "$DO_SAVE_CONFIG" == true ]]; then
        kernel_config_save "$path"
    fi
    
    echo "--> Configuration operations complete."
}

# --- 5. Build Modules ---
build_release() {
    echo "--> Starting RELEASE build for $ARCH using base: $TARGET_DEFCONFIG..."
    if [[ ! -f "$KBUILD_OUT_DIR/.config" ]]; then
        echo "--> .config missing. Initializing deterministic build with $TARGET_DEFCONFIG..."
        kmake "$TARGET_DEFCONFIG"
    fi
    kmake -j$(nproc)
}

build_debug() {
    echo "--> Starting DEBUG build for $ARCH using base: $TARGET_DEFCONFIG..."
    if [[ ! -f "$KBUILD_OUT_DIR/.config" ]]; then
        echo "--> .config missing. Initializing deterministic build with $TARGET_DEFCONFIG..."
        kmake "$TARGET_DEFCONFIG"
    fi
    KCFLAGS="-g -O1" kmake -j$(nproc)
}

build_kernel() {
    if [[ "$RELEASE_BUILD" == true ]]; then
        build_release
    else
        build_debug
    fi
}

# --- 6. Argument Parsing & Validation ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--board)                 TARGET_BOARD="$2"; shift 2 ;;
            -p|--profile)               BUILD_PROFILE="$2"; shift 2 ;;
            -d|--defconfig)             TARGET_DEFCONFIG="$2"; shift 2 ;;
            -a|--arch)                  ARCH="$2"; shift 2 ;;
            -cc|--cross-toolchain)      CROSS_COMPILE="$2"; shift 2 ;;
            -o|--output)                OUTPUT_DIR="$2"; KBUILD_OUT_DIR="${OUTPUT_DIR}/kernel"; shift 2 ;;
            -r|--release-build)         RELEASE_BUILD=true; shift ;;
            -c|--clean)                 DO_CLEAN=true; shift ;;
            -m|-edit|--menuconfig)      DO_MENUCONFIG=true; MODE="config"; shift ;;
            -ld|-load|--load-config)    
                TARGET_DEFCONFIG="$2"
                MODE="config"
                shift 2 
                ;;
            -s|-save|--savedefconfig)   
                DO_SAVE_CONFIG=true
                MODE="config"
                if [[ -n "$2" && ! "$2" == -* ]]; then
                    SAVE_AS="$2"
                    shift 2
                else
                    shift 1
                fi
                ;;
            -h|--help)                  usage; exit 0 ;;
            *) echo "Error: Unknown option '$1'"; usage; exit 1 ;;
        esac
    done
}

check_args() {
    if [[ -z "$TARGET_DEFCONFIG" ]]; then
        echo "Error: Deterministic build requires a target defconfig."
        echo "Please specify a board (-b <board>) to fetch from env.json, or provide it explicitly (-d <defconfig> or -ld <defconfig>)."
        usage; exit 1
    fi

    if [[ -z "$ARCH" ]]; then
        echo "Error: Architecture not specified. Provide via -b or -a."
        usage; exit 1
    fi
    
    if [[ -z "$CROSS_COMPILE" ]]; then
        echo "Error: Cross-compiler prefix not specified. Provide via -b or -cc."
        usage; exit 1
    fi
    
    if [[ -z "$KBUILD_OUT_DIR" ]]; then
        echo "Error: Output directory not specified (via env.json or CLI)."
        usage; exit 1
    fi
    
    mkdir -p "$KBUILD_OUT_DIR"
    KBUILD_OUT_DIR=$(realpath "$KBUILD_OUT_DIR")
}

# --- 7. Main Execution Flow ---
main() {
    parse_args "$@"

    get_global_vars
    check_args

    # Apply the clean action immediately before routing to build/config
    if [[ "$DO_CLEAN" == true ]]; then
        echo "--> [--clean] Wiping active .config to force a fresh baseline..."
        rm -f "$KBUILD_OUT_DIR/.config"
    fi

    if [[ "$MODE" == "build" ]]; then
        build_kernel
    elif [[ "$MODE" == "config" ]]; then
        config_kernel
    else
        echo "Error: Invalid execution mode."
        usage; exit 1
    fi
}

main "$@"

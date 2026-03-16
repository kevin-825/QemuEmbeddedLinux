#!/bin/bash

# --- Global Variables ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)
export PROJECT_ROOT="$SCRIPT_DIR"
JSON_CFG="$PROJECT_ROOT/build_env.json"
jSON_RESOLVER="$PROJECT_ROOT/scripts/json_resolve_scripts/resolver.sh"

# Global paths populated by init_globals
BUILDROOT_DIR=""
EXTERNAL_DIR=""
OUTPUT_DIR=""
DOCKER_CMD=""

# --- Module: Argument Parsing ---
show_help() {
    echo "Usage: $(basename "$0") <command> [config_name]"
    echo ""
    echo "Commands:"
    echo "  load <name>      Load a defconfig from external/configs/ into the build environment"
    echo "  edit             Open 'make menuconfig' in the Docker container"
    echo "  save             Save current .config back to the currently active defconfig"
    echo "  save-as <name>   Save current .config as a NEW defconfig in external/configs/"
    echo "  list             List all available configs in the external tree"
}

parse_args() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi

    COMMAND="$1"
    TARGET_CONFIG="$2"
}

# --- Module: Initialization ---
init_globals() {
    BUILDROOT_DIR=$($jSON_RESOLVER "$JSON_CFG" "environment.BUILDROOT_DIR")
    EXTERNAL_DIR=$($jSON_RESOLVER "$JSON_CFG" "environment.EXTERNAL_DIR")
    # Using a generic config-management output folder to avoid clashing with profile builds
    OUTPUT_DIR=$($jSON_RESOLVER "$JSON_CFG" "environment.OUTPUT_BASE_DIR")"/config_manager"
    
    # We need an interactive Docker wrapper for menuconfig (adding -it)
    # Fetch the raw wrapper and ensure it has interactive flags
    local raw_docker=$($jSON_RESOLVER "$JSON_CFG" "environment.DOCKER_WRAPPER")
    if [[ "$raw_docker" != *"-it"* ]]; then
        DOCKER_CMD="${raw_docker/run --rm/run --rm -it}"
    else
        DOCKER_CMD="$raw_docker"
    fi

    mkdir -p "$OUTPUT_DIR"

    echo "Initialized global paths:"
    echo "  BUILDROOT_DIR: $BUILDROOT_DIR"
    echo "  EXTERNAL_DIR: $EXTERNAL_DIR"
    echo "  OUTPUT_DIR: $OUTPUT_DIR"
    echo "  DOCKER_CMD: $DOCKER_CMD"
    echo ""

}

# --- Module: Commands ---

list_configs() {
    echo ">>> Available defconfigs in $EXTERNAL_DIR/configs/:"
    ls -1 "$EXTERNAL_DIR/configs/" | grep "_defconfig$" | sed 's/^/  - /'
}

load_config() {
    if [[ -z "$TARGET_CONFIG" ]]; then
        echo ">>> [ERROR] Please specify a config name (e.g., my_qemu_riscv64_virt_defconfig)"
        exit 1
    fi

    local config_path="$EXTERNAL_DIR/configs/$TARGET_CONFIG"
    if [[ ! -f "$config_path" ]]; then
        echo ">>> [ERROR] Config not found: $config_path"
        exit 1
    fi

    echo ">>> [CONFIG] Loading $TARGET_CONFIG..."
    # We pass ONLY the filename so Buildroot's %_defconfig rule works via BR2_EXTERNAL
    eval $DOCKER_CMD make -C "$BUILDROOT_DIR" O="$OUTPUT_DIR" BR2_EXTERNAL="$EXTERNAL_DIR" "$TARGET_CONFIG"
    echo ">>> [SUCCESS] Loaded. Ready for 'edit'."
}

edit_config() {
    echo ">>> [CONFIG] Launching menuconfig..."
    eval $DOCKER_CMD make -C "$BUILDROOT_DIR" O="$OUTPUT_DIR" BR2_EXTERNAL="$EXTERNAL_DIR" menuconfig
}

save_config() {
    # If a name is provided, use it (save-as). Otherwise, try to extract the active one from .config
    local dest_name="$TARGET_CONFIG"
    
    if [[ -z "$dest_name" ]]; then
        # Read the current BR2_DEFCONFIG from the hidden .config file
        echo ">>> [INFO] No config name provided. Attempting to auto-detect active defconfig from .config..."
        local current_defconfig=$(grep "^BR2_DEFCONFIG=" "$OUTPUT_DIR/.config" | cut -d '=' -f 2 | tr -d '"')
        if [[ -z "$current_defconfig" ]]; then
            echo ">>> [ERROR] Could not determine active defconfig. Use 'save-as <name>' instead."
            exit 1
        fi
        dest_name=$(basename "$current_defconfig")
    fi

    # Ensure it has the _defconfig suffix
    if [[ "$dest_name" != *"_defconfig" ]]; then
        dest_name="${dest_name}_defconfig"
    fi

    local save_path="$EXTERNAL_DIR/configs/$dest_name"
    
    echo ">>> [CONFIG] Saving minimal defconfig to $save_path..."
    # Force the savedefconfig target to write to our specific path
    eval $DOCKER_CMD make -C "$BUILDROOT_DIR" O="$OUTPUT_DIR" BR2_EXTERNAL="$EXTERNAL_DIR" BR2_DEFCONFIG="$save_path" savedefconfig
    
    echo ">>> [SUCCESS] Saved to $dest_name"
}

# --- Main Execution ---
main() {
    parse_args "$@"
    init_globals

    case "$COMMAND" in
        list)    list_configs ;;
        load)    load_config ;;
        edit)    edit_config ;;
        save)    save_config ;;
        save-as) save_config ;; # Reuses save_config logic
        *)       echo ">>> [ERROR] Unknown command: $COMMAND"; show_help; exit 1 ;;
    esac
}

main "$@"
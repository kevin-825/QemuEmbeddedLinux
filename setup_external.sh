#!/bin/bash
source ./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh
set -e
# --- Global Variables ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)
export PROJECT_ROOT="${SCRIPT_DIR}"
JSON_CFG="$SCRIPT_DIR/env.json"
jSON_RESOLVER="$SCRIPT_DIR/scripts/json_resolve_scripts/resolver.sh"

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        printf "\e[35m[DEBUG]\e[0m %s\n" "$1" >&2
    fi
}

RAW_PROJECT_NAME=$($jSON_RESOLVER "$JSON_CFG" "project_name")
export EXT_NAME=$(echo "$RAW_PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
EXTERNAL_PATH=$($jSON_RESOLVER "$JSON_CFG" "environment.EXTERNAL_DIR")

if [[ -z "$EXTERNAL_PATH" || "$EXTERNAL_PATH" == "null" ]]; then
    echo ">>> [ERROR] Failed to resolve environment.EXTERNAL_DIR. Check JSON and Resolver."
    exit 1
fi
log_debug "SCRIPT_DIR: $SCRIPT_DIR"
log_debug "JSON_CFG: $JSON_CFG"
log_debug "jSON_RESOLVER: $jSON_RESOLVER"
log_debug "RAW_PROJECT_NAME: $RAW_PROJECT_NAME"
log_debug "EXT_NAME: $EXT_NAME"
log_debug "EXTERNAL_PATH: $EXTERNAL_PATH"

EXT_DIR_NAME="external"
EXT_KMOD_DIR_NAME="kernel_modules"
EXT_BOARD_DIR_NAME="board"
EXT_PACKAGE_DIR_NAME="packages"

# --- Module: Board Setup ---
setup_board() {
    local board_name="$1"
    local board_dir="$EXTERNAL_PATH/$EXT_BOARD_DIR_NAME/$board_name"
    
    if [[ -d "$board_dir" ]]; then
        echo ">>> [Info] Board directory already exists: $board_dir"
        exit 1
    fi
    echo ">>> [Info] Creating new board directory: $board_dir"
    
    mkdir -p "$board_dir"/{overlay,kernel_configs}
    touch "$board_dir/"{genimage.cfg,extlinux.conf,run_qemu.sh,post-image.sh}
    chmod +x "$board_dir/run_qemu.sh" "$board_dir/post-image.sh"
}

# --- Module: Kernel Module Setup ---
setup_external_linux_module() {
    if [[ ! -d "$EXTERNAL_PATH/$EXT_KMOD_DIR_NAME" ]]; then
        echo ">>> [Info] Kernel modules directory does not exist. Creating it: $EXTERNAL_PATH/$EXT_KMOD_DIR_NAME"
        mkdir -p "$EXTERNAL_PATH/$EXT_KMOD_DIR_NAME"
    fi
    local path_to_mod_name="$1"
    export mod_name="$(basename "$path_to_mod_name")"
    # 1. Strip the known prefixes (Pure Bash, no subshells)
    local clean_path="${path_to_mod_name#${EXT_DIR_NAME}/}"
    clean_path="${clean_path#${EXT_KMOD_DIR_NAME}/}"
    local full_path_to_mod="$EXTERNAL_PATH/$EXT_KMOD_DIR_NAME/$clean_path"
    export upper="$(echo "$mod_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
    
    if [[ -d "$full_path_to_mod" ]]; then
        echo ">>> [Info] Module directory already exists: $full_path_to_mod"
        exit 1
    fi
    mkdir -p "$full_path_to_mod/src/uapi"

    export relative_path_ext_dir=$(realpath --relative-to="$EXTERNAL_PATH" "$full_path_to_mod")
    local mod_dir="$EXTERNAL_PATH/$relative_path_ext_dir"


    echo ">>> [Info] Setting up new external Linux module: $mod_name"
    log_debug ">>> [Info] Path to module: $path_to_mod_name"
    log_debug ">>> [Info] Module directory: $mod_dir"
    log_debug ">>> [Info] Module name: $mod_name"
    log_debug ">>> [Info] Uppercase module name: $upper"
    log_debug ">>> [Info] Full path to module: $full_path_to_mod"
    log_debug ">>> [Info] Relative path to module (from external dir): $relative_path_ext_dir"

    local allowed_vars='${mod_name} ${upper} ${EXT_NAME} ${relative_path_ext_dir}'
    local template_dir="$SCRIPT_DIR/scripts/templates/ext_kmods"

    # 4. Execute the template substitutions
    envsubst "$allowed_vars" < "$template_dir/Config.in.template"   > "$mod_dir/Config.in"
    envsubst "$allowed_vars" < "$template_dir/packages.mk.template" > "$mod_dir/${mod_name}.mk"
    
    envsubst "$allowed_vars" < "$template_dir/src/Makefile.template" > "$mod_dir/src/Makefile"
    
    envsubst "$allowed_vars" < "$template_dir/src/core.c.template"  > "$mod_dir/src/${mod_name}_core.c"
    envsubst "$allowed_vars" < "$template_dir/src/core.h.template"  > "$mod_dir/src/${mod_name}_core.h"
    
    envsubst "$allowed_vars" < "$template_dir/src/debug.c.template" > "$mod_dir/src/${mod_name}_debug.c"
    envsubst "$allowed_vars" < "$template_dir/src/debug.h.template" > "$mod_dir/src/${mod_name}_debug.h"
    
    envsubst "$allowed_vars" < "$template_dir/src/uapi/uapi.h.template" > "$mod_dir/src/uapi/${mod_name}_uapi.h"

    # 5. Clean up the exported environment variables
    unset mod_name upper relative_path_ext_dir

    echo ">>> [Success] Module $mod_name generated successfully at $mod_dir"

}

# --- Module: Application Package Setup ---
setup_external_package() {
    if [[ ! -d "$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME" ]]; then
        echo ">>> [Info] Packages directory does not exist. Creating it: $EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME"
        mkdir -p "$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME"
    fi

    local path_to_package_name="$1"
    export package_name="$(basename "$path_to_package_name")"
    local clean_path="${path_to_package_name#${EXT_DIR_NAME}/}"
    clean_path="${clean_path#${EXT_PACKAGE_DIR_NAME}/}"
    local package_dir="$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME/$clean_path"
    export upper="$(echo "$package_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
    
    if [[ -d "$package_dir" ]]; then
        echo ">>> [Info] Package directory already exists: $package_dir, exiting to avoid overwriting."
        exit 1
    fi
    mkdir -p "$package_dir/src"
    export relative_path_ext_dir=$(realpath --relative-to="$EXTERNAL_PATH" "$package_dir")
    echo ">>> [Info] Creating the package:${package_name}    at directory: $package_dir"
    local template_dir="$SCRIPT_DIR/scripts/templates/ext_pkgs"
    echo ">>> [Info] Using template directory: $template_dir"
    # We pass the specific variables we want to replace to envsubst 
    # to prevent it from accidentally replacing system environment variables.
    local allowed_vars='${package_name} ${upper} ${EXT_NAME} ${relative_path_ext_dir}'

    envsubst "$allowed_vars" < "$template_dir/Config.in.template" > "$package_dir/Config.in"
    envsubst "$allowed_vars" < "$template_dir/pkg.mk.template"    > "$package_dir/$package_name.mk"
    envsubst "$allowed_vars" < "$template_dir/Makefile.template"  > "$package_dir/src/Makefile"
    envsubst "$allowed_vars" < "$template_dir/main.c.template"    > "$package_dir/src/main.c"
    envsubst "$allowed_vars" < "$template_dir/header.h.template"  > "$package_dir/src/$package_name.h"

    # Clean up the environment variables
    echo ">>> [SUCCESS] Created user-space package: $package_name"
    unset package_name upper current_date relative_path_ext_dir
}

# --- Module: Master Config Generator ---
update_main_external_br2_conf() {
    echo ">>> [Info] Updating main external COnfig.in .mk files with current modules and packages in $EXTERNAL_PATH"
    local ext_config_in_file="$EXTERNAL_PATH/Config.in"
    local ext_desc_file="$EXTERNAL_PATH/external.desc"
    local ext_mk_file="$EXTERNAL_PATH/external.mk"

    # 1. Generate external.desc
    cat <<EOF > "$ext_desc_file"
name: $EXT_NAME
desc: Auto-generated External Tree for $RAW_PROJECT_NAME
EOF

    # 2. Generate external.mk
    cat <<EOF > "$ext_mk_file"
# Auto-generated external external.mk

# Include linux kernel modules
include \$(sort \$(shell find \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/${EXT_KMOD_DIR_NAME} -name "*.mk" 2>/dev/null))

# Include standard packages
include \$(sort \$(shell find \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/${EXT_PACKAGE_DIR_NAME} -name "*.mk" 2>/dev/null))
EOF

    # 3. Generate Config.in dynamically using bash
    cat <<EOF > "$ext_config_in_file"
# Auto-generated Config.in for $EXT_NAME

config BR2_EXTERNAL_KMODE_DEV_ALL
    bool "Build all kernel modules"
    help
      If selected, all kernel modules in the external tree will be built.

config BR2_EXTERNAL_PACKAGE_DEV_ALL
    bool "Build all external app packages"
    help
      If selected, all app packages in the external tree will be built.

menu "External Loadable Kernel Modules"
EOF
    # Safely find and inject module paths
    if [[ -d "$EXTERNAL_PATH/$EXT_KMOD_DIR_NAME" ]]; then
        find "$EXTERNAL_PATH/$EXT_KMOD_DIR_NAME" -name "Config.in" | sort | while read -r f; do
            rel_path=$(realpath --relative-to="$EXTERNAL_PATH" "$f")
            echo "source \"\$BR2_EXTERNAL_${EXT_NAME}_PATH/$rel_path\"" >> "$ext_config_in_file"
        done
    fi
    echo "endmenu" >> "$ext_config_in_file"

    echo "" >> "$ext_config_in_file"
    echo "menu \"External Custom Packages\"" >> "$ext_config_in_file"
    
    # Safely find and inject package paths
    if [[ -d "$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME" ]]; then
        find "$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME" -name "Config.in" | sort | while read -r f; do
            rel_path=$(realpath --relative-to="$EXTERNAL_PATH" "$f")
            echo "source \"\$BR2_EXTERNAL_${EXT_NAME}_PATH/$rel_path\"" >> "$ext_config_in_file"
        done
    fi
    echo "endmenu" >> "$ext_config_in_file"
}

# --- Module: Argument Parsing ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--new-board)
                shift
                setup_board "$1"
                ;;
            -m|--new-kmod)
                shift
                setup_external_linux_module "$1"
                ;;
            -p|--new-package)
                shift
                setup_external_package "$1"
                ;;
            -u|--update-config)
                update_main_external_br2_conf
                exit 0
                ;;
            -h|--help|*)
                echo " help: Display this help message"
                echo " Usage: $0 [-b|--new-board <board_name>] [-m|--new-kmod <path/to/mod>] [-p|--new-package <path/to/package>] [-u|--update-config]"
                exit 0
                ;;
        esac
        shift
    done
}

# --- Main Execution ---
main() {
    if [[ $# -eq 0 ]]; then
        echo ">>> [ERROR] No arguments provided. Please specify at least one of the following options:"
        echo "Usage: $0 [-b|--new-board <board_name>] [-m|--new-kmod <path/to/mod>] [-p|--new-package <path/to/package>] [-u|--update-config]"
        exit 1
    fi
    parse_args "$@"
    update_main_external_br2_conf
}

main "$@"

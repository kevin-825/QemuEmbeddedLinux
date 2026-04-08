#!/bin/bash
source ./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh
# --- Global Variables ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
export PROJECT_ROOT="$SCRIPT_DIR"
JSON_CFG="$PROJECT_ROOT/env.json"
jSON_RESOLVER="$PROJECT_ROOT/scripts/json_resolve_scripts/resolver.sh"

RAW_PROJECT_NAME=""
EXT_NAME=""
EXTERNAL_PATH=""
MODE=""
kmod_dir_name="lkms"

# --- Module: Argument Parsing ---
show_help() {
    echo "Usage: $(basename "$0") <mode>"
    echo ""
    echo "Modes:"
    echo "  init    Initialize the external tree, core files, and example packages."
    echo "  sync    Scan the tree and auto-generate missing Config.in and .mk files for new code."
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message and exit"
    echo ""
    echo "Example of adding a new kernel module:"
    echo "  This is demo of adding a new kernel module named \"my_new_module\" into external/$kmod_dir_name/example_kernel_mod folder:"
    echo "    1. mkdir -p external/$kmod_dir_name/example_kernel_mod/my_new_module/src"
    echo "    2. run $0 sync  #this will generate the .mk and Config.in files for this new module and link it into the kernel extensions menu."
    echo "    3. Add your kernel module code into the src/ directory"
    echo "    4. build your project with Buildroot as usual. The new module will be built and included in the final image based on the generated glue files."
    exit 0
}

parse_args() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi

    case "$1" in
        init) MODE="init" ;;
        sync) MODE="sync" ;;
        clean) MODE="clean" ;;
        -h|--help) show_help; exit 0 ;;
        *)
            echo ">>> [ERROR] Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# --- Module: Initialization ---
init_globals() {
    RAW_PROJECT_NAME=$($jSON_RESOLVER "$JSON_CFG" "project_name")
    EXT_NAME=$(echo "$RAW_PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    EXTERNAL_PATH=$($jSON_RESOLVER "$JSON_CFG" "environment.EXTERNAL_DIR")

    if [[ -z "$EXTERNAL_PATH" || "$EXTERNAL_PATH" == "null" ]]; then
        echo ">>> [ERROR] Failed to resolve environment.EXTERNAL_DIR. Check JSON and Resolver."
        exit 1
    fi
}

# ==========================================
#          INIT MODE FUNCTIONS
# ==========================================

setup_base_directories() {
    echo ">>> [INIT] Creating base directory structure..."
    mkdir -p "$EXTERNAL_PATH/configs"
    mkdir -p "$EXTERNAL_PATH/board"
    mkdir -p "$EXTERNAL_PATH/package/apps"
    mkdir -p "$EXTERNAL_PATH/package/drivers"
    mkdir -p "$EXTERNAL_PATH/$kmod_dir_name"
    mkdir -p "$EXTERNAL_PATH/patches"
}

generate_core_files() {
    echo ">>> [INIT] Generating core br2-external files..."

    cat <<EOF > "$EXTERNAL_PATH/external.desc"
name: $EXT_NAME
desc: Auto-generated External Tree for $RAW_PROJECT_NAME
EOF

    cat <<EOF > "$EXTERNAL_PATH/external.mk"
# Include standard packages (using find for infinite depth)
include \$(sort \$(shell find \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/package -name "*.mk"))

# Include linux kernel extensions (using find for infinite depth)
include \$(sort \$(shell find \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/$kmod_dir_name -name "*.mk"))
EOF

    cat <<EOF > "$EXTERNAL_PATH/Config.in"
menu "External Custom Packages"
source "\$BR2_EXTERNAL_${EXT_NAME}_PATH/package/generated_menu.in"
endmenu
menu "External loadable Kernel Modules"
source "\$BR2_EXTERNAL_${EXT_NAME}_PATH/$kmod_dir_name/generated_ext_menu.in"   
endmenu
EOF

    cat <<EOF > "$EXTERNAL_PATH/$kmod_dir_name/Config.ext.in"
# Kernel extensions menu
source "\$BR2_EXTERNAL_${EXT_NAME}_PATH/$kmod_dir_name/generated_ext_menu.in"
EOF
}

generate_board_configs() {
    echo ">>> [INIT] Generating board configurations..."
    local target_keys=$(jq -r '.targets | keys[]' "$JSON_CFG")

    for target in $target_keys; do
        echo ">>> [INIT] Setting up board configuration for target: $target"
        mkdir -p "$EXTERNAL_PATH/board/$target/overlay"
        mkdir -p "$EXTERNAL_PATH/board/$target/kernel_configs"
        #touch "$EXTERNAL_PATH/board/$target/genimage.cfg"
        #touch  "$EXTERNAL_PATH/board/$target/extlinux.conf"
        #local run_qemu="$EXTERNAL_PATH/board/$target/run_qemu.sh"
        #local post_img="$EXTERNAL_PATH/board/$target/post-image.sh"
    done
}



# ==========================================
#          SYNC MODE FUNCTIONS
# ==========================================

# @description: Scans for missing .mk and Config.in files for standard packages
sync_packages() {
    echo ">>> [SYNC] Scanning apps and drivers for missing glue files..."
    local gen_in="$EXTERNAL_PATH/package/generated_menu.in"
    echo "# Auto-generated menu list" > "$gen_in"
    local catagories=$(ls -d "$EXTERNAL_PATH/package"/*/ 2>/dev/null | xargs -n 1 basename | sort | uniq)
    echo ">>> [SYNC] Found categories: $catagories"
    for cat in $catagories ; do
        echo ">>> [SYNC] Processing category: $cat"
        local cat_dir="$EXTERNAL_PATH/package/$cat"
        if [[ -d "$cat_dir" && "$(ls -A "$cat_dir")" ]]; then
            echo "menu \"${cat^}\"" >> "$gen_in"
            
            # Find all directories that contain a 'src' folder
            find "$cat_dir" -mindepth 2 -maxdepth 2 -type d -name "src" | while read -r src_path; do
                local pkg_dir=$(dirname "$src_path")
                local name=$(basename "$pkg_dir")
                local upper=$(echo "$name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
                
                # 1. Generate .mk if missing
                if [[ ! -f "$pkg_dir/$name.mk" ]]; then
                    echo "  -> Generating $name.mk"
                    cat <<EOF > "$pkg_dir/$name.mk"
${upper}_VERSION = local
${upper}_SITE = \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/package/$cat/$name/src
${upper}_SITE_METHOD = local

define ${upper}_BUILD_CMDS
	\$(MAKE) \$(TARGET_CONFIGURE_OPTS) -C \$(\@D) all
endef

define ${upper}_INSTALL_TARGET_CMDS
	\$(MAKE) \$(TARGET_CONFIGURE_OPTS) -C \$(\@D) DESTDIR=\$(TARGET_DIR) install
endef

\$(eval \$(generic-package))
EOF
                fi
                
                # 2. Generate Config.in if missing
                if [[ ! -f "$pkg_dir/Config.in" ]]; then
                    echo "  -> Generating Config.in for $name"
                    cat <<EOF > "$pkg_dir/Config.in"
config BR2_PACKAGE_${upper}
	bool "$name"
	help
	  Auto-generated package for $name.
EOF
                fi
                
                # Link into the dynamic menu
                echo "    source \"\$BR2_EXTERNAL_${EXT_NAME}_PATH/package/$cat/$name/Config.in\"" >> "$gen_in"
            done
            echo "endmenu" >> "$gen_in"
        fi
    done
}

# @description: Scans for missing .mk and Config.in files for kernel extensions
sync_linux_extensions() {
    echo ">>> [SYNC] Scanning linux extensions for missing glue files..."
    local linux_dir="$EXTERNAL_PATH/$kmod_dir_name"
    local ext_menu="$linux_dir/generated_ext_menu.in"
    
    echo "# Auto-generated kernel extensions list" > "$ext_menu"
    
    if [[ -d "$linux_dir" ]]; then
        echo ">>> [SYNC] Processing linux extensions in: $linux_dir"
        find "$linux_dir" -mindepth 2 -maxdepth 10 -type d -name "src" | while read -r src_path; do
            echo ">>> [SYNC] Processing kernel extension at: $src_path"
            local mod_dir=$(dirname "$src_path")
            local name=$(basename "$mod_dir")
            local upper=$(echo "$name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
            local relative_path=$(realpath --relative-to="$linux_dir" "$mod_dir")
            echo ">>> [SYNC] module name: $name (upper: $upper) relative_path: $relative_path"
            # 1. Generate .mk if missing
            if [[ ! -f "$mod_dir/$name.mk" ]]; then
                echo "  -> Generating kernel module $name.mk"
                cat <<EOF > "$mod_dir/$name.mk"
${upper}_VERSION = local
${upper}_KCONFIG_VAR = BR2_EXT_KERNEL_MODULES_${upper}
${upper}_SITE = \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/$kmod_dir_name/$relative_path
${upper}_SITE_METHOD = local

# Assumes kernel-module infrastructure. Requires Kbuild/Makefile in src/
\$(eval \$(kernel-module))
\$(eval \$(generic-package))
EOF
            fi

            # 2. Generate Config.in if missing
            if [[ ! -f "$mod_dir/Config.in" ]]; then
                echo "  -> Generating Config.in for kernel module $name"
                cat <<EOF > "$mod_dir/Config.in"
config BR2_EXT_KERNEL_MODULES_${upper}
	bool "$name module"
	help
	  Auto-generated kernel module extension for $name.
EOF
            fi
            if [[ ! -f "$mod_dir/Makefile" ]]; then
                echo "  -> Generating Makefile for kernel module $name"
                cat <<EOF > "$mod_dir/Makefile"
# ==============================================================================
# Out-of-Tree Kernel Module Makefile
# ==============================================================================

# Module definition
MODULE_NAME := $name
obj-m += \$(MODULE_NAME).o
MODULE_SRCs := \$(wildcard src/*.c)
MODULE_OBJs := \$(MODULE_SRCs:.c=.o)
\$(MODULE_NAME)-y := \$(MODULE_OBJs)

# Build environment paths
KDIR        ?= \$(KBUILD_OUT_DIR)
PWD         := \$(shell pwd)
# ==============================================================================
# Build Targets
# ==============================================================================
.PHONY: all clean install \$(MODULE_NAME)

all: \$(MODULE_NAME)

\$(MODULE_NAME):
	\$(MAKE) -C \$(KDIR) M=\$(PWD) modules

clean:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) clean

install:
	\$(MAKE) -C \$(KDIR) M=\$(PWD) modules_install
EOF
            fi

            # Link into the dynamic kernel menu
            echo "source \"\$BR2_EXTERNAL_${EXT_NAME}_PATH/$kmod_dir_name/$relative_path/Config.in\"" >> "$ext_menu"
        done
    fi
}
clean_external_packages() {
    echo ">>> [CLEAN] Removing generated package glue files..."
    find "$EXTERNAL_PATH/package" -type f \( -name "*.mk" -o -name "Config.in" -o -name "generated_menu.in" -o -name "Makefile" \) -delete
}

clean_external_linux_extensions() {
    echo ">>> [CLEAN] Removing generated kernel module glue files..."
    find "$EXTERNAL_PATH/$kmod_dir_name" -type f \( -name "*.mk" -o -name "Config.in" -o -name "generated_menu.in" -o -name "Makefile" \) -delete
    #find "$EXTERNAL_PATH/$kmod_dir_name" -type f -name "generated_ext_menu.in" -delete
}

# --- Main Execution ---
main() {
    parse_args "$@"
    init_globals
    
    if [[ "$MODE" == "init" ]]; then
        setup_base_directories
        generate_core_files
        generate_board_configs
        # Running sync immediately after init to generate glue for the scaffolded examples
        sync_packages
        sync_linux_extensions
        echo ">>> [SUCCESS] Initialization complete."
        
    elif [[ "$MODE" == "sync" ]]; then
        sync_packages
        sync_linux_extensions
        echo ">>> [SUCCESS] Sync complete. Buildroot menus updated."
    elif [[ "$MODE" == "clean" ]]; then
        clean_external_packages
        clean_external_linux_extensions
        echo ">>> [SUCCESS] Clean complete. Generated glue files removed."
    else
        echo ">>> [ERROR] Invalid mode: $MODE"
        show_help
        exit 1
    fi
}

main "$@"

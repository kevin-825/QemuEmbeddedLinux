#!/bin/bash
source ./scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh

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
EXT_NAME=$(echo "$RAW_PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
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
        echo ">>> [ERROR] Kernel modules directory does not exist. Please create it first: mkdir -p $EXTERNAL_PATH/$EXT_KMOD_DIR_NAME"
        exit 1
    fi
    local path_to_mod_name="$1"
    local mod_name="$(basename "$path_to_mod_name")"
    # 1. Strip the known prefixes (Pure Bash, no subshells)
    local clean_path="${path_to_mod_name#${EXT_DIR_NAME}/}"
    clean_path="${clean_path#${EXT_KMOD_DIR_NAME}/}"
    local full_path_to_mod="$EXTERNAL_PATH/$EXT_KMOD_DIR_NAME/$clean_path"
    local upper="$(echo "$mod_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
    
    if [[ -d "$full_path_to_mod" ]]; then
        echo ">>> [Info] Module directory already exists: $full_path_to_mod"
        exit 1
    fi
    mkdir -p "$full_path_to_mod/src"

    local relative_path_ext_dir=$(realpath --relative-to="$EXTERNAL_PATH" "$full_path_to_mod")
    local mod_dir="$EXTERNAL_PATH/$relative_path_ext_dir"


    log_debug ">>> [Info] Setting up new external Linux module: $mod_name"
    log_debug ">>> [Info] Path to module: $path_to_mod_name"
    log_debug ">>> [Info] Module directory: $mod_dir"
    log_debug ">>> [Info] Module name: $mod_name"
    log_debug ">>> [Info] Uppercase module name: $upper"
    log_debug ">>> [Info] Full path to module: $full_path_to_mod"
    log_debug ">>> [Info] Relative path to module (from external dir): $relative_path_ext_dir"



    mkdir -p "$mod_dir/src"

    # 1. Create the .mk file
    cat <<EOF > "$mod_dir/$mod_name.mk"
################################################################################
# $mod_name
################################################################################

${upper}_VERSION = 1.0
${upper}_SITE = \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/$relative_path_ext_dir
${upper}_SITE_METHOD = local
${upper}_MODULE_SUBDIR = src

# Optional: Add custom compiler flags here
${upper}_MODULE_MAKE_OPTS = \
    KCFLAGS="-Werror"

\$(eval \$(kernel-module))
\$(eval \$(generic-package))
EOF

    # 2. Create the Config.in file
    cat <<EOF > "$mod_dir/Config.in"
config BR2_PACKAGE_${upper}
    bool "$mod_name module"
    #depends on BR2_LINUX_KERNEL
    #select BR2_PACKAGE_HOST_LINUX_HEADERS
    help
      Auto-generated kernel module extension for $mod_name.
EOF

    # 3. Create the pure Kbuild Makefile
# 3. Create the Hybrid Kbuild/Manual Makefile with Strict Environment Checks
    cat <<EOF > "$mod_dir/src/Makefile"
MODULE_NAME = $mod_name

# ------------------------------------------------------------------------------
# PATH 1: Kbuild Context (Invoked by Buildroot)
# ------------------------------------------------------------------------------
ifneq (\$(KERNELRELEASE),)

$(info ">>> [Info] Running in Kbuild context. Building $mod_name as a kernel module.")

obj-m += \$(MODULE_NAME).o

# Kbuild sets \$(src) to the absolute path of this directory
MODULE_SRCs := \$(wildcard \$(src)/*.c)
MODULE_OBJs := \$(patsubst \$(src)/%.c,%.o,\$(MODULE_SRCs))

\$(MODULE_NAME)-y := \$(MODULE_OBJs)

# ------------------------------------------------------------------------------
# PATH 2: Manual GNU Make Context (Invoked directly by the user)
# ------------------------------------------------------------------------------
else
$(info ">>> [Info] Running in manual make context.")
$(info ">>> [Info] Exported variables: ARCH=$$ARCH, CROSS_COMPILE=$$CROSS_COMPILE, PRE_BUILT_KERNEL_OUT_DIR=$$PRE_BUILT_KERNEL_OUT_DIR")

# --- Strict Environment Checks ---
ifndef ARCH
\$(error [FATAL] ARCH is not exported in the environment. Please run your setup script first.)
endif

ifndef CROSS_COMPILE
\$(error [FATAL] CROSS_COMPILE is not exported in the environment. Please run your setup script first.)
endif

ifndef PRE_BUILT_KERNEL_OUT_DIR
\$(error [FATAL] PRE_BUILT_KERNEL_OUT_DIR is not exported in the environment. Please run your setup script first.)
endif

PWD := \$(shell pwd)

.PHONY: all clean install

all:
	\$(MAKE) -C \$(PRE_BUILT_KERNEL_OUT_DIR) M=\$(PWD) ARCH=\$(ARCH) CROSS_COMPILE=\$(CROSS_COMPILE) modules

clean:
	\$(MAKE) -C \$(PRE_BUILT_KERNEL_OUT_DIR) M=\$(PWD) ARCH=\$(ARCH) CROSS_COMPILE=\$(CROSS_COMPILE) clean

install:
	\$(MAKE) -C \$(PRE_BUILT_KERNEL_OUT_DIR) M=\$(PWD) ARCH=\$(ARCH) CROSS_COMPILE=\$(CROSS_COMPILE) INSTALL_MOD_PATH=\$(INSTALL_DIR) modules_install

endif
EOF

    # 4. Create the C stub
    cat <<EOF > "$mod_dir/src/main.c"
#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static int __init ${mod_name}_init(void) {
    printk(KERN_INFO "${mod_name}: Loaded\n");
    return 0;
}

static void __exit ${mod_name}_exit(void) {
    printk(KERN_INFO "${mod_name}: Unloaded\n");
}

module_init(${mod_name}_init);
module_exit(${mod_name}_exit);
EOF
}

# --- Module: Application Package Setup ---
setup_external_package() {
    if [[ ! -d "$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME" ]]; then
        echo ">>> [Info] Packages directory does not exist. Creating it: $EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME"
        mkdir -p "$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME"
    fi

    local path_to_package_name="$1"
    local package_name="$(basename "$path_to_package_name")"
    local clean_path="${path_to_package_name#${EXT_DIR_NAME}/}"
    clean_path="${clean_path#${EXT_PACKAGE_DIR_NAME}/}"
    local package_dir="$EXTERNAL_PATH/$EXT_PACKAGE_DIR_NAME/$clean_path"
    local upper="$(echo "$package_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
    
    if [[ -d "$package_dir" ]]; then
        echo ">>> [Info] Package directory already exists: $package_dir, exiting to avoid overwriting."
        exit 1
    fi
    local relative_path_ext_dir=$(realpath --relative-to="$EXTERNAL_PATH" "$package_dir")
    echo ">>> [Info] Creating new package directory: $package_dir"
    
    mkdir -p "$package_dir/src"

    local main_c_file="$package_dir/src/main.c"
    local package_makefile="$package_dir/src/Makefile"
    local package_mk_file="$package_dir/$package_name.mk"
    local config_in="$package_dir/Config.in"

    # 1. Create the Config.in file
    cat <<EOF > "$config_in"
config BR2_PACKAGE_${upper}
	bool "$package_name"
	help
	  Auto-generated user-space application package for $package_name.
EOF

    # 2. Create the Buildroot .mk file
    # Note: We point the SITE directly to the src/ directory so Buildroot
    # builds from there, and we pass TARGET_CONFIGURE_OPTS to enforce cross-compilation.
    cat <<EOF > "$package_mk_file"
################################################################################
# $package_name
################################################################################

${upper}_VERSION = 1.0
${upper}_SITE = \$(BR2_EXTERNAL_${EXT_NAME}_PATH)/$relative_path_ext_dir/src
${upper}_SITE_METHOD = local

define ${upper}_BUILD_CMDS
	\$(MAKE) \$(TARGET_CONFIGURE_OPTS) -C \$(@D) all
endef

define ${upper}_INSTALL_TARGET_CMDS
	\$(INSTALL) -D -m 0755 \$(@D)/$package_name \$(TARGET_DIR)/usr/bin/$package_name
endef

\$(eval \$(generic-package))
EOF

    # 3. Create the Standard C Makefile
    # Note: We use ?= for CC and CFLAGS so Buildroot can override them 
    # with the cross-compiler via TARGET_CONFIGURE_OPTS.
    cat <<EOF > "$package_makefile"
# Auto-generated Makefile for $package_name
CC ?= gcc
CFLAGS ?= -Wall -O2
MODULE_SRCs := \$(wildcard *.c)
MODULE_ASMs := \$(wildcard *.S)
MODULE_ASMs += \$(wildcard *.s)
MODULE_OBJs := \$(MODULE_SRCs:.c=.o) \$(MODULE_ASMs:.S=.o)

.PHONY: all clean

all: $package_name

$package_name: \$(MODULE_OBJs)
	\$(CC) \$(LDFLAGS) -o \$@ \$^

\$(MODULE_OBJs): %.o: %.c
	\$(CC) \$(CFLAGS) -c -o \$@ \$<

\$(MODULE_OBJs): %.o: %.S
	\$(CC) \$(CFLAGS) -c -o \$@ \$<
\$(MODULE_OBJs): %.o: %.s
    \$(CC) \$(CFLAGS) -c -o \$@ \$<

clean:
	rm -f *.o $package_name
EOF

    # 4. Create the C Application Stub
    cat <<EOF > "$main_c_file"
#include <stdio.h>

int main(int argc, char **argv) {
    printf("Hello from $package_name user-space application!\\n");
    return 0;
}
EOF

    echo ">>> [SUCCESS] Created user-space package: $package_name"
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

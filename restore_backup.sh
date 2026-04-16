#!/bin/bash
set -e

# --- Global Variables ---
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)
export PROJECT_ROOT="${SCRIPT_DIR}"
JSON_CFG="$SCRIPT_DIR/env.json"
JSON_RESOLVER="$SCRIPT_DIR/scripts/json_resolve_scripts/resolver.sh"

# Source the exception engine
source "$SCRIPT_DIR/scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh"

OUTPUT_BASE_DIR=""
BACKUP_BASE_DIR=""
output_dir=""
backup_dir=""

# --- Arrays ---
ramdisk_bkp_srce_dir_list=()
ramdisk_bkp_dest_dir_list=()
ramdisk_bkp_exclude_list=()
ramdisk_bkp_flag_list=()

# -----------------------------------------------------------------------------
# Module 1: Environment & State Management
# -----------------------------------------------------------------------------
load_environment() {
    if [[ ! -x "$JSON_RESOLVER" ]]; then
        echo "Error: JSON resolver not found or not executable at $JSON_RESOLVER"
        exit 1
    fi

    OUTPUT_BASE_DIR=$("$JSON_RESOLVER" "$JSON_CFG" "environment.OUTPUT_BASE_DIR")
    BACKUP_BASE_DIR=$("$JSON_RESOLVER" "$JSON_CFG" "environment.BACKUP_BASE_DIR")
    output_dir=$("$JSON_RESOLVER" "$JSON_CFG" "build.output_dir")
    backup_dir=$("$JSON_RESOLVER" "$JSON_CFG" "build.backup_dir")

}

init_backup_targets() {
    # CRITICAL FIX: Clear arrays before populating to prevent accumulation in loops
    ramdisk_bkp_srce_dir_list=()
    ramdisk_bkp_dest_dir_list=()
    ramdisk_bkp_exclude_list=()
    ramdisk_bkp_flag_list=()

    # Target 0: Build Directory
    ramdisk_bkp_srce_dir_list+=("$output_dir/build")
    ramdisk_bkp_dest_dir_list+=("$backup_dir/build")
    ramdisk_bkp_exclude_list+=("linux-custom") 
    ramdisk_bkp_flag_list+=("rw")

    # Target 1: Target Directory
    ramdisk_bkp_srce_dir_list+=("$OUTPUT_BASE_DIR/ccache")
    ramdisk_bkp_dest_dir_list+=("$BACKUP_BASE_DIR/ccache")
    ramdisk_bkp_exclude_list+=("None")
    ramdisk_bkp_flag_list+=("rw") 

    # Target 2: Host Directory
    ramdisk_bkp_srce_dir_list+=("$output_dir/host")
    ramdisk_bkp_dest_dir_list+=("$backup_dir/host")
    ramdisk_bkp_exclude_list+=("None")
    ramdisk_bkp_flag_list+=("rw")

    # Target 3: Cache Directory
    ramdisk_bkp_srce_dir_list+=("$output_dir/target")
    ramdisk_bkp_dest_dir_list+=("$backup_dir/target")
    ramdisk_bkp_exclude_list+=("None")
    ramdisk_bkp_flag_list+=("rw")
    
}

# -----------------------------------------------------------------------------
# Module 2: File System Operations
# -----------------------------------------------------------------------------
sync_directories() {
    local src="$1"
    local dst="$2"
    local exc="$3"

    mkdir -p "$dst"
    
    if [ "$exc" != "None" ]; then
        rsync -ah --delete "${src}/" "${dst}/" --exclude "$exc"
    else
        rsync -ah --delete "${src}/" "${dst}/"
    fi
}

backup_ramdisk() {
    load_environment
    init_backup_targets

    for ((i=0; i<${#ramdisk_bkp_srce_dir_list[@]}; i++)); do
        local src="${ramdisk_bkp_srce_dir_list[$i]}"
        local dst="${ramdisk_bkp_dest_dir_list[$i]}"
        local exc="${ramdisk_bkp_exclude_list[$i]}"
        echo "Backing up $src to $dst..."

        if [ -d "$src" ]; then
            echo "Backing up ... $src ==> $dst"
            sync_directories "$src" "$dst" "$exc"
            echo "Done backup."
            echo ""
        else
            echo "Error: Source directory $src not found."
            exit 1
        fi
    done
}

restore_ramdisk() {
    load_environment
    init_backup_targets

    for ((i=0; i<${#ramdisk_bkp_dest_dir_list[@]}; i++)); do
        local src="${ramdisk_bkp_srce_dir_list[$i]}"
        local dst="${ramdisk_bkp_dest_dir_list[$i]}"
        local exc="${ramdisk_bkp_exclude_list[$i]}" # Usually excludes aren't needed for restore, but passed for parity
        echo "Restoring $dst to $src..."

        if [ -d "$src" ]; then
            echo "Skip restoring: Target directory $src already exists."
            continue
        fi

        if [ -d "$dst" ]; then
            echo "Restoring $dst to $src..."
            # For restore, src is the destination
            sync_directories "$dst" "$src" "None" 
            echo "Done restoring."
            echo ""
        else
            echo "Error: Backup directory $dst not found."
        fi
    done

    #find $output_dir/build -name "*stamp_*"
    find "$output_dir/build" -name "*stamp_*installed" -not -path "*host-*" -delete
    mkdir -p $output_dir/images
}

# -----------------------------------------------------------------------------
# Module 3: Workflow Wrappers
# -----------------------------------------------------------------------------
backup_all() {
    export BUILD_PROFILE="customBuild"
    export TARGET_BOARD="qemu_riscv64_virt_board" 
    backup_ramdisk


    export BUILD_PROFILE="customBuild"
    export TARGET_BOARD="qemu_aarch64_virt_board"
    backup_ramdisk
}

restore_all() {
    export BUILD_PROFILE="customBuild"

    export TARGET_BOARD="qemu_riscv64_virt_board" 
    restore_ramdisk
    
    export TARGET_BOARD="qemu_aarch64_virt_board" 
    restore_ramdisk
}

# -----------------------------------------------------------------------------
# Module 4: Command Line Interface
# -----------------------------------------------------------------------------
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -b,  -bk,  --backup       Backup current targets"
    echo "  -r,  -rs,  --restore      Restore current targets"
    echo "  -ba, -bka, --backup-all   Backup all profiles/boards"
    echo "  -ra, -rsa, --restore-all  Restore all profiles/boards"
    echo "  -h,  --help               Display this help message"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|-bk|--backup)        backup_ramdisk; exit 0;;
            -r|-rs|--restore)       restore_ramdisk; exit 0;;
            -ba|-bka|--backup-all)  backup_all; exit 0;;
            -ra|-rsa|--restore-all) restore_all; exit 0;;
            -h|--help|*)            print_help; exit 0;;
        esac
        shift
    done
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------
main() {
    if [[ $# -eq 0 ]]; then
        print_help
        exit 1
    fi
    parse_args "$@"
}

main "$@"
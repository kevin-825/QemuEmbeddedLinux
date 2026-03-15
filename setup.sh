#!/usr/bin/env bash
# setup_workspace.sh - Modular script to generate the Buildroot project architecture

set -euo pipefail

readonly WORKSPACE_NAME="./"

# --- Module: Workspace Directories ---
create_directories() {
    echo "Creating project directory tree in ./${WORKSPACE_NAME}..."
    mkdir -p "${WORKSPACE_NAME}/buildroot"
    mkdir -p "${WORKSPACE_NAME}/out"
    mkdir -p "${WORKSPACE_NAME}/scripts"
    
    # BR2_EXTERNAL Tree
    mkdir -p "${WORKSPACE_NAME}/external/configs"
    mkdir -p "${WORKSPACE_NAME}/external/board"
    mkdir -p "${WORKSPACE_NAME}/external/package"
    
    # Local Source Overrides
    mkdir -p "${WORKSPACE_NAME}/local_src/linux"
    mkdir -p "${WORKSPACE_NAME}/local_src/u-boot"
    mkdir -p "${WORKSPACE_NAME}/local_src/drivers/custom_sensor_mod"
    mkdir -p "${WORKSPACE_NAME}/local_src/apps/my_custom_daemon"
}

# --- Module: Configuration & Script Files ---
create_files() {
    echo "Generating configuration files and scripts..."
    
    # Root Level
    touch "${WORKSPACE_NAME}/build_env.json"
    touch "${WORKSPACE_NAME}/build_runner.sh"
    
    # BR2_EXTERNAL Base
    touch "${WORKSPACE_NAME}/external/external.desc"
    touch "${WORKSPACE_NAME}/external/Config.in"
    touch "${WORKSPACE_NAME}/external/external.mk"
    
    # Defconfigs
    touch "${WORKSPACE_NAME}/external/configs/qemu_riscv64_virt_defconfig"
    touch "${WORKSPACE_NAME}/external/configs/qemu_aarch64_virt_defconfig"
    touch "${WORKSPACE_NAME}/external/configs/raspberrypi3_64_defconfig"
    
    # Hooks
    touch "${WORKSPACE_NAME}/scripts/pre_build.sh"
    touch "${WORKSPACE_NAME}/scripts/post_build.sh"
    
    # Set execution permissions
    chmod +x "${WORKSPACE_NAME}/build_runner.sh"
    chmod +x "${WORKSPACE_NAME}/scripts/pre_build.sh"
    chmod +x "${WORKSPACE_NAME}/scripts/post_build.sh"
}

# --- Module: Host Infrastructure ---
create_host_dependencies() {
    echo "Setting up shared host directories (requires sudo)..."
    
    # Create shared download and ccache directories
    mkdir -p ${WORKSPACE_NAME}/shared/buildroot_downloads
    mkdir -p ${WORKSPACE_NAME}/shared/buildroot_ccache
    
    # Create TFTP boot directory
    #sudo mkdir -p /var/lib/tftpboot
    #sudo chown -R "${USER}:${USER}" /var/lib/tftpboot
}

# --- Main Flow ---
main() {
    create_directories
    create_files
    create_host_dependencies
    
    echo "Success: Architecture generated. You can now cd into ${WORKSPACE_NAME}."
}

main "$@"
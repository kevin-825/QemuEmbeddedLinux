
KERNEL_SRC_PATH="/mnt/wsl/disk2/OffRepos/linux"
PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
output_base_dir="/mnt/wsl/ramdisk5/kbuild_out"
DOCKER_WRAPPER="docker run -it -e TERM=${TERM} --rm -v ${PROJECT_ROOT}:${PROJECT_ROOT} ${dockerVolumes} -w ${PROJECT_ROOT}"




declare -A TARGETS

# Target 0: RISC-V
TARGETS[0,output_dir]="$output_base_dir/riscv64"
TARGETS[0,arch]="riscv"
TARGETS[0,docker]="kflyn825/rvdev:latest"
TARGETS[0,cc]="riscv64-unknown-linux-gnu-"

# Target 1: ARM64
TARGETS[1,output_dir]="$output_base_dir/arm64"
TARGETS[1,arch]="arm64"
TARGETS[1,docker]="kflyn825/arm_dev_u24:latest"
TARGETS[1,cc]="aarch64-none-linux-gnu-"



print_structure_by_index() {
    local Index=$1
    echo "=== Target Configuration for Index: $Index ==="
    echo "Output Directory: ${TARGETS[$Index,output_dir]}"
    echo "Architecture: ${TARGETS[$Index,arch]}"
    echo "Docker Image: ${TARGETS[$Index,docker]}"
    echo "Cross Compiler Prefix: ${TARGETS[$Index,cc]}"
    echo "==========================================="
}



kmake() {
    local DOCKER_CMD="${DOCKER_WRAPPER} ${TARGETS[$Index,docker]}"
    echo "[Info] Selected ARCH:${TARGETS[$Index,arch]}   Index: $Index"

    local cmd=($DOCKER_CMD make -C "$KERNEL_SRC_PATH" O="${TARGETS[$Index,output_dir]}" ARCH="${TARGETS[$Index,arch]}" CROSS_COMPILE="${TARGETS[$Index,cc]}" "$@") 
    echo "[exec] ${cmd[*]}"
    "${cmd[@]}" 
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--index)  
                Index="$2"
                shift 2
                while [[ $# -gt 0 && ! "$1" == -* ]]; do
                    KMAKE_TARGETS+=("$1")
                    shift
                done
                ;;
            -h|--help)   usage; exit 0 ;;
            *) echo "Error: Unknown option '$1'"; usage; exit 1 ;;
        esac
    done
}

usage() {
    echo "Usage: $0 [Options] [Kmake options/args]  "
    echo "Options:"
    echo "  -i, --index <index>   Specify the index for the build configuration (default: 0)"
    echo "  -h, --help            Show this help message and exit"
    echo ""
    echo "Kmake options/args:"
    echo "  Any additional arguments will be passed directly to the 'make' command inside the Kernel source directory."
    echo ""
    echo "Available Indices:"
    for idx in 0 1; do
        echo "  Index $idx: ARCH=${TARGETS[$idx,arch]}"
    done
    exit 1
}

main() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Missing required arguments."
        usage
        exit 1
    fi
    parse_args "$@"

    echo "[Info]  kernel make wrapper starting ... KERNEL_SRC_PATH=${KERNEL_SRC_PATH}    "

    print_structure_by_index "$Index"
    #check_args
    kmake "${KMAKE_TARGETS[@]}"
}

main "$@"
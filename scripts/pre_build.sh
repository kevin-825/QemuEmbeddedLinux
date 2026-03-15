# Source your existing exception handling core
source ./json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh

# --- Configuration & Defaults ---
JSON_CFG="./build_env.json"
jSON_RESOLVER="./json_resolve_scripts/resolver.sh"
# --- Module: Local.mk Generator ---
# @description: Extracts overrides from JSON and writes a local.mk in the target's output directory.
generate_local_mk() {
    local target="$1"
    local profile="$2"

    echo ">>> [INFO] Checking for overrides for Target: $target, Profile: $profile"

    # 1. Resolve the Output Directory Path
    # We fetch the subdir template from JSON and eval it to resolve ${TARGET_BOARD}
    local resolved_output_dir
    resolved_output_dir=$($jSON_RESOLVER "$JSON_CFG" "build.${profile}.output_dir")
    
    # Export TARGET_BOARD so eval can find it
    export TARGET_BOARD="$target"

    local local_mk_path="${resolved_output_dir}/local.mk"

    # 2. Extract Overrides
    # We use jq to get the overrides object and format it for Make syntax
    local overrides
    overrides=$(jq -r ".build.${profile}.overrides | to_entries[] | \"\(.key)_OVERRIDE_SRCDIR = \(.value)\"" "$JSON_CFG")

    if [[ -n "$overrides" && "$overrides" != "null" ]]; then
        # Ensure the directory exists before writing the file
        mkdir -p "$resolved_output_dir"
        
        echo "# Generated Buildroot Override File" > "$local_mk_path"
        echo "# Target: $target | Profile: $profile" >> "$local_mk_path"
        
        while IFS= read -r line; do
            # Resolve variables inside the path (e.g., ${LOCAL_SRC_BASE} or ${ARCH_NAME})
            local resolved_line=$(eval echo "$line")
            echo "$resolved_line" >> "$local_mk_path"
            echo ">>> [OVERRIDE] Applied: $resolved_line"
        done <<< "$overrides"
    else
        echo ">>> [INFO] No overrides found. Skipping local.mk generation."
        # Optional: remove old local.mk to prevent accidental overrides from previous runs
        rm -f "$local_mk_path"
    fi
}

main() {
    #parse_args "$@"
    generate_local_mk "$TARGET_BOARD" "$BUILD_PROFILE"
}

main "$@"

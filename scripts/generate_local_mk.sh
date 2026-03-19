#!/bin/bash
# ==============================================================================
# MODULE: generate_local_mk.sh
# DESCRIPTION: Dynamically generates local.mk from JSON overrides
# ==============================================================================

# Ensure PROJECT_ROOT is available


JSON_CFG="$PROJECT_ROOT/env.json"
jSON_RESOLVER="$PROJECT_ROOT/scripts/json_resolve_scripts/resolver.sh"

# Source exception handling (ensure this path is correct relative to script)
CORE_PATH="$PROJECT_ROOT/scripts/json_resolve_scripts/shell_exception_handling_core/exception_handling_core.sh"
if [[ -f "$CORE_PATH" ]]; then
    source "$CORE_PATH"
fi

generate_local_mk() {
    local json_file="$1"
    local build_profile="$2"
    
    # 1. FIX: Get the directory path and APPEND the filename 'local.mk'
    local output_dir
    output_dir=$($jSON_RESOLVER "$JSON_CFG" "build.output_dir")
    echo "[generate_local_mk]    output_dir:$output_dir"
    local output_file="${output_dir}/local.mk"

    if [[ ! -f "$json_file" ]]; then
        echo ">>> [ERROR] Resolved JSON not found: $json_file" >&2
        return 1
    fi

    # 2. Ensure the output directory actually exists before writing
    mkdir -p "$output_dir"

    echo ">>> [INFO] Generating local.mk for profile: $build_profile" >&2

    # Start with a clean file and header
    {
        echo "# ================================================================"
        echo "# AUTO-GENERATED BUILDROOT OVERRIDES - DO NOT EDIT"
        echo "# Generated from: $(basename "$json_file")"
        echo "# Profile: $build_profile"
        echo "# Date: $(date)"
        echo "# ================================================================"
        echo ""
        
        # The JQ Magic: Accesses the overrides object and formats for Buildroot
        jq -r ".build.overrides | to_entries[] | \"\(.key)_OVERRIDE_SRCDIR = \(.value)\"" "$json_file"
        
    } > "$output_file"

    if [[ $? -eq 0 ]]; then
        echo ">>> [SUCCESS] local.mk generated at: $output_file" >&2
        # Print what we found for visual confirmation
        grep "_OVERRIDE_SRCDIR" "$output_file" | sed 's/^/  [MAPPED] /' >&2
    else
        echo ">>> [ERROR] Failed to parse JSON overrides." >&2
        return 1
    fi
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <resolved_json_path> <profile_name>"
        exit 1
    fi
    generate_local_mk "$@"
fi
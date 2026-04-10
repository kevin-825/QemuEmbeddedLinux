#!/bin/bash

# Resolves to /mnt/wsl/ramdisk5/QemuEmbeddedLinux (goes up two directories from the script location)
PROJECT_ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")
JSON_CFG="$PROJECT_ROOT/env.json"
JSON_RESOLVER="$PROJECT_ROOT/scripts/json_resolve_scripts/resolver.sh"
TASKS_JSON="$PROJECT_ROOT/.vscode/tasks.json"
export PROJECT_ROOT

# --- Safety Checks ---
if [[ ! -f "$JSON_CFG" ]]; then
    echo ">>> [ERROR] env.json not found at: $JSON_CFG"
    exit 1
fi

if [[ ! -f "$TASKS_JSON" ]]; then
    echo ">>> [ERROR] tasks.json not found at: $TASKS_JSON"
    echo ">>> Please create the VS Code task architecture first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo ">>> [ERROR] 'jq' is not installed. Please install it (sudo apt install jq)."
    exit 1
fi

echo ">>> Syncing VS Code tasks with env.json..."

# 1. Extract arrays directly into JSON format using jq
BOARDS_JSON=$(jq -c '.boards | keys' "$JSON_CFG")
PROFILES_JSON=$(jq -c '.build.profiles | keys | map(select(. != "base_options"))' "$JSON_CFG")
EXT_DIR=$($JSON_RESOLVER "$JSON_CFG" "environment.EXTERNAL_DIR")
echo " EXT_DIR: $EXT_DIR"
EXTERNAL_CONFIGS=$(ls "$EXT_DIR/configs" 2>/dev/null | jq -R -s 'split("\n")[:-1]') # Get list of config files, handle empty case
echo " EXTERNAL_CONFIGS: $EXTERNAL_CONFIGS"
# Ensure the jq extraction actually worked before overwriting files
if [[ -z "$BOARDS_JSON" || "$BOARDS_JSON" == "null" ]]; then
    echo ">>> [ERROR] Failed to parse boards from env.json."
    exit 1
fi


# 2. Surgically replace the options arrays inside tasks.json
jq --argjson boards "$BOARDS_JSON" --argjson profiles "$PROFILES_JSON" --argjson extConfigs "$EXTERNAL_CONFIGS" '
  (.inputs[] | select(.id == "targetBoard") | .options) = $boards |
  (.inputs[] | select(.id == "targetBoard") | .default) = $boards[0] |
  (.inputs[] | select(.id == "buildProfile") | .options) = $profiles |
  (.inputs[] | select(.id == "buildProfile") | .default) = $profiles[0] |
  (.inputs[] | select(.id == "loadConfigName") | .options) = $extConfigs
' "$TASKS_JSON" > "${TASKS_JSON}.tmp"

# 3. Commit the changes
if [[ $? -eq 0 && -s "${TASKS_JSON}.tmp" ]]; then
    mv "${TASKS_JSON}.tmp" "$TASKS_JSON"
    echo ">>> [SUCCESS] tasks.json updated with latest boards and profiles!"
else
    echo ">>> [ERROR] Failed to update tasks.json."
    rm -f "${TASKS_JSON}.tmp"
    exit 1
fi
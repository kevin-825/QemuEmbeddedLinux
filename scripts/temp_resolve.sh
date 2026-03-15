#!/bin/bash

# Define the regex as a variable.
# Exporting it ensures Perl can read the exact string safely without Bash quoting conflicts.
export RE_JSON_TEMPLATE='\$\{((?:[^{}]|(?R))*)\}'

extract_template() {
    local input_line="$1"
    
    # Perl compiles the regex from the environment variable.
    # $& = The full matched string (Index 0)
    # $1 = The captured inner group (Index 1)
    mapfile -t MATCHES < <(perl -nle 'if (/$ENV{RE_JSON_TEMPLATE}/) { print "$&\n$1"; exit }' <<< "$input_line")
}

# --- Test Case ---
line='  "${targets.${TARGET_BOARD}.rootfsOnly_BR2_OPT.join(" ")}", "${next_var}"'

extract_template "$line"

echo "MATCHES[0] (Full Match):  ${MATCHES[0]}"
echo "MATCHES[1] (Inner Group): ${MATCHES[1]}"
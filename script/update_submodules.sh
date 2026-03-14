#!/bin/bash


main() {
    # Check if specific submodules were passed as arguments
    if [ $# -gt 0 ]; then
        echo "Updating specified submodules..."
        for mod in "$@"; do
            git submodule update --init --recursive "$mod"
        done
    else
        echo "No arguments provided. Updating ALL submodules recursively..."
        # This is the most reliable way to catch everything including nested ones
        git submodule update --init --recursive
    fi

    echo "------------------------------------------"
    echo "Done."
}

main "$@"
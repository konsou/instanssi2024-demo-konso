#!/usr/bin/env bash

# Exports all environment variables from a file
# Example usage
# source dotenv.sh
# load_venv "/path/to/.env"
load_venv() {
    # Check if the argument (file path) was provided
    if [[ -z "$1" ]]; then
        echo "Error: No path provided to load_venv" >&2
        return 1
    fi

    # Check if the file exists
    if [[ ! -f "$1" ]]; then
        echo "Error: File $1 does not exist" >&2
        return 1
    fi

    # Check if the file contains any assignment-like lines (e.g., VAR=value)
    if ! grep -Eq '^[a-zA-Z_][a-zA-Z0-9_]*=.*$' "$1"; then
        echo "Error: File $1 does not appear to contain any variables" >&2
        return 1
    fi

    # Source the file and export the variables
    set -a
    # shellcheck disable=SC1090
    source "$1"
    set +a
}

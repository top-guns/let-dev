#!/bin/bash

# This script acts as a simple key-value store.

# File to store values
LETDEV_STORAGE_FILE="$LETDEV_HOME/profiles/$LETDEV_PROFILE/storage.env"


letdev_storage_list() {
    # Remove all except key-value pairs
    cat "$LETDEV_STORAGE_FILE" | grep -E "^[^#].*="
}

# Get the value associated with a key
letdev_storage_get() {
    local key="$1"
    grep "^$key=" "$LETDEV_STORAGE_FILE" | cut -d '=' -f2-
}

# Set the value associated with a key
letdev_storage_set() {
    local key="$1"
    local value="$2"

    if grep -q "^$key=" "$LETDEV_STORAGE_FILE"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/^$key=.*/$key=$value/" "$LETDEV_STORAGE_FILE"
        else
            # Linux (Ubuntu и другие)
            sed -i "s/^$key=.*/$key=$value/" "$LETDEV_STORAGE_FILE"
        fi
        
    else
        echo "$key=$value" >> "$LETDEV_STORAGE_FILE"
    fi
}

# Check if a key exists
letdev_storage_has() {
    local key="$1"
    grep -q "^$key=" "$LETDEV_STORAGE_FILE" && return 0 || return 1
}

# Remove the value associated with a key
letdev_storage_remove() {
    local key="$1"
    sed -i '' "/^$key=/d" "$LETDEV_STORAGE_FILE"
}

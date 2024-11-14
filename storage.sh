#!/bin/bash

# This script acts as a simple key-value store.


# File to store values
LETDEV_STORAGE_FILE="$LETDEV_HOME/profiles/$LETDEV_PROFILE/storage.env"


# ----------------------------------------------------------------
# Interact with the storage file
# The storage file is a simple text file with key-value pairs separated by an equal sign

_storage_var_find_key() {
    local key="$1"

    if grep -q "^$key=" "$LETDEV_STORAGE_FILE"; then
        return 0  # Key found
    else
        return 1  # Key not found
    fi
}

_storage_var_get_value() {
    local key="$1"
    local value=$(grep "^$key=" "$LETDEV_STORAGE_FILE" | cut -d '=' -f2-)
    echo "$value"
}

_storage_var_put_value() {
    local key="$1"
    local value="$2"

    if grep -q "^$key=" "$LETDEV_STORAGE_FILE"; then
        sed -i '' "s/^$key=.*/$key=$value/" "$LETDEV_STORAGE_FILE"
    else
        echo "$key=$value" >> "$LETDEV_STORAGE_FILE"
    fi
}

_storage_var_remove_value() {
    local key="$1"
    sed -i '' "/^$key=/d" "$LETDEV_STORAGE_FILE"
}

_storage_var_rows() {
    # Remove all except key-value pairs
    cat "$LETDEV_STORAGE_FILE" | grep -E "^[^#].*="
}


# ----------------------------------------------------------------
# Interact with the storage service

letdev_storage_list() {
    _storage_var_rows
}

# Get the value associated with a key
letdev_storage_get() {
    local key=$1
    local value=$(_storage_var_get_value "$key")
    echo "$value"
}

# Set the value associated with a key
letdev_storage_set() {
    local key=$1
    local value=$2
    _storage_var_put_value "$key" "$value"
}

# Check if a key exists
letdev_storage_has() {
    local key=$1
    local result=$(_storage_var_find_key "$key" && echo true || echo false)
    [ "$result" = true ] && return 0 || return 1
}

# Remove the value associated with a key
letdev_storage_remove() {
    local key=$1
    _storage_var_remove_value "$key"
}

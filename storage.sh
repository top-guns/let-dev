#!/bin/bash

# This script acts as a simple key-value store.
# It listens for commands from a named pipe and performs operations
# to store and retrieve values.


# Named pipe for reading commands
LETDEV_STORAGE_PIPE_IN="/tmp/letdev_storage_pipe_in"
# Named pipe for writing results
LETDEV_STORAGE_PIPE_OUT="/tmp/letdev_storage_pipe_out"
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
# Interact with the storage listener via named pipe

letdev_storage_list() {
    echo "list" >$LETDEV_STORAGE_PIPE_IN
    cat <$LETDEV_STORAGE_PIPE_OUT
}

# Get the value associated with a key
letdev_storage_get() {
    local key=$1
    letdev_storage_has $key || return
    echo "get $key" >$LETDEV_STORAGE_PIPE_IN
    cat <$LETDEV_STORAGE_PIPE_OUT
}

# Set the value associated with a key
letdev_storage_set() {
    local key=$1
    local value=$2
    echo "set $key $value" >$LETDEV_STORAGE_PIPE_IN
}

# Check if a key exists
letdev_storage_has() {
    local key=$1
    echo "has $key" >$LETDEV_STORAGE_PIPE_IN
    local result=$(cat <$LETDEV_STORAGE_PIPE_OUT)
    [ "$result" = "true" ]
}

# Remove the value associated with a key
letdev_storage_remove() {
    local key=$1
    echo "remove $key" >$LETDEV_STORAGE_PIPE_IN
}


# ----------------------------------------------------------------
# Storage listener

# Create a named pipe for communication and start listening for commands
_letdev_storage_listener() {
    # Create named pipes if they do not exist
    [ -p $LETDEV_STORAGE_PIPE_IN ] || mkfifo $LETDEV_STORAGE_PIPE_IN
    [ -p $LETDEV_STORAGE_PIPE_OUT ] || mkfifo $LETDEV_STORAGE_PIPE_OUT    

    # Listen for commands
    while true; do
        if read -r line <$LETDEV_STORAGE_PIPE_IN; then
            # Split the line into command and arguments
            local cmd=$(echo $line | cut -d ' ' -f1)
            local key=$(echo $line | cut -d ' ' -f2)
            # value is the rest of the line
            local val=$(echo $line | cut -d ' ' -f3-)

            # Perform the command based on the received value
            case "$cmd" in
                "list")
                    _storage_var_rows >$LETDEV_STORAGE_PIPE_OUT
                    ;;
                "set")
                    _storage_var_put_value "$key" "$val"
                    ;;
                "get")
                    local val=$(_storage_var_get_value "$key")
                    echo "$val" >$LETDEV_STORAGE_PIPE_OUT
                    ;;
                "has")
                    _storage_var_find_key "$key" && echo "true" >$LETDEV_STORAGE_PIPE_OUT || echo "false" >$LETDEV_STORAGE_PIPE_OUT
                    ;;
                "remove")
                    _storage_var_remove_value "$key"
                    ;;
                "exit")
                    break
                    ;;
                *)
                    echo "let-dev storage error: unknown command '$cmd'" >&2
                    ;;
            esac
        fi
    done

    # Clean up the named pipes
    [ -p $LETDEV_STORAGE_PIPE_IN ] && rm $LETDEV_STORAGE_PIPE_IN
    [ -p $LETDEV_STORAGE_PIPE_OUT ] && rm $LETDEV_STORAGE_PIPE_OUT
}


# ----------------------------------------------------------------
# Storage listener management

# Start the listener in the background
letdev_storage_start() {
    letdev_storage_started || letdev_marked_process_start letdev_storage_listener _letdev_storage_listener
}

# Stop the listener and remove the named pipes
letdev_storage_stop() {
    # Send the exit command to the listener if it is running
    # if [ -p $LETDEV_STORAGE_PIPE_IN ]; then
    #     echo "exit" >$LETDEV_STORAGE_PIPE_IN
    # fi

    # Kill the listener process if it is running
    letdev_marked_process_kill letdev_storage_listener
        
    # Clean up the named pipes if they exist
    [ -p $LETDEV_STORAGE_PIPE_IN ] && rm $LETDEV_STORAGE_PIPE_IN
    [ -p $LETDEV_STORAGE_PIPE_OUT ] && rm $LETDEV_STORAGE_PIPE_OUT
}

letdev_storage_restart() {
    letdev_storage_stop
    letdev_storage_start
}

# Check if the listener is running
letdev_storage_started() {
    letdev_marked_process_started letdev_storage_listener
}

letdev_storage_status() {
    if letdev_storage_started; then
        echo "running"
    else
        echo "stopped"
    fi
}

letdev_storage_pid() {
    local pid=$(letdev_marked_process_pid letdev_storage_listener)
    [ -n "$pid" ] && echo $pid
}

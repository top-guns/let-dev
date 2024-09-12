#!/bin/bash

# This script acts as a simple key-value store.
# It listens for commands from a named pipe and performs operations
# to store and retrieve values.

# Named pipe for reading commands
LETDEV_STORAGE_PIPE_IN="/tmp/letdev_storage_pipe_in"
# Named pipe for writing results
LETDEV_STORAGE_PIPE_OUT="/tmp/letdev_storage_pipe_out"

# Get the value associated with a key
letdev_storage_get() {
    local key=$1
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
    cat <$LETDEV_STORAGE_PIPE_OUT
}

# Remove the value associated with a key
letdev_storage_remove() {
    local key=$1
    echo "remove $key" >$LETDEV_STORAGE_PIPE_IN
}

# Create a named pipe for communication and start listening for commands
_letdev_storage_listener() {
    # Create named pipes if they do not exist
    [ -p $LETDEV_STORAGE_PIPE_IN ] || mkfifo $LETDEV_STORAGE_PIPE_IN
    [ -p $LETDEV_STORAGE_PIPE_OUT ] || mkfifo $LETDEV_STORAGE_PIPE_OUT

    # Declare an associative array to store values
    declare -A values

    # Listen for commands
    while true; do
        if read -r line <$LETDEV_STORAGE_PIPE_IN; then
            # Split the line into command and arguments
            cmd=$(echo $line | cut -d ' ' -f1)
            arg1=$(echo $line | cut -d ' ' -f2)
            arg2=$(echo $line | cut -d ' ' -f3)

            # Perform the command based on the received value
            case $cmd in
                "set")
                    values[$arg1]=$arg2
                    ;;
                "get")
                    echo "${values[$arg1]}" >$LETDEV_STORAGE_PIPE_OUT
                    ;;
                "has")
                    [ -n "${values[$arg1]}" ] && echo "true" >$LETDEV_STORAGE_PIPE_OUT || echo "false" >$LETDEV_STORAGE_PIPE_OUT
                    ;;
                "remove")
                    unset values[$arg1]
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

# Start the listener in the background
letdev_storage_start() {
    (_letdev_storage_listener &)
}

# Stop the listener and remove the named pipes
letdev_storage_stop() {
    # Send the exit command to the listener if it is running
    if [ -p $LETDEV_STORAGE_PIPE_IN ]; then
        echo "exit" >$LETDEV_STORAGE_PIPE_IN
    fi
        
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
    [ -p $LETDEV_STORAGE_PIPE_IN ]
}

letdev_storage_status() {
    if letdev_storage_started; then
        echo "running"
    else
        echo "stopped"
    fi
}

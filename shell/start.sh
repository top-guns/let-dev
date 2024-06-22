#!/bin/bash

# Load aliases to make them available in the current shell
shopt -s expand_aliases
# source $HOME/.bashrc

source $LETDEV_PATH/shell/lib/settings.sh
source $LETDEV_PATH/shell/lib/util.sh
source $LETDEV_PATH/shell/lib/commands.sh
source $LETDEV_PATH/shell/lib/history.sh
source $LETDEV_PATH/shell/lib/display.sh

SHELL_MODE=false
PINNED_COMMANDS=()
# Current command
COMMAND=""
COMMAND_ARGS=()

# Array to store command history
COMMAND_HISTORY=()
COMMAND_HISTORY_INDEX=-1

# Check for --clear-history option
for arg in "$@"
do
    if [ "$arg" == "--clear-history" ]; then
        > "$HISTORY_FILE"
    elif [ "$arg" == "clear-history" ]; then
        > "$HISTORY_FILE"
        echo "Command history cleared"
        exit 0
    elif [ "$arg" == "--help" ]; then
        echo "Usage: $0 [--clear-history] [--help]"
        echo "  --clear-history: Clear the command history"
        echo "  --help: Print this help message"
        exit 0
    else 
        echo "Unknown option: $arg"
        exit 1
    fi
done

# Check for the existence of the history file
if [ ! -f "$HISTORY_FILE" ]; then
    touch "$HISTORY_FILE"
fi


# Function to handle the window size change signal
handle_winch() {
    # Ignore the signal while we are handling it
    trap "" SIGWINCH
    redraw_screen
    # Reinstall the signal handler
    trap handle_winch SIGWINCH
}

# Function to wait for the next command
wait_for_command() {
    display_command_input
    execute_command
}


# Handle the window size change signal
trap handle_winch SIGWINCH

# Main loop
while true; do
    [ "$SHELL_MODE" = false ] && redraw_screen
    wait_for_command
done
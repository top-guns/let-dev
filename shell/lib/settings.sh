#!/bin/bash

# Get the absolute path of the current script
[ -n "${BASH_SOURCE[0]}" ] && SCRIPT_PATH="${BASH_SOURCE[0]}" || SCRIPT_PATH="$0"
SCRIPT_DIR=`dirname $SCRIPT_PATH`

TERM_SYMBOL=${LETDEV_SYMBOL:-'::'}

# File for storing command history
HISTORY_FILE="$LETDEV_USERS_PATH/$LETDEV_PROFILE/command_history.txt"
# HISTORY_LINES=100
BLOCK_SEPARATOR_FILE='─────────────────────────────'
FILL_SYMBOL_FILE='▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨'

COMMAND_SYMBOL=':'
FILE_SYMBOL='<'
COMMENT_SYMBOL='#'
VAR_SYMBOL='$'
DELETE_SYMBOL='x'
HELP_SYMBOL='?'
ATTACH_SYMBOL='+'

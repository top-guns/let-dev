#!/bin/bash

source "$LETDEV_HOME/storage.sh"
source "$LETDEV_HOME/list_commands_impl.sh"
source "$LETDEV_HOME/commands_history.sh"

if [[ $(letdev_storage_get ldm) == "history" ]]; then
    letdev_storage_set ldm ""
    get_history_commands
else
    letdev_storage_set ldm "history"
    list_commands --format=command
fi

#!/bin/bash

# Save the process marker to the LETDEV_MARKER
eval $1
shift

trap "pkill -P $$" EXIT

shopt -s expand_aliases
source $LETDEV_HOME/init-shell.sh bash false

eval $@ > /dev/null 2>&1

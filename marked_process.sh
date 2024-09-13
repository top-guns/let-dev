#!/bin/bash

_get_marker_string() {
    local marker="$1"
    echo "LETDEV_MARKER=$marker "
}


letdev_marked_process_start() {
    local marker="$1"
    shift
    [ -z "$marker" ] && echo "Missing marker" >&2 && return 1

    # Check if the marker is already in the list of marked processes
    letdev_marked_process_started "$marker" && echo "Process already started" >&2 && return 1

    marker=$(_get_marker_string "$marker")

    # Start the process in the background with loaded bash environment
    # local cmd=" \
    #     bash -c \" \
    #         trap 'pkill -P \\\$BASHPID' EXIT; \
    #         shopt -s expand_aliases; \
    #         export LETDEV_HOME='$LETDEV_HOME'; \
    #         export LETDEV_PROFILE='$LETDEV_PROFILE'; \
    #         source $LETDEV_HOME/init-shell.sh bash false; \
    #         $marker eval $@ \
    #     \" & \
    # "
    local cmd="$LETDEV_HOME/marked_process_starter.sh $marker '$@' &"
    # echo "Starting process: $cmd"
    (eval $cmd)
}

letdev_marked_process_kill() {
    local pids=$(ps aux | grep $1 | grep -v grep | awk '{print $2}')

    [ -z "$pids" ] && echo "No process found for pattern: '$pattern'" && return

    # if many processes found, ask user to confirm
    local process_count=$(echo "$pids" | wc -l | tr -d ' ')
    if [ $process_count -gt 1 ]; then
        echo "Found multiple processes: $(echo "$pids" | xargs | sed 's/ /, /g')"
        local message="Do you want to kill all these processes? [y/n]: "
        local result
        if [[ $SHELL == *"zsh"* ]]; then
            vared -p "$message" 'result'
        else
            read -p "$message" result
        fi

        [ "$result" != "y" ] && return
    fi

    for pid in $(echo "$pids"); do
        kill -9 $pid
    done
    
    if [ $process_count -gt 1 ]; then
        echo "$process_count processes killed"
    else
        # echo "Process killed"
        true
    fi
}

letdev_marked_process_pid() {
    local marker="$1"
    [ -z "$marker" ] && echo "Missing marker" >&2 && return 1
    marker=$(_get_marker_string "$marker")

    # Get the PID of the process by the marker
    local pids=$(pgrep -f "$marker")
    [ -z "$pids" ] && return

    # Skip all pids that is child of the other pids in the list
    for p in $(echo "$pids"); do
        local parent=$(ps -o ppid= -p $p)
        if ! echo "$pids" | grep -q "$parent"; then
            echo "$p"
        fi
    done
}

letdev_marked_process_started() {
    local pid=$(letdev_marked_process_pid "$1")
    [ -n "$pid" ]
}

letdev_marked_process_status() {
    if letdev_marked_process_started "$1"; then
        echo "started"
    else
        echo "stopped"
    fi
}

letdev_marked_process_current_marker() {
    [ -n "$LETDEV_MARKER" ] && echo "$LETDEV_MARKER"
}

# Format: Market, Parent PID, PID, COMMAND
letdev_marked_process_ps() {
    local processes=$(ps -eo ppid,pid,args | grep " LETDEV_MARKER=" | grep -v 'grep --color=auto' | grep -v 'grep  LETDEV_MARKER=')
    [ -z "$processes" ] && echo "No marked processes found" && return

    local markers=() pids=() ppids=() commands=()
    local max_marker=6 max_ppid=4 max_pid=3 max_command=7

    while IFS= read -r line; do
        ppid=$(echo "$line" | awk '{print $1}')
        pid=$(echo "$line" | awk '{print $2}')
        marker=$(echo "$line" | awk -F"LETDEV_MARKER=" '{print $2}' | awk '{print $1}')
        eval_value=$(echo "$line" | sed "s/.*LETDEV_MARKER=$marker  *//")

        (( ${#marker} > max_marker )) && max_marker=${#marker}
        (( ${#ppid} > max_ppid )) && max_ppid=${#ppid}
        (( ${#pid} > max_pid )) && max_pid=${#pid}
        (( ${#eval_value} > max_command )) && max_command=${#eval_value}

        markers+=("$marker")
        ppids+=("$ppid")
        pids+=("$pid")
        commands+=("$eval_value")
    done <<< "$processes"

    printf "%-${max_marker}s %-${max_ppid}s %-${max_pid}s %-${max_command}s\n" "Marker" "PPID" "PID" "Command"

    if [ "$ZSH_VERSION" ]; then
        start_index=1
        array_length=$((${#markers[@]} + 1))
    else
        start_index=0
        array_length=${#markers[@]}
    fi

    for ((i=$start_index; i<$array_length; i++)); do
        printf "%-${max_marker}s %-${max_ppid}s %-${max_pid}s %-${max_command}s\n" "${markers[$i]}" "${ppids[$i]}" "${pids[$i]}" "${commands[$i]}"
    done
}
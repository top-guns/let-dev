#!/bin/bash

text_shell_processor() {
    local separator="$1"
    shift

    # For each argument
    local result=""
    for arg in "$@"; do
        local value=""

        # If the argument is environment variable
        if [[ "${arg:0:1}" == "$" ]]; then
            # Remove the dollar sign from the beginning of the environment variable
            local name=$(echo "$arg" | sed "s/^[$]//")
            [ -z "$name" ] && value=$(env) || value=$(eval echo "\$$name") || continue
        # If the argument is a file path
        elif [[ "${arg:0:1}" == "/" ]] || [[ "${arg:0:2}" == "./" ]] || [[ "${arg:0:3}" == "../" ]] || [[ "${arg:0:2}" == "~/" ]] || [[ "${arg}" == "." ]] || [[ "${arg}" == ".." ]] || [[ "${arg}" == "~" ]]; then
            # Replace the tilde with the home directory
            local path=$(sed "s|~|$HOME|" <<< $arg)
            # Print the content of the file with the specified path
            [ -f "$path" ] && value=$(cat "$path")
            [ -d "$path" ] && value=$(ls -l "$path")
            # [ -s "$path" ] && value=$(du -sh "$path")
            [ -z "$value" ] && value="File not found"
        # If the argument is a command
        elif [[ "${arg:0:1}" == ":" ]]; then
            # Execute the command and print the result
            value=$(eval $arg)
        else
            value="$arg"

            local first="${value:0:1}"
            local last="${value:${#value}-1:1}"

            # If the first and the last symbols are the same and the length of the argument is greater than 1
            if [[ "$first" == "$last" ]] && [[ "${#value}" -gt 1 ]]; then
                # if the first symbol is one of the following: ' " `
                if [[ "$first" == "'" ]] || [[ "$first" == "\"" ]] || [[ "$first" == "\`" ]]; then
                    # Remove the first and the last symbols
                    value=$(echo "$value" | sed "s/^.\(.*\).$/\1/")
                fi
            fi
        fi

        if [ -n "$value" ]; then
            if [ -z "$result" ]; then
                result="$value"
                echo -n "$value"
            else
                result="$result$separator$value"
                echo -n -e "$separator"
                echo -n "$value"
            fi
        fi
    done
}

select_command() {
    local query="$1"
    [ -n "$query" ] && filter="--query=$query" && shift || query=""

    local selected=$($LETDEV_HOME/completion-output.sh | fzf $query \
        --no-sort \
        --cycle \
        --reverse \
        --exact \
        --inline-info \
        --preview="$LETDEV_HOME/get-command-variable.sh {} COMMAND_HELP" \
        --bind "tab:reload( LETDEV_HOME='$LETDEV_HOME' $LETDEV_HOME/completion-output.sh )" \
    )
    [ -n "$selected" ] && echo "$selected"
}

default_command() {
    local cur_command=""
    if [ -n "$ZSH_VERSION" ]; then
        # Save the current command to the history
        fc -AI
        # Update the history file
        fc -R
        # Get the last command
        cur_command=$(fc -ln -1 | tail -n 1)
    elif [ -n "$BASH_VERSION" ]; then
        # Save the current command to the history
        history -a
        # Update the history file
        history -r
        # Get the last command
        cur_command=$(history | tail -n 1 | sed "s/^[ ]*[0-9]*[ ]*//")
    else
        echo "Unsupported shell"
        return 1
    fi

    # Add the current command to the let-dev history
    put_command_to_history "$cur_command"

    # ----------------------------------------------------------------
    # Text shell

    # Remove the leading spaces
    local text_shell_input=$(echo "$cur_command" | sed "s/^[ ]*//")
    # echo "Text shell input: '$text_shell_input'"

    # If the command starts with '::' then use text shell to process the command
    if [[ "${text_shell_input:0:2}" == "$LETDEV_SYMBOL$LETDEV_SYMBOL" ]]; then
        local separator_mode=false
        [[ "${text_shell_input:0:3}" == "$LETDEV_SYMBOL$LETDEV_SYMBOL$LETDEV_SYMBOL" ]] && separator_mode=true

        # Remove let-dev text shell command at the beginning of the line
        text_shell_input=$(echo "$text_shell_input" | sed "s/^[ ]*::*[ ]*//")

        local separator=""
        if [ "$separator_mode" = true ]; then
            # Separator is the first argument in text_shell_input
            separator=$(echo "$text_shell_input" | cut -d " " -f 1)
            # Remove the separator from the text_shell_input
            text_shell_input=$(echo "$text_shell_input" | cut -d " " -f 2-)
        fi

        # echo "Text shell input: '$text_shell_input', length: ${#text_shell_input}, separator: '$separator'"
        if [ "${#text_shell_input}" -eq 0 ]; then
            # $LETDEV_HOME/shell/start.sh

            echo "Let-Dev settings:"
            echo "  Profile: $LETDEV_PROFILE"
            echo "  Home: $LETDEV_HOME"

            return
        fi

        # Parse the imput: split by spaces and process each part
        local parts=($text_shell_input)
        local result=$(text_shell_processor "$separator" "${parts[@]}")
        [ -n "$result" ] && echo "$result"
        return
    fi


    # ----------------------------------------------------------------
    # Command shell

    local cmd=''

    if [ "$#" -eq 0 ]; then
        # $LETDEV_HOME/shell/start.sh
        cmd=$(select_command)
    else
        cmd=`echo "$1"`
        shift
    fi

    if [ -z "$cmd" ]; then
        return
    fi
    # echo "cmd: $cmd"
    
    # # Remove ': ' from the beginning of the command
    # cmd=`echo "$cmd" | sed "s|^$LETDEV_SYMBOL[ ]*||"`

    # Replace spaces with /
    # cmd=`echo "$cmd" | tr " " "/"`
    # echo "cmd: $cmd"


    # Remove let-dev default command at the beginning of the line
    cmd=$(echo "$cmd" | sed "s/^[ ]*:[ ][ ]*//")

    # If the first symbol is a colon, then add the home directory to the command
    if [[ "${cmd:0:1}" == "$LETDEV_SYMBOL" ]]; then
        # Remove the first symbol if it is a colon
        cmd=$(echo "$cmd" | sed "s/^://")

        # echo "Command shell input: $cmd"
        
        # Replace colons with slashes
        cmd=`echo "$cmd" | tr ":" "/"`
        cmd2=`echo "$cmd" | sed "s|/\([^/]*\)$|/-\1|"`

        # TODO: use get-command-script-path.sh !

        local project_command=$(list_commands --project --format=fullpath | grep "$cmd$")
        local project_command2=$(list_commands --project --format=fullpath | grep "$cmd2$")

        # Add the home directory to the command
        if [ -n "$project_command" ]; then
            cmd=`echo "$project_command"`
        elif [ -n "$project_command2" ]; then
            cmd=`echo "$project_command2"`
        elif [ -f "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands/$cmd" ]; then
            cmd=`echo "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands/$cmd"`
        elif [ -f "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands/$cmd2" ]; then
            cmd=`echo "$LETDEV_HOME/profiles/$LETDEV_PROFILE/commands/$cmd2"`
        elif [ -f "$LETDEV_HOME/commands/$cmd" ]; then
            cmd=`echo "$LETDEV_HOME/commands/$cmd"`
        elif [ -f "$LETDEV_HOME/commands/$cmd2" ]; then
            cmd=`echo "$LETDEV_HOME/commands/$cmd2"`
        else 
            echo "Command '$cmd' not found"
            return
        fi
    fi

    # Resolve symbolic links
    # cmd=`readlink -f $cmd`

    source "$cmd" "$@"
}

default_command "$@"

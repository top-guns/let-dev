#!/bin/bash

_letdev_complete() {
    local cur prev words cword
    _init_completion || return
    local cmds=$($LETDEV_HOME/list-commands.sh)
    COMPREPLY=($(compgen -W "$(echo "$cmds" | fzf --reverse --inline-info --tac)" -- "$cur"))
}

_letdev_tab_complete() {
    if [[ -n "$READLINE_LINE" ]]; then
        local words=($READLINE_LINE)
        local cur_word_index=$(
            IFS=" "
            set -f
            set -- $READLINE_LINE
            echo $#
        )
        local cur=${words[cur_word_index - 1]}
        local prev=${words[cur_word_index - 2]}

        # If the previous symbol is space, then the new argument is started
        local symbol_before_cursor=${READLINE_LINE:READLINE_POINT-1:1}
        if [[ "$symbol_before_cursor" != " " ]]; then
            if [[ "$cur" =~ ^: ]]; then
                local cmds=$($LETDEV_HOME/list-commands.sh | sed 's|/|:|g')

                if [[ $cur_word_index -eq 1 ]]; then
                    # Command completion
                    local selected=$(echo "$cmds" | fzf --reverse --inline-info --tac --query=": $cur")
                    if [[ -n $selected ]]; then
                        READLINE_LINE=": $selected"
                        READLINE_POINT=$((2 + ${#selected}))
                    fi
                    return 0
                else
                    # Arguments completion
                    local selected=$(echo "$cmds" | fzf --reverse --inline-info --tac --query="$cur")
                    if [[ -n $selected ]]; then
                        local cur_length=${#cur}
                        READLINE_LINE=${READLINE_LINE:0:$((READLINE_POINT - cur_length))}$selected${READLINE_LINE:$READLINE_POINT}
                        READLINE_POINT=$((READLINE_POINT - cur_length + ${#selected}))
                    fi
                    return 0
                fi

            fi
        fi
    fi

    fzf_bash_completion
}

multiline_to_array() {
    local str=$1
    local arr_name=$2
    eval $arr_name'=()'
    while IFS= read -r line; do
        eval $arr_name'+=("$line")'
    done <<< "$str"
}

_letdev_init_completion() {
    local commands=$($LETDEV_HOME/list-commands.sh)
    multiline_to_array "$commands" "commands"

    # Create alias for every command
    for command in "${commands[@]}"; do
        alias_name=$(echo $command | sed 's|/|:|g')
        alias "$alias_name"="$LETDEV_HOME/default.sh $command"
    done

    complete -F _letdev_complete :
    bind -x '"\t": _letdev_tab_complete'
}

_letdev_init_completion

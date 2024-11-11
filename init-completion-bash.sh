#!/bin/bash

# _letdev_complete() {
#     local cur prev words cword
#     _init_completion || return
#     local cmds=$($LETDEV_HOME/list-commands.sh --with-descriptions)
#     COMPREPLY=($(compgen -W "$(echo "$cmds" | fzf --reverse --inline-info --tac --preview)" -- "$cur"))
# }

_letdev_menu_handler() {
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
                letdev_storage_set ldm ""
                local cmd_name=${cur:1} # remove the first ":" symbol from $cur
                if [[ $cur_word_index -eq 1 ]]; then
                    # Command completion
                    # $LETDEV_HOME/list-commands.sh | sed "s|:|$LETDEV_HOME/commands/|" | fzf --reverse --inline-info --tac --preview="$LETDEV_HOME/get-command-variable.sh {} COMMAND_HELP"
                    local selected=$($LETDEV_HOME/completion-output.sh | fzf \
                        --no-sort \
                        --cycle \
                        --reverse \
                        --exact \
                        --inline-info \
                        --query="$cmd_name" \
                        --preview="$LETDEV_HOME/get-command-variable.sh {} COMMAND_HELP" \
                        --bind "tab:reload( LETDEV_HOME='$LETDEV_HOME' $LETDEV_HOME/completion-output.sh )" \
                    )
                    if [[ -n $selected ]]; then
                        READLINE_LINE="$selected"
                        READLINE_POINT=$((${#selected}))
                    fi
                    return 0
                else
                    # Arguments completion
                    # TODO: Implement arguments completion
                    local selected=$($LETDEV_HOME/completion-output.sh | fzf \
                        --no-sort \
                        --cycle \
                        --reverse \
                        --exact \
                        --inline-info \
                        --query=": $cur" \
                        --preview="$LETDEV_HOME/get-command-variable.sh {} COMMAND_HELP" \
                        --bind "tab:reload( LETDEV_HOME='$LETDEV_HOME' $LETDEV_HOME/completion-output.sh )" \
                    )
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


_letdev_tab_handler() {
    _letdev_menu_handler "$@"
}

# _letdev_shift_tab_handler() {
#     _letdev_menu_handler "reversed" "get_history_commands"
# }

# export -f _letdev_shift_tab_handler

_letdev_init_completion() {
    # complete -F _letdev_complete :

    # Bind tab key
    bind -x '"\t": _letdev_tab_handler'

    # Bind shift-tab key 
    # bind -x '"\e[Z": _letdev_shift_tab_handler'
}

_letdev_init_completion

#!/bin/bash

# _letdev_complete() {
#     local cur prev words cword
#     _init_completion || return
#     local cmds=$($LETDEV_HOME/list-commands.sh --with-descriptions)
#     COMPREPLY=($(compgen -W "$(echo "$cmds" | fzf --reverse --inline-info --tac --preview)" -- "$cur"))
# }

_letdev_menu_handler() {
    if [[ -n "$READLINE_LINE" ]]; then
        local left_of_cursor="${READLINE_LINE:0:$READLINE_POINT}"
        local right_of_cursor="${READLINE_LINE:$READLINE_POINT}"

        local before_cursor="${left_of_cursor##* }"
        local after_cursor="${right_of_cursor%% *}"

        local current_word="$before_cursor$after_cursor"

        if [[ "$current_word" =~ ^: ]]; then
            local query="$current_word"

            letdev_storage_set ldm ""

            local selected=$($LETDEV_HOME/completion-output.sh | fzf \
                --no-sort \
                --cycle \
                --reverse \
                --exact \
                --inline-info \
                --query="$query" \
                --preview="$LETDEV_HOME/get-command-variable.sh {} COMMAND_HELP" \
                --bind "tab:reload( LETDEV_HOME='$LETDEV_HOME' $LETDEV_HOME/completion-output.sh )" \
            )
            if [[ -n $selected ]]; then
                local current_word_start=$((READLINE_POINT - ${#before_cursor}))
                READLINE_LINE="${READLINE_LINE:0:$current_word_start}$selected${READLINE_LINE:$((READLINE_POINT + ${#after_cursor}))}"
                READLINE_POINT=$((current_word_start + ${#selected}))
            fi
            return 0
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

#!/bin/bash

_letdev_complete() {
    local cur prev words cword
    _init_completion || return
    local cmds=$($LETDEV_PATH/default --list)
    COMPREPLY=( $(compgen -W "$(echo "$cmds" | fzf --reverse --inline-info --tac)" -- "$cur") )
}

_letdev_tab_complete() {
    if [[ "$READLINE_LINE" =~ ^: ]]; then
        local words=($READLINE_LINE)
        local cur_word_index=$(IFS=" "; set -f; set -- $READLINE_LINE; echo $#)
        local cur=${words[cur_word_index-1]}
        local prev=${words[cur_word_index-2]}
        local cmds=$($LETDEV_PATH/default --list)
        local selected=$(echo "$cmds" | fzf --reverse --inline-info --tac --query="$cur")
        if [[ -n $selected ]]; then
            local cur_length=${#cur}
            READLINE_LINE=${READLINE_LINE:0:$((READLINE_POINT - cur_length))}$selected${READLINE_LINE:$READLINE_POINT}
            READLINE_POINT=$((READLINE_POINT - cur_length + ${#selected}))
        fi
        return 0
    fi

    fzf_bash_completion
}

complete -F _letdev_complete :
bind -x '"\t": _letdev_tab_complete'

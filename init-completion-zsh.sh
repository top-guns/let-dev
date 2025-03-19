# _letdev_command() {
#     echo "letdev_command!!!!!!!"
#     local command_list=$($LETDEV_HOME/list-commands.sh)
#     local -a commands
#     multiline_to_array "$command_list" commands

#     _describe -t commands 'letdev_command commands' commands
# }

# _letdev_command() {
#   if [[ $LBUFFER =~ :[^[:space:]]*$ ]]; then
#     local -a commands_with_prefix
#     commands_with_prefix=(
#       'start:Start the application'
#       'stop:Stop the application'
#       'status:Show the status of the application'
#     )
#     _describe -t commands 'letdev_command commands' commands_with_prefix
#   else
#     local -a commands_without_prefix
#     commands_without_prefix=(
#       'init:Initialize the environment'
#       'deploy:Deploy the application'
#       'update:Update the application'
#     )
#     _describe -t commands 'letdev_command commands' commands_without_prefix
#   fi
# }

# _custom_tab_handler() {
#   if [[ $LBUFFER == :* ]]; then
#     local command=${LBUFFER#:}
#     LBUFFER="letdev_command $command"
#     zle redisplay
#   else
#     zle expand-or-complete
#   fi
# }

# _letdev_command() {
#     echo "letdev_command!!!!!"
#   local curcontext="$curcontext" state line
#   typeset -A opt_args

#   local -a commands
#   commands=(
#     'start:Start the application'
#     'stop:Stop the application'
#     'status:Show the status of the application'
#     'init:Initialize the environment'
#     'deploy:Deploy the application'
#     'update:Update the application'
#   )

#   _describe -t commands 'letdev_command commands' commands
# }

# _custom_tab_handler() {
#   # If the current line starts with a colon, we call the autocomplete function for 'letdev_command'
# #   echo "custom_tab_handler '$LBUFFER'"
#   if [[ $LBUFFER =~ .*:[^\ ]*$ ]]; then
#     # zle complete-word
#     _letdev_command
#     # compadd $(_letdev_command)
#     # zle redisplay
#   else
#     # Otherwise, we call the original tab expansion
#     zle expand-or-complete
#   fi
# }

# _letdev_command() {
#   local -a commands_with_prefix commands_without_prefix
#   commands_with_prefix=(
#     'start:Start the application'
#     'stop:Stop the application'
#     'status:Show the status of the application'
#   )
#   commands_without_prefix=(
#     'init:Initialize the environment'
#     'deploy:Deploy the application'
#     'update:Update the application'
#   )

#   # Проверка, есть ли двоеточие и непустая команда в буфере перед курсором
#   if [[ $LBUFFER =~ .*:[^[:space:]]*$ ]]; then
#     _describe -t commands 'letdev_command commands' commands_with_prefix
#   else
#     _describe -t commands 'letdev_command commands' commands_without_prefix
#   fi
# }

# _letdev_command() {
#   local -a commands_with_prefix
#   commands_with_prefix=(
#     'start:Start the application'
#     'stop:Stop the application'
#     'status:Show the status of the application'
#   )

#   _describe -t commands 'letdev_command commands' commands_with_prefix
# }


_letdev_menu_handler() {
    local left_of_cursor="${LBUFFER:0:$CURSOR}"
    local right_of_cursor="${LBUFFER:$CURSOR}"

    local pre_cursor_word="${left_of_cursor##* }"
    local post_cursor_word="${right_of_cursor%% *}"
    local initial_cursor_position=$((CURSOR - ${#pre_cursor_word}))

    local current_word="${LBUFFER:$initial_cursor_position:${#post_cursor_word}}"

    if [[ "$current_word" = ":"* ]]; then
        local prefix="${current_word%%:*}"
        local query="${current_word#*:}"

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
            LBUFFER="${left_of_cursor:0:initial_cursor_position}$prefix:$selected${right_of_cursor:${#post_cursor_word}}"
            CURSOR=$((initial_cursor_position + ${#prefix} + 1 + ${#selected}))
        fi
    else
        if whence -w fzf-tab-complete >/dev/null; then
            fzf-tab-complete $@
        else
            zle expand-or-complete $@
        fi
    fi
}

_letdev_tab_handler() {
    # _letdev_menu_handler "normal" "list_commands" "--format=command"
    _letdev_menu_handler "$@"
}

# _letdev_shift_tab_handler() {
#     _letdev_menu_handler "reversed" "get_history_commands"
# }

_letdev_init_completion() {
    # alias ld="letdev_command"
    # compdef _letdev_command letdev_command

    # Bind tab key
    zle -N _letdev_tab_handler
    bindkey "^I" _letdev_tab_handler

    # Add letdev_command to the completion list
    # compdef _letdev_command letdev_command
    # compdef _letdev_command :*

    # Bind shift-tab key 
    # zle -N _letdev_shift_tab_handler
    # bindkey "^[[Z" _letdev_shift_tab_handler
}

_letdev_init_completion

# TODO: change it and implement the / trigger behavior
# Disable / trigger continuous completion (used when completing a deep path)
zstyle ':fzf-tab:*' continuous-trigger ''

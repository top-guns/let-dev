# VSCode let-dev theme - simple prompt with PROJECT_NAME support
# Format: ➜  project_name (PROJECT_NAME: branch_name) or ➜  project_name (branch_name)

# Custom git prompt with PROJECT_NAME support
function custom_git_prompt_info() {
local ref
    if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" != "1" ]]; then
        ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
        ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
        local branch_name="${ref#refs/heads/}"
        
        if [[ -n "$PROJECT_NAME" ]]; then
            echo "$PROJECT_NAME: $branch_name"
        else
            echo "$branch_name"
        fi
    fi
}

# Main prompt with arrow, directory and git info
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )%{$reset_color%} "
PROMPT+="%{$fg[cyan]%}%c%{$reset_color%} "
PROMPT+="%{$fg[blue]%}(%{$fg[yellow]%}\$(custom_git_prompt_info)%{$fg[blue]%})%{$reset_color%} "

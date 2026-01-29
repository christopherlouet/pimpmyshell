#!/usr/bin/env bash
# pimpmyshell - fzf integration
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_INTEG_FZF_LOADED:-}" ]] && return 0
_PIMPMYSHELL_INTEG_FZF_LOADED=1

# Skip if fzf is not installed
if ! command -v fzf &>/dev/null; then
    return 0
fi

# Default fzf options
export FZF_DEFAULT_OPTS="
  --height=50%
  --layout=reverse
  --border=rounded
  --info=inline
  --pointer='▶'
  --marker='✓'
  --prompt='❯ '
"

# Use fd if available for faster file search
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v fdfind &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
fi

# Preview with bat (for CTRL+T file preview)
if command -v bat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza --icons --tree --level=1 {} 2>/dev/null'"
elif command -v batcat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'batcat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza --icons --tree --level=1 {} 2>/dev/null'"
fi

# Preview with eza tree (for ALT+C directory preview)
if command -v eza &>/dev/null; then
    export FZF_ALT_C_OPTS="--preview 'eza --icons --tree --level=2 {}'"
fi

# History search options (CTRL+R)
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=up:3:hidden:wrap --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'"

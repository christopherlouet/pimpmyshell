#!/usr/bin/env bash
# pimpmyshell - File listing aliases (eza + bat)
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_ALIASES_FILES_LOADED:-}" ]] && return 0
_PIMPMYSHELL_ALIASES_FILES_LOADED=1

# eza aliases (if eza is available)
if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza -T --icons --level=2'
    alias l='eza -l --icons --group-directories-first'
fi

# bat aliases (if bat/batcat is available)
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
    alias catp='bat'
elif command -v batcat &>/dev/null; then
    alias cat='batcat --paging=never'
    alias catp='batcat'
fi

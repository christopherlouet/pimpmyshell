#!/usr/bin/env bash
# pimpmyshell - tmux integration
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_INTEG_TMUX_LOADED:-}" ]] && return 0
_PIMPMYSHELL_INTEG_TMUX_LOADED=1

# Skip if tmux is not installed
if ! command -v tmux &>/dev/null; then
    return 0
fi

# Tmux plugin configuration for oh-my-zsh
export ZSH_TMUX_AUTOSTART="${PIMPMYSHELL_TMUX_AUTOSTART:-false}"
export ZSH_TMUX_AUTOCONNECT="${PIMPMYSHELL_TMUX_AUTOCONNECT:-true}"
export ZSH_TMUX_AUTOQUIT="${PIMPMYSHELL_TMUX_AUTOQUIT:-false}"

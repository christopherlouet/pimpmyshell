#!/usr/bin/env bash
# pimpmyshell - Navigation aliases
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_ALIASES_NAV_LOADED:-}" ]] && return 0
_PIMPMYSHELL_ALIASES_NAV_LOADED=1

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return 1
}

# Alias for mkcd
take() {
    mkcd "$@"
}

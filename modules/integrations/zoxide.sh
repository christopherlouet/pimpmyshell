#!/usr/bin/env bash
# pimpmyshell - zoxide integration (smarter cd)
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_INTEG_ZOXIDE_LOADED:-}" ]] && return 0
_PIMPMYSHELL_INTEG_ZOXIDE_LOADED=1

# Initialize zoxide if installed
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

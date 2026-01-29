#!/usr/bin/env bash
# pimpmyshell - mise integration (runtime version manager)
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_INTEG_MISE_LOADED:-}" ]] && return 0
_PIMPMYSHELL_INTEG_MISE_LOADED=1

# Activate mise if installed
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi

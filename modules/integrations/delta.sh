#!/usr/bin/env bash
# pimpmyshell - delta integration (git diff pager)
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_INTEG_DELTA_LOADED:-}" ]] && return 0
_PIMPMYSHELL_INTEG_DELTA_LOADED=1

# Configure git to use delta if installed
configure_delta() {
    if ! command -v delta &>/dev/null; then
        return 0
    fi

    if ! command -v git &>/dev/null; then
        return 0
    fi

    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global delta.light false
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default
}

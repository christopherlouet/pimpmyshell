#!/usr/bin/env bash
# pimpmyshell - Git aliases
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_ALIASES_GIT_LOADED:-}" ]] && return 0
_PIMPMYSHELL_ALIASES_GIT_LOADED=1

# Git shortcuts
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias gm='git merge'
alias gr='git rebase'
alias gst='git stash'
alias gstp='git stash pop'
alias gf='git fetch'
alias gcl='git clone'

#!/usr/bin/env bash
# pimpmyshell - Docker aliases
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_ALIASES_DOCKER_LOADED:-}" ]] && return 0
_PIMPMYSHELL_ALIASES_DOCKER_LOADED=1

# Docker shortcuts
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dex='docker exec -it'
alias dlogs='docker logs -f'
alias dimg='docker images'
alias drm='docker rm'
alias drmi='docker rmi'

# Docker Compose shortcuts
alias dcp='docker compose'
alias dcup='docker compose up -d'
alias dcdn='docker compose down'
alias dcps='docker compose ps'
alias dclogs='docker compose logs -f'
alias dcbuild='docker compose build'
alias dcrestart='docker compose restart'

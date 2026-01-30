#!/usr/bin/env bash
# pimpmyshell - Bash completion
# Source this file or add to your .bashrc:
#   source /path/to/pimpmyshell/completions/pimpmyshell.bash
#
# Or copy to /etc/bash_completion.d/pimpmyshell

_pimpmyshell_completions() {
    local cur prev words cword
    _init_completion || return

    # Main commands
    local commands="apply theme tools backup restore doctor wizard profile update version help"

    # Profile subcommands
    local profile_cmds="list create switch delete"

    # Tools subcommands
    local tools_cmds="check install"

    # Get available themes
    _pimpmyshell_themes() {
        local themes_dir="${PIMPMYSHELL_THEMES_DIR:-$HOME/.pimpmyshell/themes}"
        if [[ -d "$themes_dir" ]]; then
            find "$themes_dir" -maxdepth 1 -name "*.yaml" -exec basename {} .yaml \; 2>/dev/null
        fi
    }

    # Get available profiles
    _pimpmyshell_profiles() {
        local profiles_dir="${PIMPMYSHELL_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pimpmyshell}/profiles"
        if [[ -d "$profiles_dir" ]]; then
            for dir in "$profiles_dir"/*/; do
                [[ -d "$dir" ]] && basename "$dir"
            done | grep -v '^current$' 2>/dev/null
        fi
    }

    # Get available backups
    _pimpmyshell_backups() {
        local backups_dir="${PIMPMYSHELL_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/pimpmyshell}/backups"
        if [[ -d "$backups_dir" ]]; then
            find "$backups_dir" -maxdepth 1 -name "*.bak" 2>/dev/null
        fi
    }

    case "${cword}" in
        1)
            # Complete main commands
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            ;;
        2)
            case "${prev}" in
                theme)
                    # Complete theme names and options
                    COMPREPLY=($(compgen -W "$(_pimpmyshell_themes) --list --preview" -- "$cur"))
                    ;;
                tools)
                    # Complete tools subcommands
                    COMPREPLY=($(compgen -W "$tools_cmds" -- "$cur"))
                    ;;
                profile)
                    # Complete profile subcommands
                    COMPREPLY=($(compgen -W "$profile_cmds" -- "$cur"))
                    ;;
                restore)
                    # Complete restore options and backups
                    COMPREPLY=($(compgen -W "--latest $(_pimpmyshell_backups)" -- "$cur"))
                    ;;
                apply)
                    # Complete apply options
                    COMPREPLY=($(compgen -W "--dry-run --no-backup" -- "$cur"))
                    ;;
                *)
                    ;;
            esac
            ;;
        3)
            local cmd="${words[1]}"
            local subcmd="${words[2]}"

            case "$cmd" in
                profile)
                    case "$subcmd" in
                        switch|delete)
                            # Complete profile names
                            COMPREPLY=($(compgen -W "$(_pimpmyshell_profiles)" -- "$cur"))
                            ;;
                        create)
                            # User types profile name
                            COMPREPLY=()
                            ;;
                    esac
                    ;;
            esac
            ;;
    esac

    return 0
}

# Register the completion function
complete -F _pimpmyshell_completions pimpmyshell
complete -F _pimpmyshell_completions pms

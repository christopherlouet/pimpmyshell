#compdef pimpmyshell
# pimpmyshell - Zsh completion
# Source this file or add to your fpath:
#   fpath=(/path/to/pimpmyshell/completions $fpath)
#   autoload -Uz compinit && compinit

_pimpmyshell_themes() {
    local themes_dir="${PIMPMYSHELL_THEMES_DIR:-$HOME/.pimpmyshell/themes}"
    if [[ -d "$themes_dir" ]]; then
        local themes=(${themes_dir}/*.yaml(N:t:r))
        _describe -t themes 'theme' themes
    fi
}

_pimpmyshell_profiles() {
    local profiles_dir="${PIMPMYSHELL_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pimpmyshell}/profiles"
    if [[ -d "$profiles_dir" ]]; then
        local profiles=()
        for dir in "$profiles_dir"/*/; do
            [[ -d "$dir" ]] && profiles+=("$(basename "$dir")")
        done
        profiles=("${(@)profiles:#current}")
        _describe -t profiles 'profile' profiles
    fi
}

_pimpmyshell_backups() {
    local backups_dir="${PIMPMYSHELL_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/pimpmyshell}/backups"
    if [[ -d "$backups_dir" ]]; then
        local backups=(${backups_dir}/*.bak(N))
        _describe -t backups 'backup' backups
    fi
}

_pimpmyshell() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        '(-c --config)'{-c,--config}'[Use custom config file]:file:_files' \
        '(-v --verbose)'{-v,--verbose}'[Enable verbose output]' \
        '(-d --debug)'{-d,--debug}'[Enable debug output]' \
        '(-q --quiet)'{-q,--quiet}'[Suppress non-error output]' \
        '(-h --help)'{-h,--help}'[Show help]' \
        '--version[Show version]' \
        '--dry-run[Show what would be done]' \
        '--no-backup[Skip automatic backup]' \
        '1: :->command' \
        '*: :->args'

    case $state in
        command)
            local commands=(
                'apply:Apply configuration (generate .zshrc, theme, plugins)'
                'theme:Show or change the current theme'
                'tools:Check or install CLI tools'
                'backup:Create a manual backup'
                'restore:Restore from backup'
                'doctor:Run diagnostics on your environment'
                'wizard:Interactive setup wizard'
                'profile:Manage configuration profiles'
                'update:Update pimpmyshell to latest version'
                'version:Show version'
                'help:Show help message'
            )
            _describe -t commands 'command' commands
            ;;

        args)
            case $words[2] in
                theme)
                    if (( CURRENT == 3 )); then
                        local opts=(
                            '--list:List available themes'
                            '--preview:Preview all themes'
                        )
                        _pimpmyshell_themes
                        _describe -t options 'option' opts
                    fi
                    ;;

                tools)
                    if (( CURRENT == 3 )); then
                        local subcmds=(
                            'check:Check installed tools'
                            'install:Install required and recommended tools'
                        )
                        _describe -t subcommands 'subcommand' subcmds
                    fi
                    ;;

                profile)
                    if (( CURRENT == 3 )); then
                        local subcmds=(
                            'list:List configuration profiles'
                            'create:Create a new profile'
                            'switch:Switch to a profile'
                            'delete:Delete a profile'
                        )
                        _describe -t subcommands 'subcommand' subcmds
                    elif (( CURRENT == 4 )); then
                        case $words[3] in
                            switch|delete)
                                _pimpmyshell_profiles
                                ;;
                            create)
                                _message 'Profile name'
                                ;;
                        esac
                    fi
                    ;;

                restore)
                    if (( CURRENT == 3 )); then
                        local opts=('--latest:Restore most recent backup')
                        _pimpmyshell_backups
                        _describe -t options 'option' opts
                    fi
                    ;;

                apply)
                    local opts=(
                        '--dry-run:Preview without applying'
                        '--no-backup:Skip automatic backup'
                    )
                    _describe -t options 'option' opts
                    ;;
            esac
            ;;
    esac
}

_pimpmyshell "$@"

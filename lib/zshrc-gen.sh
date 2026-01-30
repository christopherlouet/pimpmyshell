#!/usr/bin/env bash
# pimpmyshell - .zshrc generation functions
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_ZSHRC_GEN_LOADED:-}" ]] && return 0
_PIMPMYSHELL_ZSHRC_GEN_LOADED=1

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

if [[ -z "${_PIMPMYSHELL_CONFIG_LOADED:-}" ]]; then
    # shellcheck source=./config.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/config.sh"
fi

# -----------------------------------------------------------------------------
# .zshrc Section Generators
# -----------------------------------------------------------------------------

## Generate environment variable exports
## Usage: _generate_env_vars
_generate_env_vars() {
    local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
    # Ensure common tool directories are in PATH
    echo '[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"'
    echo "export ZSH=\"${zsh_dir}\""
    echo "export LANG=\"\${LANG:-en_US.UTF-8}\""
    echo "export EDITOR=\"\${EDITOR:-vim}\""
    echo "export PIMPMYSHELL_CONFIG_FILE=\"\${PIMPMYSHELL_CONFIG_FILE:-${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml}\""
}

## Generate Oh-My-Zsh config (ZSH_THEME, etc.)
## Usage: _generate_omz_config
_generate_omz_config() {
    local prompt_engine
    prompt_engine=$(get_config '.prompt.engine' "$DEFAULT_PROMPT_ENGINE")

    # When using starship or p10k, set ZSH_THEME to empty
    if [[ "$prompt_engine" == "starship" || "$prompt_engine" == "p10k" ]]; then
        echo 'ZSH_THEME=""'
    else
        echo 'ZSH_THEME="robbyrussell"'
    fi

    echo 'DISABLE_AUTO_UPDATE="true"'
    echo 'DISABLE_UNTRACKED_FILES_DIRTY="true"'
}

## Generate plugins=() line for .zshrc
## Usage: _generate_plugins_line
_generate_plugins_line() {
    local all_plugins=""

    # Get ohmyzsh standard plugins
    local omz_plugins
    omz_plugins=$(get_config_list '.plugins.ohmyzsh')
    if [[ -n "$omz_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            if [[ -n "$all_plugins" ]]; then
                all_plugins="${all_plugins} ${plugin}"
            else
                all_plugins="$plugin"
            fi
        done <<< "$omz_plugins"
    fi

    # Get custom plugins
    local custom_plugins
    custom_plugins=$(get_config_list '.plugins.custom')
    if [[ -n "$custom_plugins" ]]; then
        # Check if fzf-tab is explicitly disabled
        local fzf_tab_enabled=true
        if ! config_enabled '.integrations.fzf_tab.enabled'; then
            # Only skip if the key exists and is explicitly false
            local fzf_tab_value
            fzf_tab_value=$(get_config '.integrations.fzf_tab.enabled' "")
            if [[ -n "$fzf_tab_value" ]]; then
                fzf_tab_enabled=false
            fi
        fi

        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            # Skip fzf-tab if disabled in config
            if [[ "$plugin" == "fzf-tab" && "$fzf_tab_enabled" == false ]]; then
                log_verbose "Skipping fzf-tab plugin (disabled in integrations.fzf_tab.enabled)"
                continue
            fi
            if [[ -n "$all_plugins" ]]; then
                all_plugins="${all_plugins} ${plugin}"
            else
                all_plugins="$plugin"
            fi
        done <<< "$custom_plugins"
    fi

    echo "plugins=(${all_plugins})"
}

## Generate alias source lines
## Usage: _generate_aliases
_generate_aliases() {
    local modules_dir="${PIMPMYSHELL_MODULES_DIR:-${PIMPMYSHELL_ROOT}/modules}"

    # Check if aliases are enabled
    if ! config_enabled '.aliases.enabled'; then
        return 0
    fi

    # Get enabled alias groups
    local groups
    groups=$(get_config_list '.aliases.groups')
    if [[ -z "$groups" ]]; then
        return 0
    fi

    while IFS= read -r group; do
        [[ -z "$group" ]] && continue
        local alias_file="${modules_dir}/aliases/${group}.sh"
        if [[ -f "$alias_file" ]]; then
            echo "source \"${alias_file}\""
        else
            echo "# Alias group not found: ${group}"
        fi
    done <<< "$groups"
}

## Generate integration source lines
## Usage: _generate_integrations
_generate_integrations() {
    local modules_dir="${PIMPMYSHELL_MODULES_DIR:-${PIMPMYSHELL_ROOT}/modules}"
    local integrations=("fzf" "mise" "tmux" "zoxide" "delta")
    local output=""

    for integ in "${integrations[@]}"; do
        if config_enabled ".integrations.${integ}.enabled"; then
            local integ_file="${modules_dir}/integrations/${integ}.sh"
            if [[ -f "$integ_file" ]]; then
                if [[ -n "$output" ]]; then
                    output="${output}"$'\n'"source \"${integ_file}\""
                else
                    output="source \"${integ_file}\""
                fi
            fi
        fi
    done

    if [[ -n "$output" ]]; then
        echo "$output"
    fi
}

## Generate eza theme source line
## Usage: _generate_eza_theme
_generate_eza_theme() {
    local eza_theme_file="${PIMPMYSHELL_DATA_DIR}/eza/eza-theme.sh"
    echo "[[ -f \"${eza_theme_file}\" ]] && source \"${eza_theme_file}\""
}

## Generate terminal colors source line
## Usage: _generate_terminal_colors
_generate_terminal_colors() {
    local colors_file="${PIMPMYSHELL_DATA_DIR}/colors/terminal-colors.sh"
    echo "[[ -f \"${colors_file}\" ]] && source \"${colors_file}\""
}

## Generate completions fpath setup
## Usage: _generate_completions
_generate_completions() {
    local completions_dir="${PIMPMYSHELL_ROOT}/completions"
    if [[ -d "$completions_dir" ]]; then
        echo "fpath=(${completions_dir} \$fpath)"
    fi
}

## Generate shell wrapper function that auto-reloads eza/starship on theme switch
## Usage: _generate_shell_wrapper
_generate_shell_wrapper() {
    local eza_theme_file="${PIMPMYSHELL_DATA_DIR}/eza/eza-theme.sh"
    local colors_file="${PIMPMYSHELL_DATA_DIR}/colors/terminal-colors.sh"
    cat <<'WRAPPER'
pimpmyshell() {
    command pimpmyshell "$@"
    local ret=$?
    if [[ $ret -eq 0 && "$1" == "theme" && -n "${2:-}" && "$2" != --* ]]; then
WRAPPER
    echo "        [[ -f \"${eza_theme_file}\" ]] && source \"${eza_theme_file}\""
    echo "        [[ -f \"${colors_file}\" ]] && source \"${colors_file}\""
    cat <<'WRAPPER'
    fi
    return $ret
}
WRAPPER
}

## Generate prompt initialization
## Usage: _generate_prompt_init
_generate_prompt_init() {
    local prompt_engine
    prompt_engine=$(get_config '.prompt.engine' "$DEFAULT_PROMPT_ENGINE")

    case "$prompt_engine" in
        starship)
            echo 'eval "$(starship init zsh)"'
            ;;
        p10k)
            echo '[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh'
            ;;
        none)
            # No prompt engine
            ;;
    esac
}

# -----------------------------------------------------------------------------
# User Custom Section
# -----------------------------------------------------------------------------

## Extract user custom section from existing .zshrc
## Usage: extract_user_custom <file>
## Returns: content between user custom markers (without markers)
extract_user_custom() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    local in_custom=false
    local custom_content=""

    while IFS= read -r line; do
        if [[ "$line" == *">>> user custom >>>"* ]]; then
            in_custom=true
            continue
        fi
        if [[ "$line" == *"<<< user custom <<<"* ]]; then
            in_custom=false
            continue
        fi
        if [[ "$in_custom" == true ]]; then
            if [[ -n "$custom_content" ]]; then
                custom_content="${custom_content}"$'\n'"${line}"
            else
                custom_content="$line"
            fi
        fi
    done < "$file"

    if [[ -n "$custom_content" ]]; then
        echo "$custom_content"
    fi
}

# -----------------------------------------------------------------------------
# Template Processing
# -----------------------------------------------------------------------------

## Replace a placeholder in content using awk-safe escaping
## Usage: _replace_placeholder <placeholder> <replacement> <<< "$content"
_replace_placeholder() {
    local placeholder="$1"
    local replacement="$2"
    local content
    content=$(cat)
    # Use awk for safe replacement (handles multi-line values on all platforms)
    # Pass replacement via environment variable to avoid BSD awk -v newline issues
    _AWK_REP="$replacement" awk -v pat="{${placeholder}}" '{
        idx = index($0, pat)
        while (idx > 0) {
            $0 = substr($0, 1, idx-1) ENVIRON["_AWK_REP"] substr($0, idx+length(pat))
            idx = index($0, pat)
        }
        print
    }' <<< "$content"
}

# -----------------------------------------------------------------------------
# Orchestration
# -----------------------------------------------------------------------------

## Generate complete .zshrc from template and config
## Usage: generate_zshrc <output_file>
generate_zshrc() {
    local output_file="$1"
    local template_file="${PIMPMYSHELL_TEMPLATES_DIR}/zshrc.template"

    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template_file"
        return 1
    fi

    # Extract existing user custom content before overwriting
    local user_custom=""
    if [[ -f "$output_file" ]]; then
        user_custom=$(extract_user_custom "$output_file")
    fi

    # Get theme name
    local theme_name
    theme_name=$(get_config '.theme' "$DEFAULT_THEME")

    # Generate all sections
    local env_vars omz_config plugins_line completions aliases integrations eza_theme terminal_colors prompt_init
    env_vars=$(_generate_env_vars)
    omz_config=$(_generate_omz_config)
    plugins_line=$(_generate_plugins_line)
    completions=$(_generate_completions)
    aliases=$(_generate_aliases)
    integrations=$(_generate_integrations)
    terminal_colors=$(_generate_terminal_colors)
    eza_theme=$(_generate_eza_theme)
    local shell_wrapper
    shell_wrapper=$(_generate_shell_wrapper)
    prompt_init=$(_generate_prompt_init)

    # Read template and replace placeholders using awk (safe with special chars)
    local content
    content=$(<"$template_file")
    content=$(echo "$content" | _replace_placeholder "VERSION" "$PIMPMYSHELL_VERSION")
    content=$(echo "$content" | _replace_placeholder "DATE" "$(date '+%Y-%m-%d %H:%M:%S')")
    content=$(echo "$content" | _replace_placeholder "THEME" "$theme_name")
    content=$(echo "$content" | _replace_placeholder "ENV_VARS" "$env_vars")
    content=$(echo "$content" | _replace_placeholder "OMZ_CONFIG" "$omz_config")
    content=$(echo "$content" | _replace_placeholder "PLUGINS" "$plugins_line")
    content=$(echo "$content" | _replace_placeholder "COMPLETIONS" "$completions")
    content=$(echo "$content" | _replace_placeholder "ALIASES" "$aliases")
    content=$(echo "$content" | _replace_placeholder "INTEGRATIONS" "$integrations")
    content=$(echo "$content" | _replace_placeholder "TERMINAL_COLORS" "$terminal_colors")
    content=$(echo "$content" | _replace_placeholder "EZA_THEME" "$eza_theme")
    content=$(echo "$content" | _replace_placeholder "SHELL_WRAPPER" "$shell_wrapper")
    content=$(echo "$content" | _replace_placeholder "PROMPT_INIT" "$prompt_init")
    content=$(echo "$content" | _replace_placeholder "USER_CUSTOM" "$user_custom")

    # Ensure output directory exists
    mkdir -p "$(dirname "$output_file")"

    # Write output
    echo "$content" > "$output_file"

    log_verbose "Generated .zshrc: $output_file"
    return 0
}

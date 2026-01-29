#!/usr/bin/env bash
# pimpmyshell - Configuration parsing and access
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_CONFIG_LOADED:-}" ]] && return 0
_PIMPMYSHELL_CONFIG_LOADED=1

# Ensure core is loaded
if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

readonly DEFAULT_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
readonly DEFAULT_THEME="cyberpunk"
readonly DEFAULT_FRAMEWORK="ohmyzsh"
readonly DEFAULT_PROMPT_ENGINE="starship"

# Valid values for validation
readonly VALID_FRAMEWORKS=("ohmyzsh" "prezto" "none")
readonly VALID_PROMPT_ENGINES=("starship" "p10k" "none")
readonly VALID_THEMES=("cyberpunk" "matrix" "dracula" "catppuccin" "nord" "gruvbox" "tokyo-night")

# -----------------------------------------------------------------------------
# YAML Parsing
# -----------------------------------------------------------------------------

## Check if yq is available and which version
## Returns: "go" for Go version, "python" for Python version, "" if not found
detect_yq_version() {
    if ! check_command yq; then
        echo ""
        return
    fi

    # Go version: "yq (https://github.com/mikefarah/yq/) version v4.x.x"
    # Python version: "yq 2.x.x"
    if yq --version 2>&1 | grep -q "mikefarah"; then
        echo "go"
    elif yq --version 2>&1 | grep -qE "^yq [0-9]"; then
        echo "python"
    else
        echo "go"  # Assume Go version for newer installations
    fi
}

## Require yq to be installed
## Exits with error if yq is not available
require_yq() {
    if ! check_command yq; then
        log_error "yq is required but not installed."
        log_error ""
        log_error "Install yq (Go version recommended):"
        log_error "  macOS:   brew install yq"
        log_error "  Linux:   sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
        log_error "  Snap:    sudo snap install yq"
        log_error ""
        log_error "More info: https://github.com/mikefarah/yq"
        return 1
    fi
}

## Get a value from YAML file using yq
## Usage: yq_get <file> <path>
## Example: yq_get config.yaml '.theme'
yq_get() {
    local file="$1"
    local path="$2"

    if [[ ! -f "$file" ]]; then
        log_error "Config file not found: $file"
        return 1
    fi

    require_yq || return 1

    local yq_type
    yq_type=$(detect_yq_version)

    local result
    case "$yq_type" in
        go)
            result=$(yq eval "$path" "$file" 2>/dev/null)
            if [[ "$result" == "null" || -z "$result" ]]; then
                echo ""
            else
                echo "$result"
            fi
            ;;
        python)
            result=$(yq -r "$path" "$file" 2>/dev/null)
            if [[ "$result" == "null" || -z "$result" ]]; then
                echo ""
            else
                echo "$result"
            fi
            ;;
        *)
            log_error "yq is required for YAML parsing"
            return 1
            ;;
    esac
}

## Get a config value with default fallback
## Usage: get_config <path> [default]
get_config() {
    local path="$1"
    local default="${2:-}"
    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
    local value

    value=$(yq_get "$config_file" "$path")

    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

## Check if a config path is enabled (true/yes/1)
## Usage: config_enabled <path>
config_enabled() {
    local path="$1"
    local value
    value=$(get_config "$path" "false")
    value=$(to_lower "$value")

    [[ "$value" == "true" || "$value" == "yes" || "$value" == "1" ]]
}

## Get a list of values from YAML
## Usage: get_config_list <path>
## Returns: One item per line
get_config_list() {
    local path="$1"
    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    require_yq || return 1

    local yq_type
    yq_type=$(detect_yq_version)

    local result
    case "$yq_type" in
        go)
            result=$(yq eval "${path}[]" "$config_file" 2>/dev/null)
            ;;
        python)
            result=$(yq -r "${path}[]" "$config_file" 2>/dev/null)
            ;;
        *)
            return 1
            ;;
    esac

    # Filter out null/empty
    if [[ -n "$result" && "$result" != "null" ]]; then
        echo "$result"
    fi
}

# -----------------------------------------------------------------------------
# .zshrc Generation
# -----------------------------------------------------------------------------

## Generate environment variable exports
## Usage: _generate_env_vars
_generate_env_vars() {
    local zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
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
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
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

## Replace a placeholder in content using sed-safe escaping
## Usage: _replace_placeholder <placeholder> <replacement> <<< "$content"
_replace_placeholder() {
    local placeholder="$1"
    local replacement="$2"
    local content
    content=$(cat)
    # Use awk for safe replacement (no special char issues)
    echo "$content" | awk -v pat="{${placeholder}}" -v rep="$replacement" '{
        idx = index($0, pat)
        while (idx > 0) {
            $0 = substr($0, 1, idx-1) rep substr($0, idx+length(pat))
            idx = index($0, pat)
        }
        print
    }'
}

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
    local env_vars omz_config plugins_line aliases integrations eza_theme prompt_init
    env_vars=$(_generate_env_vars)
    omz_config=$(_generate_omz_config)
    plugins_line=$(_generate_plugins_line)
    aliases=$(_generate_aliases)
    integrations=$(_generate_integrations)
    eza_theme=$(_generate_eza_theme)
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
    content=$(echo "$content" | _replace_placeholder "ALIASES" "$aliases")
    content=$(echo "$content" | _replace_placeholder "INTEGRATIONS" "$integrations")
    content=$(echo "$content" | _replace_placeholder "EZA_THEME" "$eza_theme")
    content=$(echo "$content" | _replace_placeholder "PROMPT_INIT" "$prompt_init")
    content=$(echo "$content" | _replace_placeholder "USER_CUSTOM" "$user_custom")

    # Ensure output directory exists
    mkdir -p "$(dirname "$output_file")"

    # Write output
    echo "$content" > "$output_file"

    log_verbose "Generated .zshrc: $output_file"
    return 0
}

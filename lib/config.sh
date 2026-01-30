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

# Ensure yq-utils is loaded
if [[ -z "${_PIMPMYSHELL_YQ_UTILS_LOADED:-}" ]]; then
    # shellcheck source=./yq-utils.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/yq-utils.sh"
fi

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

readonly DEFAULT_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
# shellcheck disable=SC2034
readonly DEFAULT_THEME="cyberpunk"
# shellcheck disable=SC2034
readonly DEFAULT_FRAMEWORK="ohmyzsh"
# shellcheck disable=SC2034
readonly DEFAULT_PROMPT_ENGINE="starship"

# Valid values for validation (used by validation.sh)
# shellcheck disable=SC2034
readonly VALID_FRAMEWORKS=("ohmyzsh" "prezto" "none")
# shellcheck disable=SC2034
readonly VALID_PROMPT_ENGINES=("starship" "p10k" "none")
# shellcheck disable=SC2034
readonly VALID_THEMES=("cyberpunk" "matrix" "dracula" "catppuccin" "nord" "gruvbox" "tokyo-night")

# -----------------------------------------------------------------------------
# YAML Parsing (delegates to yq-utils.sh)
# -----------------------------------------------------------------------------

## Get a value from YAML file using yq
## Usage: yq_get <file> <path>
## Example: yq_get config.yaml '.theme'
yq_get() {
    _require_args "yq_get" 2 $# || return 1
    yq_eval "$@"
}

## Get a config value with default fallback
## Usage: get_config <path> [default]
get_config() {
    _require_args "get_config" 1 $# || return 1
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

## Set a value in the YAML config file using yq
## Usage: set_config <path> <value>
## Example: set_config '.theme' 'dracula'
set_config() {
    _require_args "set_config" 2 $# || return 1
    local path="$1"
    local value="$2"
    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"

    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    yq_write "$config_file" "$path" "$value" || return 1

    log_verbose "Config updated: ${path} = ${value}"
    return 0
}

## Check if a config path is enabled (true/yes/1)
## Usage: config_enabled <path>
config_enabled() {
    _require_args "config_enabled" 1 $# || return 1
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
    _require_args "get_config_list" 1 $# || return 1
    local path="$1"
    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"

    yq_eval_list "$config_file" "$path"
}


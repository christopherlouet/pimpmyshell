#!/usr/bin/env bash
# pimpmyshell - Configuration validation functions
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_VALIDATION_LOADED:-}" ]] && return 0
_PIMPMYSHELL_VALIDATION_LOADED=1

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

# Ensure core is loaded
if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

# Ensure config is loaded
if [[ -z "${_PIMPMYSHELL_CONFIG_LOADED:-}" ]]; then
    # shellcheck source=./config.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/config.sh"
fi

# -----------------------------------------------------------------------------
# YAML Syntax Validation
# -----------------------------------------------------------------------------

## Validate YAML syntax using yq
## Usage: validate_yaml_syntax <config_file>
## Returns: 0 if valid, 1 if invalid
validate_yaml_syntax() {
    local config_file="$1"

    # Check arguments
    if [[ -z "$config_file" ]]; then
        log_error "validate_yaml_syntax: No config file specified"
        return 1
    fi

    # Check file exists
    if [[ ! -f "$config_file" ]]; then
        log_error "validate_yaml_syntax: Config file not found: $config_file"
        return 1
    fi

    # Empty file is valid YAML
    if [[ ! -s "$config_file" ]]; then
        log_debug "Config file is empty, considered valid"
        return 0
    fi

    # Require yq for syntax check
    if ! check_command yq; then
        log_warn "yq not available, skipping YAML syntax validation"
        return 0
    fi

    local yq_type
    yq_type=$(detect_yq_version)

    local validation_output
    case "$yq_type" in
        go)
            validation_output=$(yq eval '.' "$config_file" 2>&1)
            ;;
        python)
            validation_output=$(yq '.' "$config_file" 2>&1)
            ;;
        *)
            return 0
            ;;
    esac

    local status=$?
    if [[ $status -ne 0 ]]; then
        log_error "Invalid YAML syntax in $config_file"
        if [[ -n "$validation_output" ]]; then
            log_error "$validation_output"
        fi
        return 1
    fi

    log_debug "YAML syntax is valid: $config_file"
    return 0
}

# -----------------------------------------------------------------------------
# Config Values Validation
# -----------------------------------------------------------------------------

## Validate config values (theme exists, framework valid, etc.)
## Usage: validate_config_values <config_file>
## Returns: 0 if valid (warnings are not errors), 1 on critical issues
validate_config_values() {
    local config_file="$1"
    local warnings=0

    if [[ -z "$config_file" || ! -f "$config_file" ]]; then
        log_error "validate_config_values: Config file not found"
        return 1
    fi

    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    # Validate theme
    local theme
    theme=$(yq_get "$config_file" '.theme')
    if [[ -n "$theme" ]]; then
        local themes_dir="${PIMPMYSHELL_THEMES_DIR:-${PIMPMYSHELL_ROOT:-}/themes}"
        local theme_file="${themes_dir}/${theme}.yaml"
        if [[ ! -f "$theme_file" ]]; then
            # Also check against known themes list
            if ! array_contains "$theme" "${VALID_THEMES[@]}"; then
                log_warn "Unknown theme: '$theme'. Available themes: ${VALID_THEMES[*]}"
                ((warnings++))
            fi
        fi
    fi

    # Validate framework
    local framework
    framework=$(yq_get "$config_file" '.shell.framework')
    if [[ -n "$framework" ]]; then
        if ! array_contains "$framework" "${VALID_FRAMEWORKS[@]}"; then
            log_warn "Unknown framework: '$framework'. Valid options: ${VALID_FRAMEWORKS[*]}"
            ((warnings++))
        fi
    fi

    # Validate prompt engine
    local prompt_engine
    prompt_engine=$(yq_get "$config_file" '.prompt.engine')
    if [[ -n "$prompt_engine" ]]; then
        if ! array_contains "$prompt_engine" "${VALID_PROMPT_ENGINES[@]}"; then
            log_warn "Unknown prompt engine: '$prompt_engine'. Valid options: ${VALID_PROMPT_ENGINES[*]}"
            ((warnings++))
        fi
    fi

    if [[ $warnings -gt 0 ]]; then
        log_warn "Found $warnings warning(s) in configuration"
    fi

    return 0
}

# -----------------------------------------------------------------------------
# Orchestration
# -----------------------------------------------------------------------------

## Full config validation
## Usage: validate_config [config_file]
## Returns: 0 if valid, 1 if critical errors
validate_config() {
    local config_file="${1:-${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}}"

    # Check file exists
    if [[ -z "$config_file" ]]; then
        log_error "Config file not found: no path specified"
        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # Step 1: Validate YAML syntax
    if ! validate_yaml_syntax "$config_file"; then
        log_error "YAML syntax validation failed"
        return 1
    fi

    # Step 2: Validate config values (warnings only, not fatal)
    validate_config_values "$config_file"

    log_debug "Configuration validated: $config_file"
    return 0
}

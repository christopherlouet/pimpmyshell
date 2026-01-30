#!/usr/bin/env bash
# pimpmyshell - Centralized yq YAML parsing utilities
# https://github.com/christopherlouet/pimpmyshell
#
# Provides a single abstraction over Go yq and Python yq versions,
# eliminating the need for go/python branching in every caller.

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_YQ_UTILS_LOADED:-}" ]] && return 0
_PIMPMYSHELL_YQ_UTILS_LOADED=1

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

# -----------------------------------------------------------------------------
# yq Version Detection
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

# -----------------------------------------------------------------------------
# yq Evaluation Wrappers
# -----------------------------------------------------------------------------

## Evaluate a yq expression on a file (single value)
## Handles go/python version transparently
## Usage: yq_eval <file> <path>
## Returns: the value, or empty string if null/missing
yq_eval() {
    local file="$1"
    local path="$2"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    require_yq || return 1

    local yq_type result
    yq_type=$(detect_yq_version)

    case "$yq_type" in
        go)
            result=$(yq eval "$path" "$file" 2>/dev/null)
            ;;
        python)
            result=$(yq -r "$path" "$file" 2>/dev/null)
            ;;
        *)
            log_error "yq is required for YAML parsing"
            return 1
            ;;
    esac

    if [[ "$result" == "null" || -z "$result" ]]; then
        echo ""
    else
        echo "$result"
    fi
}

## Evaluate a yq list expression on a file
## Handles go/python version transparently
## Usage: yq_eval_list <file> <path>
## Returns: one item per line, or empty if null/missing
yq_eval_list() {
    local file="$1"
    local path="$2"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    require_yq || return 1

    local yq_type result
    yq_type=$(detect_yq_version)

    case "$yq_type" in
        go)
            result=$(yq eval "${path}[]" "$file" 2>/dev/null)
            ;;
        python)
            result=$(yq -r "${path}[]" "$file" 2>/dev/null)
            ;;
        *)
            return 1
            ;;
    esac

    if [[ -n "$result" && "$result" != "null" ]]; then
        echo "$result"
    fi
}

## Write a value to a YAML file
## Handles go/python version transparently
## Usage: yq_write <file> <path> <value>
yq_write() {
    local file="$1"
    local path="$2"
    local value="$3"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    require_yq || return 1

    local yq_type
    yq_type=$(detect_yq_version)

    case "$yq_type" in
        go)
            yq eval "${path} = \"${value}\"" -i "$file" 2>/dev/null
            ;;
        python)
            yq -y --in-place "${path} = \"${value}\"" "$file" 2>/dev/null
            ;;
        *)
            log_error "yq is required to update YAML"
            return 1
            ;;
    esac
}

## Validate YAML syntax
## Handles go/python version transparently
## Usage: yq_validate <file>
## Returns: 0 if valid, 1 if invalid
yq_validate() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    if ! check_command yq; then
        log_warn "yq not available, skipping YAML validation"
        return 0
    fi

    local yq_type validation_output
    yq_type=$(detect_yq_version)

    case "$yq_type" in
        go)
            validation_output=$(yq eval '.' "$file" 2>&1)
            ;;
        python)
            validation_output=$(yq '.' "$file" 2>&1)
            ;;
        *)
            return 0
            ;;
    esac

    local status=$?
    if [[ $status -ne 0 ]]; then
        log_error "Invalid YAML syntax in $file"
        if [[ -n "$validation_output" ]]; then
            log_error "$validation_output"
        fi
        return 1
    fi

    return 0
}

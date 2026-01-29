#!/usr/bin/env bash
# pimpmyshell - Profile management
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_PROFILES_LOADED:-}" ]] && return 0
_PIMPMYSHELL_PROFILES_LOADED=1

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
# Constants
# -----------------------------------------------------------------------------

PIMPMYSHELL_PROFILES_DIR="${PIMPMYSHELL_CONFIG_DIR}/profiles"

# -----------------------------------------------------------------------------
# Validation
# -----------------------------------------------------------------------------

## Validate a profile name
## Usage: is_valid_profile_name <name>
## Returns: 0 if valid, 1 if not
is_valid_profile_name() {
    local name="$1"

    # Reject empty
    [[ -z "$name" ]] && return 1

    # Reject reserved name
    [[ "$name" == "current" ]] && return 1

    # Reject path traversal and slashes
    [[ "$name" == *".."* ]] && return 1
    [[ "$name" == *"/"* ]] && return 1

    # Only allow alphanumeric, dash, underscore
    [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || return 1

    return 0
}

# -----------------------------------------------------------------------------
# Directory Management
# -----------------------------------------------------------------------------

## Initialize profiles directory structure
## Usage: init_profiles
init_profiles() {
    mkdir -p "${PIMPMYSHELL_PROFILES_DIR}"

    # Create default profile if it doesn't exist
    if [[ ! -d "${PIMPMYSHELL_PROFILES_DIR}/default" ]]; then
        mkdir -p "${PIMPMYSHELL_PROFILES_DIR}/default"
    fi

    # Create current symlink if it doesn't exist
    if [[ ! -L "${PIMPMYSHELL_PROFILES_DIR}/current" ]]; then
        ln -s "default" "${PIMPMYSHELL_PROFILES_DIR}/current"
    fi
}

# -----------------------------------------------------------------------------
# Profile Operations
# -----------------------------------------------------------------------------

## List available profiles
## Usage: list_profiles
## Returns: one profile name per line
list_profiles() {
    local profiles_dir="${PIMPMYSHELL_PROFILES_DIR}"

    [[ ! -d "$profiles_dir" ]] && return 0

    local entry
    for entry in "${profiles_dir}"/*/; do
        [[ ! -d "$entry" ]] && continue
        local name
        name=$(basename "$entry")
        # Skip the current symlink
        [[ "$name" == "current" ]] && continue
        echo "$name"
    done
}

## Check if a profile exists
## Usage: profile_exists <name>
## Returns: 0 if exists, 1 if not
profile_exists() {
    local name="$1"
    [[ -d "${PIMPMYSHELL_PROFILES_DIR}/${name}" ]]
}

## Get the current active profile name
## Usage: get_current_profile
## Returns: profile name on stdout
get_current_profile() {
    local current_link="${PIMPMYSHELL_PROFILES_DIR}/current"

    if [[ -L "$current_link" ]]; then
        readlink "$current_link"
    else
        echo "default"
    fi
}

## Create a new profile
## Usage: create_profile <name>
## Copies config from current profile
create_profile() {
    local name="$1"

    # Validate name
    if ! is_valid_profile_name "$name"; then
        log_error "Invalid profile name: '${name}'"
        return 1
    fi

    # Check for duplicate
    if profile_exists "$name"; then
        log_error "Profile already exists: $name"
        return 1
    fi

    local profile_dir="${PIMPMYSHELL_PROFILES_DIR}/${name}"
    mkdir -p "$profile_dir"

    # Copy config from current profile if it exists
    local current
    current=$(get_current_profile)
    local current_config="${PIMPMYSHELL_PROFILES_DIR}/${current}/pimpmyshell.yaml"
    if [[ -f "$current_config" ]]; then
        cp "$current_config" "${profile_dir}/pimpmyshell.yaml"
    fi

    log_success "Profile created: $name"
    return 0
}

## Switch to a different profile
## Usage: switch_profile <name>
switch_profile() {
    local name="$1"

    if ! profile_exists "$name"; then
        log_error "Profile not found: $name"
        return 1
    fi

    local current_link="${PIMPMYSHELL_PROFILES_DIR}/current"

    # Remove existing symlink and create new one
    rm -f "$current_link"
    ln -s "$name" "$current_link"

    log_success "Switched to profile: $name"
    return 0
}

## Delete a profile
## Usage: delete_profile <name>
delete_profile() {
    local name="$1"

    # Cannot delete default
    if [[ "$name" == "default" ]]; then
        log_error "Cannot delete the default profile"
        return 1
    fi

    # Check exists
    if ! profile_exists "$name"; then
        log_error "Profile not found: $name"
        return 1
    fi

    # Cannot delete active profile
    local current
    current=$(get_current_profile)
    if [[ "$current" == "$name" ]]; then
        log_error "Cannot delete the active profile: $name"
        log_info "Switch to another profile first: pimpmyshell profile switch <other>"
        return 1
    fi

    rm -rf "${PIMPMYSHELL_PROFILES_DIR:?}/${name}"
    log_success "Profile deleted: $name"
    return 0
}

# -----------------------------------------------------------------------------
# Config Path Helpers
# -----------------------------------------------------------------------------

## Get config file path for a profile
## Usage: get_profile_config_path <name>
## Returns: path on stdout
get_profile_config_path() {
    local name="$1"

    if ! profile_exists "$name"; then
        log_error "Profile not found: $name"
        return 1
    fi

    echo "${PIMPMYSHELL_PROFILES_DIR}/${name}/pimpmyshell.yaml"
}

## Get config file path for the active profile
## Usage: get_active_config_path
## Returns: path on stdout
get_active_config_path() {
    local current
    current=$(get_current_profile)
    echo "${PIMPMYSHELL_PROFILES_DIR}/${current}/pimpmyshell.yaml"
}

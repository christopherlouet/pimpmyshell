#!/usr/bin/env bash
# pimpmyshell - Distribution detection and privilege helpers
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_DISTRO_LOADED:-}" ]] && return 0
_PIMPMYSHELL_DISTRO_LOADED=1

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

# -----------------------------------------------------------------------------
# Distribution Detection
# -----------------------------------------------------------------------------

## Read a field from /etc/os-release
## Usage: _read_os_release_field <field_name> [os_release_path]
_read_os_release_field() {
    local field="$1"
    local os_release="${2:-/etc/os-release}"

    if [[ ! -f "$os_release" ]]; then
        echo ""
        return
    fi

    local value
    value=$(grep "^${field}=" "$os_release" 2>/dev/null | head -1 | cut -d= -f2-)
    # Strip surrounding quotes (double or single)
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
    echo "$value"
}

## Get the distribution ID (e.g. ubuntu, fedora, arch, alpine, opensuse-tumbleweed)
## Usage: get_distro_id [os_release_path]
## Returns: distro ID or "unknown"
get_distro_id() {
    local os_release="${1:-/etc/os-release}"

    local id
    id=$(_read_os_release_field "ID" "$os_release")

    if [[ -n "$id" ]]; then
        echo "$id"
    else
        echo "unknown"
    fi
}

## Get the distribution family (debian, fedora, arch, suse, alpine)
## Usage: get_distro_family [os_release_path]
## Returns: family name or "unknown"
get_distro_family() {
    local os_release="${1:-/etc/os-release}"

    local id
    id=$(get_distro_id "$os_release")

    local id_like
    id_like=$(_read_os_release_field "ID_LIKE" "$os_release")

    # Check ID first, then ID_LIKE for family mapping
    local all_ids="$id $id_like"

    case "$all_ids" in
        *debian*|*ubuntu*)
            echo "debian"
            ;;
        *fedora*|*rhel*|*centos*|*rocky*|*alma*)
            echo "fedora"
            ;;
        *arch*|*manjaro*|*endeavouros*)
            echo "arch"
            ;;
        *suse*)
            echo "suse"
            ;;
        *alpine*)
            echo "alpine"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

## Get the distribution pretty name for display
## Usage: get_distro_pretty [os_release_path]
## Returns: pretty name or "unknown"
get_distro_pretty() {
    local os_release="${1:-/etc/os-release}"

    local pretty
    pretty=$(_read_os_release_field "PRETTY_NAME" "$os_release")

    if [[ -n "$pretty" ]]; then
        echo "$pretty"
    else
        echo "unknown"
    fi
}

# -----------------------------------------------------------------------------
# Privilege Helpers
# -----------------------------------------------------------------------------

## Run a command with elevated privileges if needed
## Skips sudo when already running as root (uid=0)
## Set PIMPMYSHELL_SKIP_SUDO=1 to bypass sudo (for testing or containers)
## Usage: run_privileged <command> [args...]
run_privileged() {
    if [[ $# -eq 0 ]]; then
        log_error "run_privileged: no command specified"
        return 1
    fi

    if [[ -n "${PIMPMYSHELL_SKIP_SUDO:-}" ]] || [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

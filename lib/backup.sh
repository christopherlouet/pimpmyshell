#!/usr/bin/env bash
# pimpmyshell - Backup and restore functions
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_BACKUP_LOADED:-}" ]] && return 0
_PIMPMYSHELL_BACKUP_LOADED=1

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

PIMPMYSHELL_BACKUP_DIR="${PIMPMYSHELL_DATA_DIR}/backups"
readonly PIMPMYSHELL_BACKUP_RETENTION="${PIMPMYSHELL_BACKUP_RETENTION:-10}"

# -----------------------------------------------------------------------------
# Backup Functions
# -----------------------------------------------------------------------------

## Create a backup of a file with timestamp
## Usage: backup_file <file_path>
## Returns: path to backup file (empty if no file to backup)
backup_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_debug "backup_file: No file to backup: $file"
        echo ""
        return 0
    fi

    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"

    local base
    base=$(basename "$file")
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${PIMPMYSHELL_BACKUP_DIR}/${base}.${timestamp}.bak"

    if cp "$file" "$backup_path"; then
        log_verbose "Created backup: $backup_path"
        echo "$backup_path"
        return 0
    else
        log_error "Failed to create backup of $file"
        return 1
    fi
}

## Restore a file from backup
## Usage: restore_file <backup_path> <target_path>
restore_file() {
    local backup_path="$1"
    local target_path="$2"

    if [[ ! -f "$backup_path" ]]; then
        log_error "Backup file not found: $backup_path"
        return 1
    fi

    local target_dir
    target_dir=$(dirname "$target_path")
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi

    if cp "$backup_path" "$target_path"; then
        log_success "Restored $target_path from backup"
        return 0
    else
        log_error "Failed to restore from backup: $backup_path"
        return 1
    fi
}

## List available backups
## Usage: list_backups [filter]
list_backups() {
    local filter="${1:-}"

    if [[ ! -d "$PIMPMYSHELL_BACKUP_DIR" ]]; then
        return 0
    fi

    local backups
    if [[ -n "$filter" ]]; then
        backups=$(ls -1t "$PIMPMYSHELL_BACKUP_DIR"/*"$filter"*.bak 2>/dev/null || true)
    else
        backups=$(ls -1t "$PIMPMYSHELL_BACKUP_DIR"/*.bak 2>/dev/null || true)
    fi

    if [[ -n "$backups" ]]; then
        echo "$backups"
    fi
    return 0
}

## Get the most recent backup for a file
## Usage: get_latest_backup <filename>
get_latest_backup() {
    local filename="$1"

    if [[ ! -d "$PIMPMYSHELL_BACKUP_DIR" ]]; then
        echo ""
        return 0
    fi

    local latest
    latest=$(ls -1t "$PIMPMYSHELL_BACKUP_DIR"/"$filename".*.bak 2>/dev/null | head -1)

    if [[ -n "$latest" && -f "$latest" ]]; then
        echo "$latest"
    else
        echo ""
    fi
    return 0
}

## Clean up old backups, keeping only the most recent N
## Usage: cleanup_old_backups [keep_count]
cleanup_old_backups() {
    local keep_count="${1:-$PIMPMYSHELL_BACKUP_RETENTION}"

    if [[ ! -d "$PIMPMYSHELL_BACKUP_DIR" ]]; then
        return 0
    fi

    local backup_files=()
    while IFS= read -r file; do
        [[ -n "$file" ]] && backup_files+=("$file")
    done < <(ls -1t "$PIMPMYSHELL_BACKUP_DIR"/*.bak 2>/dev/null || true)

    local total=${#backup_files[@]}
    if [[ $total -le $keep_count ]]; then
        return 0
    fi

    local removed=0
    for ((i = keep_count; i < total; i++)); do
        local file="${backup_files[$i]}"
        if [[ -f "$file" ]]; then
            rm -f "$file"
            ((removed++))
        fi
    done

    log_verbose "Cleaned up $removed old backups"
    return 0
}

## Backup files before apply (.zshrc, starship.toml, pimpmyshell.yaml)
## Usage: backup_before_apply
backup_before_apply() {
    local zshrc="${HOME}/.zshrc"
    local starship="${STARSHIP_CONFIG:-${HOME}/.config/starship.toml}"
    local config="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    if [[ -f "$zshrc" ]]; then
        backup_file "$zshrc"
    fi

    if [[ -f "$starship" ]]; then
        backup_file "$starship"
    fi

    if [[ -f "$config" ]]; then
        backup_file "$config"
    fi

    return 0
}

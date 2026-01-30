#!/usr/bin/env bats
# pimpmyshell - Tests for lib/backup.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME/.config"

    # Load libs
    load_lib 'core'
    load_lib 'backup'
}

# =============================================================================
# Guard
# =============================================================================

@test "backup.sh sets _PIMPMYSHELL_BACKUP_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_BACKUP_LOADED:-}" ]]
}

# =============================================================================
# Constants
# =============================================================================

@test "BACKUP_DIR is set" {
    [[ -n "$PIMPMYSHELL_BACKUP_DIR" ]]
}

@test "BACKUP_RETENTION is set to 10" {
    [[ "$PIMPMYSHELL_BACKUP_RETENTION" -eq 10 ]]
}

# =============================================================================
# backup_file
# =============================================================================

@test "backup_file creates a timestamped copy" {
    local src="${PIMPMYSHELL_TEST_DIR}/testfile.txt"
    echo "hello backup" > "$src"

    run backup_file "$src"
    assert_success
    # Output should contain the backup path
    [[ -n "$output" ]]
    # The backup file should exist
    [[ -f "$output" ]]
}

@test "backup_file creates file in BACKUP_DIR" {
    local src="${PIMPMYSHELL_TEST_DIR}/testfile.txt"
    echo "backup content" > "$src"

    run backup_file "$src"
    assert_success
    assert_output_contains "$PIMPMYSHELL_BACKUP_DIR"
}

@test "backup_file preserves file content" {
    local src="${PIMPMYSHELL_TEST_DIR}/testfile.txt"
    echo "important content" > "$src"

    local backup_path
    backup_path=$(backup_file "$src")
    local restored
    restored=$(<"$backup_path")
    [[ "$restored" == "important content" ]]
}

@test "backup_file returns empty for non-existent file" {
    run backup_file "/nonexistent/file.txt"
    assert_success
    [[ -z "$output" ]]
}

@test "backup_file includes timestamp in filename" {
    local src="${PIMPMYSHELL_TEST_DIR}/myconfig.txt"
    echo "data" > "$src"

    local backup_path
    backup_path=$(backup_file "$src")
    local backup_name
    backup_name=$(basename "$backup_path")
    # Should match pattern: myconfig.txt.YYYYMMDD_HHMMSS.bak
    [[ "$backup_name" =~ ^myconfig\.txt\.[0-9]{8}_[0-9]{6}\.bak$ ]]
}

@test "backup_file creates backup directory if missing" {
    rm -rf "$PIMPMYSHELL_BACKUP_DIR"
    local src="${PIMPMYSHELL_TEST_DIR}/testfile.txt"
    echo "data" > "$src"

    run backup_file "$src"
    assert_success
    assert_dir_exists "$PIMPMYSHELL_BACKUP_DIR"
}

# =============================================================================
# restore_file
# =============================================================================

@test "restore_file copies backup to target" {
    local backup="${PIMPMYSHELL_TEST_DIR}/backup.bak"
    echo "restored content" > "$backup"
    local target="${PIMPMYSHELL_TEST_DIR}/restored.txt"

    run restore_file "$backup" "$target"
    assert_success
    assert_file_exists "$target"
    assert_file_contains "$target" "restored content"
}

@test "restore_file fails for non-existent backup" {
    run restore_file "/nonexistent/backup.bak" "${PIMPMYSHELL_TEST_DIR}/target.txt"
    assert_failure
}

@test "restore_file creates target directory if needed" {
    local backup="${PIMPMYSHELL_TEST_DIR}/backup.bak"
    echo "data" > "$backup"
    local target="${PIMPMYSHELL_TEST_DIR}/subdir/deep/restored.txt"

    run restore_file "$backup" "$target"
    assert_success
    assert_file_exists "$target"
}

@test "restore_file overwrites existing target" {
    local backup="${PIMPMYSHELL_TEST_DIR}/backup.bak"
    echo "new content" > "$backup"
    local target="${PIMPMYSHELL_TEST_DIR}/target.txt"
    echo "old content" > "$target"

    restore_file "$backup" "$target"
    assert_file_contains "$target" "new content"
}

# =============================================================================
# list_backups
# =============================================================================

@test "list_backups returns empty when no backups exist" {
    run list_backups
    assert_success
    [[ -z "$output" || "$output" == *"No backups"* ]]
}

@test "list_backups lists backup files" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    touch "${PIMPMYSHELL_BACKUP_DIR}/file1.20260101_120000.bak"
    touch "${PIMPMYSHELL_BACKUP_DIR}/file2.20260101_120001.bak"

    run list_backups
    assert_success
    assert_output_contains ".bak"
}

@test "list_backups filters by filename" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    touch "${PIMPMYSHELL_BACKUP_DIR}/zshrc.20260101_120000.bak"
    touch "${PIMPMYSHELL_BACKUP_DIR}/starship.toml.20260101_120000.bak"

    run list_backups "zshrc"
    assert_success
    assert_output_contains "zshrc"
}

@test "list_backups returns sorted by time (newest first)" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    # Create files with different timestamps
    touch -t 202601011200 "${PIMPMYSHELL_BACKUP_DIR}/file.20260101_120000.bak"
    sleep 0.1
    touch -t 202601021200 "${PIMPMYSHELL_BACKUP_DIR}/file.20260102_120000.bak"

    run list_backups
    assert_success
    # First line should be the newer file
    local first_line
    first_line=$(echo "$output" | head -1)
    assert_output_contains "20260102"
}

# =============================================================================
# get_latest_backup
# =============================================================================

@test "get_latest_backup returns empty when no backups" {
    run get_latest_backup "zshrc"
    assert_success
    [[ -z "$output" ]]
}

@test "get_latest_backup returns most recent backup" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    touch -t 202601011200 "${PIMPMYSHELL_BACKUP_DIR}/zshrc.20260101_120000.bak"
    sleep 0.1
    touch -t 202601021200 "${PIMPMYSHELL_BACKUP_DIR}/zshrc.20260102_120000.bak"

    run get_latest_backup "zshrc"
    assert_success
    assert_output_contains "20260102"
}

@test "get_latest_backup returns only matching filename" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    touch "${PIMPMYSHELL_BACKUP_DIR}/zshrc.20260101_120000.bak"
    touch "${PIMPMYSHELL_BACKUP_DIR}/starship.toml.20260102_120000.bak"

    run get_latest_backup "zshrc"
    assert_success
    assert_output_contains "zshrc"
    refute_output_contains "starship"
}

# =============================================================================
# cleanup_old_backups
# =============================================================================

@test "cleanup_old_backups does nothing with few backups" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    touch "${PIMPMYSHELL_BACKUP_DIR}/file.20260101_120000.bak"
    touch "${PIMPMYSHELL_BACKUP_DIR}/file.20260102_120000.bak"

    run cleanup_old_backups
    assert_success
    # Both should still exist
    [[ -f "${PIMPMYSHELL_BACKUP_DIR}/file.20260101_120000.bak" ]]
    [[ -f "${PIMPMYSHELL_BACKUP_DIR}/file.20260102_120000.bak" ]]
}

@test "cleanup_old_backups removes oldest when exceeding retention" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    # Create 3 backups with different times, retention=2
    touch -t 202601010100 "${PIMPMYSHELL_BACKUP_DIR}/f.20260101_010000.bak"
    touch -t 202601020100 "${PIMPMYSHELL_BACKUP_DIR}/f.20260102_010000.bak"
    touch -t 202601030100 "${PIMPMYSHELL_BACKUP_DIR}/f.20260103_010000.bak"

    run cleanup_old_backups 2
    assert_success
    # Oldest should be removed
    [[ ! -f "${PIMPMYSHELL_BACKUP_DIR}/f.20260101_010000.bak" ]]
    # Newer should remain
    [[ -f "${PIMPMYSHELL_BACKUP_DIR}/f.20260102_010000.bak" ]]
    [[ -f "${PIMPMYSHELL_BACKUP_DIR}/f.20260103_010000.bak" ]]
}

@test "cleanup_old_backups handles empty directory" {
    mkdir -p "$PIMPMYSHELL_BACKUP_DIR"
    run cleanup_old_backups
    assert_success
}

@test "cleanup_old_backups handles missing directory" {
    rm -rf "$PIMPMYSHELL_BACKUP_DIR"
    run cleanup_old_backups
    assert_success
}

# =============================================================================
# backup_before_apply
# =============================================================================

@test "backup_before_apply backs up existing .zshrc" {
    local zshrc="${HOME}/.zshrc"
    echo "my zshrc" > "$zshrc"

    run backup_before_apply
    assert_success
    # Should have created a backup (dot-prefix needs -a or explicit pattern)
    [[ -n "$(ls "${PIMPMYSHELL_BACKUP_DIR}"/.zshrc.*.bak 2>/dev/null)" ]]
}

@test "backup_before_apply backs up existing starship.toml" {
    mkdir -p "${HOME}/.config"
    echo "starship config" > "${HOME}/.config/starship.toml"

    run backup_before_apply
    assert_success
    # Should have starship backup
    [[ -n "$(ls "${PIMPMYSHELL_BACKUP_DIR}"/starship.toml.*.bak 2>/dev/null)" ]]
}

@test "backup_before_apply backs up existing pimpmyshell.yaml" {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    echo "theme: cyberpunk" > "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run backup_before_apply
    assert_success
    [[ -n "$(ls "${PIMPMYSHELL_BACKUP_DIR}"/pimpmyshell.yaml.*.bak 2>/dev/null)" ]]
}

@test "backup_before_apply succeeds with no existing files" {
    run backup_before_apply
    assert_success
}

@test "backup_before_apply backs up all three files when they exist" {
    echo "zshrc" > "${HOME}/.zshrc"
    mkdir -p "${HOME}/.config"
    echo "starship" > "${HOME}/.config/starship.toml"
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    echo "theme: cyberpunk" > "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run backup_before_apply
    assert_success
    # Count all .bak files (including dot-prefixed) using find
    local count
    count=$(find "${PIMPMYSHELL_BACKUP_DIR}" -name "*.bak" -type f 2>/dev/null | wc -l)
    [[ "$count" -eq 3 ]]
}

# =============================================================================
# Edge cases
# =============================================================================

@test "backup_file handles filenames with spaces" {
    local src="${PIMPMYSHELL_TEST_DIR}/my config file.txt"
    echo "data" > "$src"

    run backup_file "$src"
    assert_success
    [[ -f "$output" ]]
}

@test "multiple backups of same file create different files" {
    local src="${PIMPMYSHELL_TEST_DIR}/testfile.txt"
    echo "v1" > "$src"

    local b1
    b1=$(backup_file "$src")
    sleep 1
    echo "v2" > "$src"
    local b2
    b2=$(backup_file "$src")

    [[ "$b1" != "$b2" ]]
    [[ -f "$b1" ]]
    [[ -f "$b2" ]]
}

# =============================================================================
# Argument validation
# =============================================================================

@test "restore_file fails without arguments" {
    run restore_file
    assert_failure
    assert_output_contains "restore_file"
}

@test "get_latest_backup fails without arguments" {
    run get_latest_backup
    assert_failure
    assert_output_contains "get_latest_backup"
}

#!/usr/bin/env bats
# pimpmyshell - Tests for install.sh

load 'test_helper'

# We source install.sh functions by sourcing it in a way that doesn't run main()
# install.sh uses: if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME"
    mkdir -p "$HOME/.local/bin"

    # Set install dir to test dir
    export PIMPMYSHELL_INSTALL_DIR="${PIMPMYSHELL_TEST_DIR}/install"

    # Source install.sh (won't run main because BASH_SOURCE != $0)
    source "${PIMPMYSHELL_ROOT}/install.sh"
}

# =============================================================================
# Script existence and structure
# =============================================================================

@test "install.sh exists" {
    [[ -f "${PIMPMYSHELL_ROOT}/install.sh" ]]
}

@test "install.sh is executable" {
    [[ -x "${PIMPMYSHELL_ROOT}/install.sh" ]]
}

@test "install.sh has bash shebang" {
    local first_line
    first_line=$(head -1 "${PIMPMYSHELL_ROOT}/install.sh")
    [[ "$first_line" == "#!/usr/bin/env bash" ]]
}

# =============================================================================
# Configuration constants
# =============================================================================

@test "PIMPMYSHELL_REPO is set" {
    [[ -n "$PIMPMYSHELL_REPO" ]]
}

@test "PIMPMYSHELL_INSTALL_DIR defaults to ~/.pimpmyshell" {
    unset PIMPMYSHELL_INSTALL_DIR
    source "${PIMPMYSHELL_ROOT}/install.sh"
    [[ "$PIMPMYSHELL_INSTALL_DIR" == *".pimpmyshell"* ]]
}

@test "PIMPMYSHELL_BIN_DIR is set to ~/.local/bin" {
    [[ "$PIMPMYSHELL_BIN_DIR" == *".local/bin"* ]]
}

# =============================================================================
# Platform detection
# =============================================================================

@test "get_platform returns a valid value" {
    run get_platform
    assert_success
    [[ "$output" == "linux" || "$output" == "macos" || "$output" == "wsl" || "$output" == "unknown" ]]
}

# =============================================================================
# Package manager detection
# =============================================================================

@test "detect_package_manager returns a value" {
    run detect_package_manager
    assert_success
    [[ -n "$output" ]]
}

# =============================================================================
# Prerequisite checks
# =============================================================================

@test "check_prerequisite_command succeeds for existing command" {
    run check_prerequisite_command "bash"
    assert_success
}

@test "check_prerequisite_command fails for missing command" {
    run check_prerequisite_command "nonexistent_command_xyz"
    assert_failure
}

# =============================================================================
# check_prerequisites
# =============================================================================

@test "check_prerequisites succeeds when git is available" {
    # git should be available in test environment
    run check_prerequisites
    assert_success
}

# =============================================================================
# install_yq
# =============================================================================

@test "install_yq function exists" {
    declare -F install_yq
}

# =============================================================================
# install_omz
# =============================================================================

@test "install_omz function exists" {
    declare -F install_omz
}

# =============================================================================
# setup_directories
# =============================================================================

@test "setup_directories creates install directory" {
    rm -rf "$PIMPMYSHELL_INSTALL_DIR"
    setup_directories
    [[ -d "$PIMPMYSHELL_INSTALL_DIR" ]]
}

@test "setup_directories creates config directory" {
    local config_dir="${PIMPMYSHELL_TEST_DIR}/xdg_config/pimpmyshell"
    export PIMPMYSHELL_CONFIG_DIR="$config_dir"
    rm -rf "$config_dir"
    setup_directories
    [[ -d "$config_dir" ]]
}

@test "setup_directories creates data directory" {
    local data_dir="${PIMPMYSHELL_TEST_DIR}/xdg_data/pimpmyshell"
    export PIMPMYSHELL_DATA_DIR="$data_dir"
    rm -rf "$data_dir"
    setup_directories
    [[ -d "$data_dir" ]]
}

@test "setup_directories creates bin directory" {
    setup_directories
    [[ -d "$PIMPMYSHELL_BIN_DIR" ]]
}

# =============================================================================
# setup_symlink
# =============================================================================

@test "setup_symlink creates CLI symlink" {
    mkdir -p "$PIMPMYSHELL_INSTALL_DIR/bin"
    echo '#!/bin/bash' > "$PIMPMYSHELL_INSTALL_DIR/bin/pimpmyshell"
    chmod +x "$PIMPMYSHELL_INSTALL_DIR/bin/pimpmyshell"
    setup_directories

    setup_symlink
    [[ -L "${PIMPMYSHELL_BIN_DIR}/pimpmyshell" ]]
}

@test "setup_symlink points to correct target" {
    mkdir -p "$PIMPMYSHELL_INSTALL_DIR/bin"
    echo '#!/bin/bash' > "$PIMPMYSHELL_INSTALL_DIR/bin/pimpmyshell"
    chmod +x "$PIMPMYSHELL_INSTALL_DIR/bin/pimpmyshell"
    setup_directories

    setup_symlink
    local target
    target=$(readlink "${PIMPMYSHELL_BIN_DIR}/pimpmyshell")
    [[ "$target" == "${PIMPMYSHELL_INSTALL_DIR}/bin/pimpmyshell" ]]
}

@test "setup_symlink replaces existing symlink" {
    mkdir -p "$PIMPMYSHELL_BIN_DIR"
    ln -sf "/tmp/old_target" "${PIMPMYSHELL_BIN_DIR}/pimpmyshell"

    mkdir -p "$PIMPMYSHELL_INSTALL_DIR/bin"
    echo '#!/bin/bash' > "$PIMPMYSHELL_INSTALL_DIR/bin/pimpmyshell"
    chmod +x "$PIMPMYSHELL_INSTALL_DIR/bin/pimpmyshell"

    setup_symlink
    local target
    target=$(readlink "${PIMPMYSHELL_BIN_DIR}/pimpmyshell")
    [[ "$target" == "${PIMPMYSHELL_INSTALL_DIR}/bin/pimpmyshell" ]]
}

# =============================================================================
# copy_config_example
# =============================================================================

@test "copy_config_example copies example config on fresh install" {
    mkdir -p "$PIMPMYSHELL_INSTALL_DIR"
    cp "${PIMPMYSHELL_ROOT}/pimpmyshell.yaml.example" "$PIMPMYSHELL_INSTALL_DIR/"
    rm -f "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run copy_config_example
    assert_success
    assert_file_exists "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
}

@test "copy_config_example preserves existing config" {
    mkdir -p "$PIMPMYSHELL_INSTALL_DIR"
    cp "${PIMPMYSHELL_ROOT}/pimpmyshell.yaml.example" "$PIMPMYSHELL_INSTALL_DIR/"
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    echo "theme: matrix" > "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run copy_config_example
    assert_success
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "theme: matrix"
}

# =============================================================================
# install_from_local
# =============================================================================

@test "install_from_local copies repo to install dir" {
    rm -rf "$PIMPMYSHELL_INSTALL_DIR"
    export PIMPMYSHELL_SCRIPT_DIR="$PIMPMYSHELL_ROOT"

    run install_from_local
    assert_success
    [[ -d "$PIMPMYSHELL_INSTALL_DIR" ]]
    [[ -f "$PIMPMYSHELL_INSTALL_DIR/bin/pimpmyshell" ]]
}

@test "install_from_local skips when already in install dir" {
    export PIMPMYSHELL_INSTALL_DIR="$PIMPMYSHELL_ROOT"
    export PIMPMYSHELL_SCRIPT_DIR="$PIMPMYSHELL_ROOT"

    run install_from_local
    assert_success
}

# =============================================================================
# detect_shell
# =============================================================================

@test "detect_shell returns a shell name" {
    run detect_shell
    assert_success
    [[ -n "$output" ]]
}

# =============================================================================
# uninstall
# =============================================================================

@test "uninstall_pimpmyshell removes symlink" {
    mkdir -p "$PIMPMYSHELL_BIN_DIR"
    touch "${PIMPMYSHELL_BIN_DIR}/pimpmyshell"

    run uninstall_pimpmyshell
    assert_success
    [[ ! -f "${PIMPMYSHELL_BIN_DIR}/pimpmyshell" ]]
}

@test "uninstall_pimpmyshell removes install directory" {
    mkdir -p "$PIMPMYSHELL_INSTALL_DIR"

    run uninstall_pimpmyshell
    assert_success
    [[ ! -d "$PIMPMYSHELL_INSTALL_DIR" ]]
}

@test "uninstall_pimpmyshell preserves config directory" {
    mkdir -p "$PIMPMYSHELL_INSTALL_DIR"
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    echo "keep" > "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run uninstall_pimpmyshell
    assert_success
    assert_file_exists "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
}

# =============================================================================
# Completions files
# =============================================================================

@test "zsh completion file exists" {
    [[ -f "${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh" ]]
}

@test "bash completion file exists" {
    [[ -f "${PIMPMYSHELL_ROOT}/completions/pimpmyshell.bash" ]]
}

@test "zsh completion file has correct header" {
    local first_line
    first_line=$(head -1 "${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh")
    [[ "$first_line" == "#compdef pimpmyshell" ]]
}

@test "bash completion registers pimpmyshell" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/completions/pimpmyshell.bash" "complete -F"
    assert_file_contains "${PIMPMYSHELL_ROOT}/completions/pimpmyshell.bash" "pimpmyshell"
}

@test "zsh completion defines main commands" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh"
    assert_file_contains "$file" "apply"
    assert_file_contains "$file" "theme"
    assert_file_contains "$file" "tools"
    assert_file_contains "$file" "backup"
    assert_file_contains "$file" "restore"
    assert_file_contains "$file" "doctor"
    assert_file_contains "$file" "wizard"
    assert_file_contains "$file" "profile"
    assert_file_contains "$file" "help"
    assert_file_contains "$file" "version"
}

@test "bash completion defines main commands" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.bash"
    assert_file_contains "$file" "apply"
    assert_file_contains "$file" "theme"
    assert_file_contains "$file" "tools"
    assert_file_contains "$file" "backup"
    assert_file_contains "$file" "restore"
    assert_file_contains "$file" "profile"
    assert_file_contains "$file" "help"
    assert_file_contains "$file" "version"
}

@test "zsh completion handles theme subcommands" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh"
    grep -qF -- "--list" "$file"
    grep -qF -- "--preview" "$file"
}

@test "zsh completion handles tools subcommands" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh"
    assert_file_contains "$file" "check"
    assert_file_contains "$file" "install"
}

@test "zsh completion handles profile subcommands" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh"
    assert_file_contains "$file" "list"
    assert_file_contains "$file" "create"
    assert_file_contains "$file" "switch"
    assert_file_contains "$file" "delete"
}

@test "bash completion handles profile subcommands" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.bash"
    assert_file_contains "$file" "list"
    assert_file_contains "$file" "create"
    assert_file_contains "$file" "switch"
    assert_file_contains "$file" "delete"
}

@test "zsh completion provides dynamic theme completion" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh"
    assert_file_contains "$file" "themes_dir"
    assert_file_contains "$file" "_describe"
}

@test "zsh completion provides global options" {
    local file="${PIMPMYSHELL_ROOT}/completions/pimpmyshell.zsh"
    grep -qF -- "--config" "$file"
    grep -qF -- "--verbose" "$file"
    grep -qF -- "--debug" "$file"
    grep -qF -- "--quiet" "$file"
    grep -qF -- "--dry-run" "$file"
    grep -qF -- "--no-backup" "$file"
}

# =============================================================================
# main routing
# =============================================================================

# =============================================================================
# rm -rf safety guards
# =============================================================================

@test "install_from_local refuses empty PIMPMYSHELL_INSTALL_DIR" {
    export PIMPMYSHELL_INSTALL_DIR=""
    export PIMPMYSHELL_SCRIPT_DIR="$PIMPMYSHELL_ROOT"
    run install_from_local
    assert_failure
    assert_output_contains "unsafe path"
}

@test "install_from_local refuses root path" {
    export PIMPMYSHELL_INSTALL_DIR="/"
    export PIMPMYSHELL_SCRIPT_DIR="$PIMPMYSHELL_ROOT"
    run install_from_local
    assert_failure
    assert_output_contains "unsafe path"
}

@test "install_from_local refuses HOME path" {
    export PIMPMYSHELL_INSTALL_DIR="$HOME"
    export PIMPMYSHELL_SCRIPT_DIR="$PIMPMYSHELL_ROOT"
    run install_from_local
    assert_failure
    assert_output_contains "unsafe path"
}

@test "uninstall_pimpmyshell refuses empty PIMPMYSHELL_INSTALL_DIR" {
    export PIMPMYSHELL_INSTALL_DIR=""
    run uninstall_pimpmyshell
    assert_failure
    assert_output_contains "unsafe path"
}

@test "uninstall_pimpmyshell refuses root path" {
    export PIMPMYSHELL_INSTALL_DIR="/"
    run uninstall_pimpmyshell
    assert_failure
    assert_output_contains "unsafe path"
}

@test "uninstall_pimpmyshell refuses HOME path" {
    export PIMPMYSHELL_INSTALL_DIR="$HOME"
    run uninstall_pimpmyshell
    assert_failure
    assert_output_contains "unsafe path"
}

# =============================================================================
# main routing
# =============================================================================

@test "install.sh main routes --help" {
    run bash "${PIMPMYSHELL_ROOT}/install.sh" --help
    assert_success
    assert_output_contains "install"
    assert_output_contains "uninstall"
}

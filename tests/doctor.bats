#!/usr/bin/env bats
# pimpmyshell - Tests for lib/doctor.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME"
    mkdir -p "$HOME/.config"

    # Create themes dir with a theme
    export PIMPMYSHELL_THEMES_DIR="${PIMPMYSHELL_ROOT}/themes"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'themes'
    load_lib 'plugins'
    load_lib 'tools'
    load_lib 'doctor'
}

# =============================================================================
# Guard
# =============================================================================

@test "doctor.sh sets _PIMPMYSHELL_DOCTOR_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_DOCTOR_LOADED:-}" ]]
}

# =============================================================================
# check_shell
# =============================================================================

@test "check_shell function exists" {
    declare -F check_shell
}

@test "check_shell returns status" {
    run check_shell
    # Should succeed (returns 0) even if zsh is not default
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "check_shell detects zsh binary" {
    run check_shell
    # Output should mention zsh
    assert_output_contains "zsh"
}

# =============================================================================
# check_framework
# =============================================================================

@test "check_framework function exists" {
    declare -F check_framework
}

@test "check_framework detects oh-my-zsh when present" {
    # Create fake omz directory
    local omz_dir="${HOME}/.oh-my-zsh"
    mkdir -p "$omz_dir"
    touch "${omz_dir}/oh-my-zsh.sh"
    export ZSH="$omz_dir"
    # Re-set OMZ_DIR used by plugins
    export OMZ_DIR="$omz_dir"

    run check_framework
    assert_success
    assert_output_contains "oh-my-zsh"
}

@test "check_framework warns when oh-my-zsh is missing" {
    export ZSH="${PIMPMYSHELL_TEST_DIR}/nonexistent-omz"
    export OMZ_DIR="${PIMPMYSHELL_TEST_DIR}/nonexistent-omz"

    run check_framework
    # Should warn but not fail fatally
    assert_output_contains "oh-my-zsh"
}

# =============================================================================
# check_doctor_tools
# =============================================================================

@test "check_doctor_tools function exists" {
    declare -F check_doctor_tools
}

@test "check_doctor_tools reports on tools" {
    # Create a minimal config with a tool we know exists (bash)
    create_test_config '
theme: cyberpunk
tools:
  required:
    - bash
'
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run check_doctor_tools
    assert_success
}

@test "check_doctor_tools reports missing tools" {
    create_test_config '
theme: cyberpunk
tools:
  required:
    - nonexistent_tool_xyz
'
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run check_doctor_tools
    assert_success
    assert_output_contains "nonexistent_tool_xyz"
}

# =============================================================================
# check_doctor_plugins
# =============================================================================

@test "check_doctor_plugins function exists" {
    declare -F check_doctor_plugins
}

@test "check_doctor_plugins reports when omz is not installed" {
    export ZSH="${PIMPMYSHELL_TEST_DIR}/nonexistent-omz"
    export OMZ_DIR="${PIMPMYSHELL_TEST_DIR}/nonexistent-omz"

    create_test_config '
theme: cyberpunk
plugins:
  ohmyzsh:
    - git
  custom:
    - zsh-autosuggestions
'
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run check_doctor_plugins
    assert_success
    assert_output_contains "oh-my-zsh"
}

@test "check_doctor_plugins checks plugins when omz exists" {
    local omz_dir="${HOME}/.oh-my-zsh"
    mkdir -p "${omz_dir}/plugins/git"
    touch "${omz_dir}/oh-my-zsh.sh"
    export ZSH="$omz_dir"
    export OMZ_DIR="$omz_dir"
    export OMZ_CUSTOM_DIR="${omz_dir}/custom"

    create_test_config '
theme: cyberpunk
plugins:
  ohmyzsh:
    - git
  custom:
    - zsh-autosuggestions
'
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run check_doctor_plugins
    assert_success
    assert_output_contains "git"
}

# =============================================================================
# check_doctor_theme
# =============================================================================

@test "check_doctor_theme function exists" {
    declare -F check_doctor_theme
}

@test "check_doctor_theme reports on configured theme" {
    create_test_config '
theme: cyberpunk
'
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run check_doctor_theme
    assert_success
    assert_output_contains "cyberpunk"
}

@test "check_doctor_theme detects missing theme" {
    create_test_config '
theme: nonexistent_theme_xyz
'
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run check_doctor_theme
    assert_success
    assert_output_contains "nonexistent_theme_xyz"
}

# =============================================================================
# check_doctor_config
# =============================================================================

@test "check_doctor_config function exists" {
    declare -F check_doctor_config
}

@test "check_doctor_config succeeds with valid config" {
    create_test_config
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run check_doctor_config
    assert_success
}

@test "check_doctor_config reports missing config" {
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_TEST_DIR}/nonexistent.yaml"

    run check_doctor_config
    assert_success
    assert_output_contains "not found"
}

# =============================================================================
# check_nerd_font
# =============================================================================

@test "check_nerd_font function exists" {
    declare -F check_nerd_font
}

@test "check_nerd_font returns a status" {
    run check_nerd_font
    # Should not crash - it may or may not find a Nerd Font
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

# =============================================================================
# check_true_color
# =============================================================================

@test "check_true_color function exists" {
    declare -F check_true_color
}

@test "check_true_color returns a status" {
    run check_true_color
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

# =============================================================================
# run_doctor
# =============================================================================

@test "run_doctor function exists" {
    declare -F run_doctor
}

@test "run_doctor orchestrates all checks" {
    create_test_config
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    # Create fake omz directory
    local omz_dir="${HOME}/.oh-my-zsh"
    mkdir -p "${omz_dir}/plugins/git"
    touch "${omz_dir}/oh-my-zsh.sh"
    export ZSH="$omz_dir"
    export OMZ_DIR="$omz_dir"
    export OMZ_CUSTOM_DIR="${omz_dir}/custom"

    run run_doctor
    assert_success
}

@test "run_doctor outputs section headers" {
    create_test_config
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run run_doctor
    assert_success
    # Should have multiple section headings
    assert_output_contains "Shell"
    assert_output_contains "Theme"
    assert_output_contains "Config"
}

@test "run_doctor succeeds with minimal environment" {
    # No omz, no config
    export ZSH="${PIMPMYSHELL_TEST_DIR}/nonexistent-omz"
    export OMZ_DIR="${PIMPMYSHELL_TEST_DIR}/nonexistent-omz"
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_TEST_DIR}/nonexistent.yaml"

    run run_doctor
    assert_success
}

@test "run_doctor shows summary" {
    create_test_config
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run run_doctor
    assert_success
    assert_output_contains "pass"
}

# =============================================================================
# Integration with CLI
# =============================================================================

@test "cmd_doctor calls run_doctor" {
    # Load the main CLI script (sourced, not executed)
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"

    create_test_config
    export PIMPMYSHELL_CONFIG_FILE="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    run cmd_doctor
    assert_success
}

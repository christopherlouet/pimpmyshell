#!/usr/bin/env bats
# pimpmyshell - Tests for lib/themes.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Use the real themes directory from the project
    export PIMPMYSHELL_THEMES_DIR="${PIMPMYSHELL_ROOT}/themes"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'themes'
}

# =============================================================================
# Guard
# =============================================================================

@test "themes.sh sets _PIMPMYSHELL_THEMES_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_THEMES_LOADED:-}" ]]
}

# =============================================================================
# list_themes
# =============================================================================

@test "list_themes returns all 7 themes" {
    run list_themes
    assert_success
    # Count lines
    local count
    count=$(echo "$output" | wc -l)
    [[ "$count" -eq 7 ]]
}

@test "list_themes includes cyberpunk" {
    run list_themes
    assert_success
    assert_output_contains "cyberpunk"
}

@test "list_themes includes matrix" {
    run list_themes
    assert_success
    assert_output_contains "matrix"
}

@test "list_themes includes dracula" {
    run list_themes
    assert_success
    assert_output_contains "dracula"
}

@test "list_themes includes catppuccin" {
    run list_themes
    assert_success
    assert_output_contains "catppuccin"
}

@test "list_themes includes nord" {
    run list_themes
    assert_success
    assert_output_contains "nord"
}

@test "list_themes includes gruvbox" {
    run list_themes
    assert_success
    assert_output_contains "gruvbox"
}

@test "list_themes includes tokyo-night" {
    run list_themes
    assert_success
    assert_output_contains "tokyo-night"
}

@test "list_themes fails with missing themes directory" {
    export PIMPMYSHELL_THEMES_DIR="/nonexistent/themes"
    run list_themes
    assert_failure
}

# =============================================================================
# get_theme_path
# =============================================================================

@test "get_theme_path returns path for existing theme" {
    run get_theme_path "cyberpunk"
    assert_success
    assert_output_contains "cyberpunk.yaml"
}

@test "get_theme_path fails for non-existent theme" {
    run get_theme_path "nonexistent_theme_xyz"
    assert_failure
}

@test "get_theme_path returns path for all valid themes" {
    for theme in cyberpunk matrix dracula catppuccin nord gruvbox tokyo-night; do
        run get_theme_path "$theme"
        assert_success
    done
}

@test "get_theme_path accepts full path to theme file" {
    local full_path="${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"
    run get_theme_path "$full_path"
    assert_success
    assert_output_contains "cyberpunk.yaml"
}

# =============================================================================
# theme_get - Read values from theme YAML
# =============================================================================

@test "theme_get reads theme name" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local theme_file="${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"

    run theme_get "$theme_file" '.name'
    assert_success
    assert_output_contains "Cyberpunk"
}

@test "theme_get reads theme description" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local theme_file="${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"

    run theme_get "$theme_file" '.description'
    assert_success
    [[ -n "$output" ]]
}

@test "theme_get reads color values" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local theme_file="${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"

    run theme_get "$theme_file" '.colors.accent'
    assert_success
    # Cyberpunk accent is cyan (#00ffff)
    assert_output_contains "#00ffff"
}

@test "theme_get returns default for missing key" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local theme_file="${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"

    run theme_get "$theme_file" '.nonexistent_key' 'fallback'
    assert_success
    assert_output_contains "fallback"
}

@test "theme_get returns default for non-existent file" {
    run theme_get "/nonexistent/theme.yaml" '.name' 'default_name'
    assert_success
    assert_output_contains "default_name"
}

# =============================================================================
# load_theme - Load and export THEME_* variables
# =============================================================================

@test "load_theme succeeds for cyberpunk theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    run load_theme "cyberpunk"
    assert_success
}

@test "load_theme fails for non-existent theme" {
    run load_theme "nonexistent_theme_xyz"
    assert_failure
}

@test "load_theme exports THEME_NAME" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    [[ "$THEME_NAME" == "Cyberpunk" ]]
}

@test "load_theme exports THEME_BG" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    [[ -n "$THEME_BG" ]]
    [[ "$THEME_BG" == "#0d0d1a" ]]
}

@test "load_theme exports THEME_ACCENT" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    [[ "$THEME_ACCENT" == "#00ffff" ]]
}

@test "load_theme exports THEME_DESCRIPTION" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    [[ -n "$THEME_DESCRIPTION" ]]
}

@test "load_theme exports separator variables" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    # Separator variables should be declared (may be empty for some themes)
    declare -p THEME_SEP_LEFT &>/dev/null
    declare -p THEME_SEP_RIGHT &>/dev/null
}

@test "load_theme exports all color variables" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    [[ -n "$THEME_BG" ]]
    [[ -n "$THEME_FG" ]]
    [[ -n "$THEME_ACCENT" ]]
    [[ -n "$THEME_ACCENT2" ]]
    [[ -n "$THEME_WARNING" ]]
    [[ -n "$THEME_ERROR" ]]
    [[ -n "$THEME_SUCCESS" ]]
}

@test "load_theme works for matrix theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "matrix"
    [[ "$THEME_NAME" == "Matrix" ]]
}

@test "load_theme works for dracula theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "dracula"
    [[ "$THEME_NAME" == "Dracula" ]]
}

# =============================================================================
# apply_starship_theme
# =============================================================================

@test "apply_starship_theme copies toml file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local starship_dir="${PIMPMYSHELL_TEST_DIR}/config/starship"
    mkdir -p "$starship_dir"
    export STARSHIP_CONFIG="${starship_dir}/starship.toml"

    run apply_starship_theme "cyberpunk"
    assert_success
    [[ -f "$STARSHIP_CONFIG" ]]
}

@test "apply_starship_theme fails for non-existent theme" {
    export STARSHIP_CONFIG="${PIMPMYSHELL_TEST_DIR}/starship.toml"
    run apply_starship_theme "nonexistent_theme_xyz"
    assert_failure
}

@test "apply_starship_theme creates backup of existing config" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local starship_config="${PIMPMYSHELL_TEST_DIR}/starship.toml"
    echo "# old config" > "$starship_config"
    export STARSHIP_CONFIG="$starship_config"

    run apply_starship_theme "cyberpunk"
    assert_success
    # Backup should exist
    [[ -n "$(ls -A "${PIMPMYSHELL_DATA_DIR}/backups/" 2>/dev/null)" ]]
}

# =============================================================================
# apply_eza_theme
# =============================================================================

@test "apply_eza_theme copies eza colors script" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local eza_dir="${PIMPMYSHELL_DATA_DIR}/eza"
    mkdir -p "$eza_dir"

    run apply_eza_theme "cyberpunk"
    assert_success
    [[ -f "${eza_dir}/eza-theme.sh" ]]
}

@test "apply_eza_theme fails for non-existent theme" {
    run apply_eza_theme "nonexistent_theme_xyz"
    assert_failure
}

@test "apply_eza_theme output contains EZA_COLORS" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local eza_dir="${PIMPMYSHELL_DATA_DIR}/eza"
    mkdir -p "$eza_dir"

    run apply_eza_theme "cyberpunk"
    assert_success

    local eza_file="${eza_dir}/eza-theme.sh"
    [[ -f "$eza_file" ]]
    grep -q "EZA_COLORS" "$eza_file"
}

# =============================================================================
# apply_theme - orchestration
# =============================================================================

@test "apply_theme succeeds for cyberpunk" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local starship_config="${PIMPMYSHELL_TEST_DIR}/starship.toml"
    local eza_dir="${PIMPMYSHELL_DATA_DIR}/eza"
    export STARSHIP_CONFIG="$starship_config"
    mkdir -p "$eza_dir"

    run apply_theme "cyberpunk"
    assert_success
}

@test "apply_theme fails for non-existent theme" {
    run apply_theme "nonexistent_theme_xyz"
    assert_failure
}

# =============================================================================
# Data file integrity
# =============================================================================

@test "starship data files exist for all themes" {
    local data_dir="${PIMPMYSHELL_ROOT}/themes/data"
    for theme in cyberpunk matrix dracula catppuccin nord gruvbox tokyo-night; do
        [[ -f "${data_dir}/${theme}.toml" ]]
    done
}

@test "eza data files exist for all themes" {
    local data_dir="${PIMPMYSHELL_ROOT}/themes/data"
    for theme in cyberpunk matrix dracula catppuccin nord gruvbox tokyo-night; do
        [[ -f "${data_dir}/eza-${theme}.sh" ]]
    done
}

@test "theme YAML files exist for all themes" {
    for theme in cyberpunk matrix dracula catppuccin nord gruvbox tokyo-night; do
        [[ -f "${PIMPMYSHELL_THEMES_DIR}/${theme}.yaml" ]]
    done
}

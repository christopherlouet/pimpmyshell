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

# =============================================================================
# Argument validation
# =============================================================================

@test "get_theme_path fails without arguments" {
    run get_theme_path
    assert_failure
    assert_output_contains "get_theme_path"
}

@test "theme_get fails without arguments" {
    run theme_get
    assert_failure
    assert_output_contains "theme_get"
}

@test "load_theme fails without arguments" {
    run load_theme
    assert_failure
    assert_output_contains "load_theme"
}

@test "apply_theme fails without arguments" {
    run apply_theme
    assert_failure
    assert_output_contains "apply_theme"
}

@test "preview_theme fails without arguments" {
    run preview_theme
    assert_failure
    assert_output_contains "preview_theme"
}

# =============================================================================
# theme_get_palette edge cases
# =============================================================================

@test "theme_get_palette returns formatted string for cyberpunk theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local theme_file="${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"
    run theme_get_palette "$theme_file"
    assert_success
    # Should return a bracket-delimited list
    [[ "$output" == "["*"]" ]]
}

@test "theme_get_palette returns empty for missing palette" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/no-palette.yaml"
    echo "name: test" > "$yaml_file"
    run theme_get_palette "$yaml_file"
    assert_success
    [[ -z "$output" ]]
}

@test "theme_get_palette returns empty for non-existent file" {
    run theme_get_palette "/nonexistent/theme.yaml"
    assert_success
    [[ -z "$output" ]]
}

@test "theme_get_palette expands hex to dconf format" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local theme_file="${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"
    local result
    result=$(theme_get_palette "$theme_file")
    # dconf format uses #RRRRGGGGBBBB (6-char hex doubled)
    [[ "$result" == *"#"* ]]
    # Each color should be 13 chars (#RRRRGGGGBBBB)
    local first_color
    first_color=$(echo "$result" | tr -d "[]' " | cut -d',' -f1)
    [[ ${#first_color} -eq 13 ]]
}

# =============================================================================
# _parse_palette_colors
# =============================================================================

@test "_parse_palette_colors function exists" {
    declare -F _parse_palette_colors
}

@test "_parse_palette_colors converts dconf format to RRGGBB" {
    local palette="['#0d0d1a1a2e2e', '#ff00003333']"
    run _parse_palette_colors "$palette"
    assert_success
    # First color should be #0d1a2e
    local first_line
    first_line=$(echo "$output" | head -1)
    [[ "$first_line" == "#0d1a2e" ]]
}

@test "_parse_palette_colors passes through short hex colors" {
    local palette="['#ff0000', '#00ff00']"
    run _parse_palette_colors "$palette"
    assert_success
    assert_output_contains "#ff0000"
    assert_output_contains "#00ff00"
}

@test "_parse_palette_colors returns nothing for empty input" {
    run _parse_palette_colors ""
    assert_success
    [[ -z "$output" ]]
}

@test "_parse_palette_colors uses THEME_PALETTE when no argument" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    run _parse_palette_colors
    assert_success
    # Should output 16 lines (16 colors)
    local count
    count=$(echo "$output" | wc -l)
    [[ "$count" -eq 16 ]]
}

# =============================================================================
# detect_terminal
# =============================================================================

@test "detect_terminal function exists" {
    declare -F detect_terminal
}

@test "detect_terminal returns a string" {
    run detect_terminal
    assert_success
    [[ -n "$output" ]]
}

@test "detect_terminal detects kitty via TERM" {
    TERM=xterm-kitty run detect_terminal
    assert_success
    assert_output_equals "kitty"
}

@test "detect_terminal detects alacritty via TERM" {
    TERM=alacritty run detect_terminal
    assert_success
    assert_output_equals "alacritty"
}

@test "detect_terminal detects kitty via TERM_PROGRAM" {
    TERM_PROGRAM=kitty run detect_terminal
    assert_success
    assert_output_equals "kitty"
}

@test "detect_terminal detects wezterm via TERM_PROGRAM" {
    TERM_PROGRAM=WezTerm run detect_terminal
    assert_success
    assert_output_equals "wezterm"
}

@test "detect_terminal detects konsole via KONSOLE_VERSION" {
    KONSOLE_VERSION=220401 run detect_terminal
    assert_success
    assert_output_equals "konsole"
}

# =============================================================================
# _generate_kitty_theme - config generation
# =============================================================================

@test "_generate_kitty_theme function exists" {
    declare -F _generate_kitty_theme
}

@test "_generate_kitty_theme produces valid kitty config" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    run _generate_kitty_theme
    assert_success
    assert_output_contains "foreground"
    assert_output_contains "background"
    assert_output_contains "color0"
}

# =============================================================================
# _generate_alacritty_theme - config generation
# =============================================================================

@test "_generate_alacritty_theme function exists" {
    declare -F _generate_alacritty_theme
}

@test "_generate_alacritty_theme produces valid TOML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    run _generate_alacritty_theme
    assert_success
    assert_output_contains "[colors.primary]"
    assert_output_contains "foreground"
    assert_output_contains "background"
}

# =============================================================================
# _generate_konsole_theme - config generation
# =============================================================================

@test "_generate_konsole_theme function exists" {
    declare -F _generate_konsole_theme
}

@test "_generate_konsole_theme produces valid colorscheme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    run _generate_konsole_theme
    assert_success
    assert_output_contains "[General]"
    assert_output_contains "[Foreground]"
    assert_output_contains "[Background]"
    assert_output_contains "[Color0]"
}

# =============================================================================
# _apply_kitty_theme - writes config file
# =============================================================================

@test "_apply_kitty_theme writes config file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    local kitty_dir="${PIMPMYSHELL_TEST_DIR}/kitty"
    mkdir -p "$kitty_dir"
    XDG_CONFIG_HOME="${PIMPMYSHELL_TEST_DIR}" run _apply_kitty_theme
    assert_success
}

# =============================================================================
# _apply_alacritty_theme - writes config file
# =============================================================================

@test "_apply_alacritty_theme writes config file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    local alacritty_dir="${PIMPMYSHELL_TEST_DIR}/alacritty"
    mkdir -p "$alacritty_dir"
    XDG_CONFIG_HOME="${PIMPMYSHELL_TEST_DIR}" run _apply_alacritty_theme
    assert_success
}

# =============================================================================
# _apply_konsole_theme - writes config file
# =============================================================================

@test "_apply_konsole_theme writes colorscheme file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    load_theme "cyberpunk"
    local konsole_dir="${PIMPMYSHELL_TEST_DIR}/konsole"
    mkdir -p "$konsole_dir"
    XDG_DATA_HOME="${PIMPMYSHELL_TEST_DIR}" run _apply_konsole_theme
    assert_success
}

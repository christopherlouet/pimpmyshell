#!/usr/bin/env bats
# pimpmyshell - Tests for Phase 13: Theme preview & Update command

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME/.config"

    export PIMPMYSHELL_THEMES_DIR="${PIMPMYSHELL_ROOT}/themes"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'themes'
}

# =============================================================================
# preview_theme
# =============================================================================

@test "preview_theme function exists" {
    declare -F preview_theme
}

@test "preview_theme displays theme name" {
    run preview_theme "cyberpunk"
    assert_success
    assert_output_contains "Cyberpunk"
}

@test "preview_theme displays color labels" {
    run preview_theme "cyberpunk"
    assert_success
    assert_output_contains "accent:"
    assert_output_contains "bg:"
    assert_output_contains "fg:"
}

@test "preview_theme displays hex values" {
    run preview_theme "cyberpunk"
    assert_success
    # Should contain hex color codes
    assert_output_contains "#"
}

@test "preview_theme displays separators" {
    run preview_theme "cyberpunk"
    assert_success
    assert_output_contains "Separators:"
}

@test "preview_theme fails for non-existing theme" {
    run preview_theme "nonexistent"
    assert_failure
}

@test "preview_theme works for matrix theme" {
    run preview_theme "matrix"
    assert_success
    assert_output_contains "Matrix"
}

# =============================================================================
# theme_gallery
# =============================================================================

@test "theme_gallery function exists" {
    declare -F theme_gallery
}

@test "theme_gallery displays all themes" {
    run theme_gallery
    assert_success
    assert_output_contains "Cyberpunk"
    assert_output_contains "Matrix"
    assert_output_contains "Dracula"
}

@test "theme_gallery displays gallery header" {
    run theme_gallery
    assert_success
    assert_output_contains "Theme Gallery"
}

# =============================================================================
# cmd_theme --preview integration
# =============================================================================

@test "cmd_theme --preview calls preview for all themes" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    run cmd_theme --preview
    assert_success
    assert_output_contains "Cyberpunk"
    assert_output_contains "Matrix"
}

# =============================================================================
# cmd_update
# =============================================================================

@test "cmd_update function exists" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    declare -F cmd_update
}

@test "cmd_update detects pimpmyshell root directory" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    run cmd_update
    # Should attempt update from the root directory (may warn if not a git repo)
    # but should not crash
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "cmd_update shows version or error info" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    run cmd_update
    # Should output something meaningful (version info or error about pull)
    [[ -n "$output" ]]
}

@test "cmd_update handles non-git directory gracefully" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    # Override PIMPMYSHELL_ROOT to a non-git directory
    local old_root="$PIMPMYSHELL_ROOT"
    PIMPMYSHELL_ROOT="${PIMPMYSHELL_TEST_DIR}/fakedir"
    mkdir -p "$PIMPMYSHELL_ROOT"
    run cmd_update
    assert_failure
    PIMPMYSHELL_ROOT="$old_root"
}

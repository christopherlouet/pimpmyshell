#!/usr/bin/env bats
# pimpmyshell - Tests for lib/tools.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'tools'
}

# =============================================================================
# Guard
# =============================================================================

@test "tools.sh sets _PIMPMYSHELL_TOOLS_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_TOOLS_LOADED:-}" ]]
}

# =============================================================================
# detect_pkg_manager
# =============================================================================

@test "detect_pkg_manager returns a valid package manager" {
    run detect_pkg_manager
    assert_success
    [[ "$output" =~ ^(apt|dnf|pacman|brew|unknown)$ ]]
}

@test "detect_pkg_manager returns apt on Debian/Ubuntu" {
    if ! command -v apt &>/dev/null; then
        skip "apt not available"
    fi
    run detect_pkg_manager
    assert_success
    assert_output_contains "apt"
}

@test "detect_pkg_manager returns brew on macOS" {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "Not macOS"
    fi
    run detect_pkg_manager
    assert_success
    assert_output_contains "brew"
}

# =============================================================================
# get_tool_command - Command name resolution
# =============================================================================

@test "get_tool_command returns eza for eza" {
    run get_tool_command "eza"
    assert_success
    assert_output_contains "eza"
}

@test "get_tool_command resolves bat command name" {
    run get_tool_command "bat"
    assert_success
    # Returns 'bat' or 'batcat' depending on platform
    [[ "$output" == "bat" || "$output" == "batcat" ]]
}

@test "get_tool_command resolves fd command name" {
    run get_tool_command "fd"
    assert_success
    # Returns 'fd' or 'fdfind' depending on platform
    [[ "$output" == "fd" || "$output" == "fdfind" ]]
}

@test "get_tool_command returns rg for ripgrep" {
    run get_tool_command "ripgrep"
    assert_success
    assert_output_contains "rg"
}

@test "get_tool_command returns delta for delta" {
    run get_tool_command "delta"
    assert_success
    assert_output_contains "delta"
}

@test "get_tool_command returns starship for starship" {
    run get_tool_command "starship"
    assert_success
    assert_output_contains "starship"
}

@test "get_tool_command returns zoxide for zoxide" {
    run get_tool_command "zoxide"
    assert_success
    assert_output_contains "zoxide"
}

@test "get_tool_command returns fzf for fzf" {
    run get_tool_command "fzf"
    assert_success
    assert_output_contains "fzf"
}

@test "get_tool_command returns tldr for tldr" {
    run get_tool_command "tldr"
    assert_success
    assert_output_contains "tldr"
}

@test "get_tool_command returns dust for dust" {
    run get_tool_command "dust"
    assert_success
    assert_output_contains "dust"
}

@test "get_tool_command returns duf for duf" {
    run get_tool_command "duf"
    assert_success
    assert_output_contains "duf"
}

@test "get_tool_command returns btop for btop" {
    run get_tool_command "btop"
    assert_success
    assert_output_contains "btop"
}

@test "get_tool_command returns hyperfine for hyperfine" {
    run get_tool_command "hyperfine"
    assert_success
    assert_output_contains "hyperfine"
}

@test "get_tool_command returns name for unknown tool" {
    run get_tool_command "unknown_tool_xyz"
    assert_success
    assert_output_contains "unknown_tool_xyz"
}

# =============================================================================
# is_tool_installed
# =============================================================================

@test "is_tool_installed returns true for bash" {
    run is_tool_installed "bash"
    assert_success
}

@test "is_tool_installed returns false for non-existent tool" {
    run is_tool_installed "nonexistent_tool_xyz_12345"
    assert_failure
}

@test "is_tool_installed checks resolved command name" {
    # This checks that is_tool_installed uses get_tool_command internally
    if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
        run is_tool_installed "bat"
        assert_success
    else
        run is_tool_installed "bat"
        assert_failure
    fi
}

# =============================================================================
# get_tool_pkg_name - Package name resolution
# =============================================================================

@test "get_tool_pkg_name returns correct apt package for bat" {
    run get_tool_pkg_name "bat" "apt"
    assert_success
    assert_output_contains "bat"
}

@test "get_tool_pkg_name returns correct apt package for fd" {
    run get_tool_pkg_name "fd" "apt"
    assert_success
    assert_output_contains "fd-find"
}

@test "get_tool_pkg_name returns correct apt package for ripgrep" {
    run get_tool_pkg_name "ripgrep" "apt"
    assert_success
    assert_output_contains "ripgrep"
}

@test "get_tool_pkg_name returns correct apt package for delta" {
    run get_tool_pkg_name "delta" "apt"
    assert_success
    assert_output_contains "git-delta"
}

@test "get_tool_pkg_name returns correct brew package for bat" {
    run get_tool_pkg_name "bat" "brew"
    assert_success
    assert_output_contains "bat"
}

@test "get_tool_pkg_name returns tool name for unknown pkg manager" {
    run get_tool_pkg_name "eza" "unknown_pm"
    assert_success
    assert_output_contains "eza"
}

# =============================================================================
# get_tool_alt_install - Alternative install commands
# =============================================================================

@test "get_tool_alt_install returns cargo command for eza" {
    run get_tool_alt_install "eza"
    assert_success
    assert_output_contains "cargo"
}

@test "get_tool_alt_install returns curl command for starship" {
    run get_tool_alt_install "starship"
    assert_success
    assert_output_contains "curl"
}

@test "get_tool_alt_install returns empty for unknown tool" {
    run get_tool_alt_install "unknown_tool_xyz"
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# check_tools - Status reporting
# =============================================================================

@test "check_tools runs without error" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"
    export PIMPMYSHELL_VERBOSITY=1

    run check_tools
    assert_success
}

@test "check_tools reports installed tools" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"
    export PIMPMYSHELL_VERBOSITY=1

    run check_tools
    assert_success
    # Should produce some output (tool status)
    [[ -n "$output" ]]
}

# =============================================================================
# get_all_tools - Tool listing
# =============================================================================

@test "get_all_tools returns required tools" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_all_tools "required"
    assert_success
    assert_output_contains "eza"
    assert_output_contains "bat"
}

@test "get_all_tools returns empty for missing section" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/minimal.yaml"
    echo "theme: cyberpunk" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_all_tools "required"
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# Edge cases
# =============================================================================

@test "tools functions handle missing config gracefully" {
    export PIMPMYSHELL_CONFIG_FILE="/nonexistent/config.yaml"
    run get_all_tools "required"
    assert_success
}

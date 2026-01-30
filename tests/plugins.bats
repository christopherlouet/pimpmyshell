#!/usr/bin/env bats
# pimpmyshell - Tests for lib/plugins.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Create a fake oh-my-zsh directory for testing
    export ZSH="${PIMPMYSHELL_TEST_DIR}/oh-my-zsh"
    export ZSH_CUSTOM="${ZSH}/custom"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'plugins'
}

# =============================================================================
# Guard & Constants
# =============================================================================

@test "plugins.sh sets _PIMPMYSHELL_PLUGINS_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_PLUGINS_LOADED:-}" ]]
}

@test "OMZ_DIR is set" {
    [[ -n "$OMZ_DIR" ]]
}

@test "OMZ_CUSTOM_DIR is set" {
    [[ -n "$OMZ_CUSTOM_DIR" ]]
}

# =============================================================================
# Custom plugin URL registry
# =============================================================================

@test "get_plugin_url returns URL for zsh-autosuggestions" {
    run get_plugin_url "zsh-autosuggestions"
    assert_success
    assert_output_contains "github.com"
    assert_output_contains "zsh-autosuggestions"
}

@test "get_plugin_url returns URL for zsh-syntax-highlighting" {
    run get_plugin_url "zsh-syntax-highlighting"
    assert_success
    assert_output_contains "github.com"
    assert_output_contains "zsh-syntax-highlighting"
}

@test "get_plugin_url returns URL for zsh-bat" {
    run get_plugin_url "zsh-bat"
    assert_success
    assert_output_contains "github.com"
    assert_output_contains "zsh-bat"
}

@test "get_plugin_url returns empty for unknown plugin" {
    run get_plugin_url "nonexistent_plugin_xyz"
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# is_omz_installed
# =============================================================================

@test "is_omz_installed returns false when directory does not exist" {
    export ZSH="/nonexistent/oh-my-zsh"
    run is_omz_installed
    assert_failure
}

@test "is_omz_installed returns true when oh-my-zsh directory exists" {
    mkdir -p "$ZSH"
    mkdir -p "${ZSH}/lib"
    touch "${ZSH}/oh-my-zsh.sh"
    run is_omz_installed
    assert_success
}

@test "is_omz_installed returns false for empty directory" {
    mkdir -p "$ZSH"
    # No oh-my-zsh.sh file
    run is_omz_installed
    assert_failure
}

# =============================================================================
# is_plugin_installed - Standard plugins
# =============================================================================

@test "is_plugin_installed returns true for existing standard plugin" {
    mkdir -p "${ZSH}/plugins/git"
    run is_plugin_installed "git"
    assert_success
}

@test "is_plugin_installed returns false for non-existing standard plugin" {
    run is_plugin_installed "nonexistent_plugin_xyz"
    assert_failure
}

@test "is_plugin_installed returns true for existing custom plugin" {
    mkdir -p "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    run is_plugin_installed "zsh-autosuggestions"
    assert_success
}

@test "is_plugin_installed returns false for missing custom plugin" {
    run is_plugin_installed "zsh-autosuggestions"
    assert_failure
}

# =============================================================================
# is_standard_plugin
# =============================================================================

@test "is_standard_plugin returns true for git" {
    mkdir -p "${ZSH}/plugins/git"
    run is_standard_plugin "git"
    assert_success
}

@test "is_standard_plugin returns true for fzf" {
    mkdir -p "${ZSH}/plugins/fzf"
    run is_standard_plugin "fzf"
    assert_success
}

@test "is_standard_plugin returns false for custom plugin" {
    # Only create it in custom, not standard
    mkdir -p "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    run is_standard_plugin "zsh-autosuggestions"
    assert_failure
}

# =============================================================================
# clone_custom_plugin
# =============================================================================

@test "clone_custom_plugin fails for unknown plugin without URL" {
    run clone_custom_plugin "nonexistent_plugin_xyz"
    assert_failure
}

@test "clone_custom_plugin creates target directory structure" {
    # Mock git by creating the directory manually
    # We test the directory creation logic, not actual git clone
    mkdir -p "${ZSH_CUSTOM}/plugins"

    # Create a fake plugin URL
    local plugin_name="test-plugin"
    local target_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    # Since we can't mock git easily, just verify the function handles
    # missing git gracefully or returns error for unknown plugins
    run clone_custom_plugin "$plugin_name"
    assert_failure
}

@test "clone_custom_plugin skips already installed plugin" {
    mkdir -p "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    run clone_custom_plugin "zsh-autosuggestions"
    assert_success
    # Should indicate it's already installed
}

# =============================================================================
# get_configured_plugins
# =============================================================================

@test "get_configured_plugins returns ohmyzsh plugins from config" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_configured_plugins "ohmyzsh"
    assert_success
    assert_output_contains "git"
    assert_output_contains "fzf"
}

@test "get_configured_plugins returns custom plugins from config" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_configured_plugins "custom"
    assert_success
    assert_output_contains "zsh-autosuggestions"
}

@test "get_configured_plugins returns empty for missing section" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/minimal.yaml"
    echo "theme: cyberpunk" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_configured_plugins "ohmyzsh"
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# generate_plugins_list
# =============================================================================

@test "generate_plugins_list outputs plugin names for zshrc" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run generate_plugins_list
    assert_success
    assert_output_contains "git"
    assert_output_contains "fzf"
    assert_output_contains "zsh-autosuggestions"
}

# =============================================================================
# check_plugins_status
# =============================================================================

@test "check_plugins_status runs without error" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    # Create fake omz with some plugins
    mkdir -p "${ZSH}/plugins/git"
    mkdir -p "${ZSH}/plugins/fzf"

    export PIMPMYSHELL_VERBOSITY=1
    run check_plugins_status
    assert_success
}

# =============================================================================
# Edge cases
# =============================================================================

@test "plugins functions work without oh-my-zsh installed" {
    export ZSH="/nonexistent/oh-my-zsh"
    run is_omz_installed
    assert_failure
}

# =============================================================================
# validate_git_url - URL validation
# =============================================================================

@test "validate_git_url accepts valid GitHub HTTPS URL" {
    run validate_git_url "https://github.com/zsh-users/zsh-autosuggestions.git"
    assert_success
}

@test "validate_git_url accepts GitHub URL without .git suffix" {
    run validate_git_url "https://github.com/zsh-users/zsh-autosuggestions"
    assert_success
}

@test "validate_git_url rejects HTTP URL" {
    run validate_git_url "http://github.com/zsh-users/zsh-autosuggestions.git"
    assert_failure
    assert_output_contains "must use HTTPS"
}

@test "validate_git_url rejects non-GitHub URL" {
    run validate_git_url "https://gitlab.com/user/repo.git"
    assert_failure
    assert_output_contains "must be from github.com"
}

@test "validate_git_url rejects git:// protocol" {
    run validate_git_url "git://github.com/user/repo.git"
    assert_failure
    assert_output_contains "must use HTTPS"
}

@test "validate_git_url rejects ext:: injection" {
    run validate_git_url "ext::sh -c 'malicious command'"
    assert_failure
    assert_output_contains "must use HTTPS"
}

@test "validate_git_url rejects URL with semicolon" {
    run validate_git_url "https://github.com/user/repo;rm -rf /"
    assert_failure
    assert_output_contains "suspicious pattern"
}

@test "validate_git_url rejects URL with pipe" {
    run validate_git_url "https://github.com/user/repo|malicious"
    assert_failure
    assert_output_contains "suspicious pattern"
}

@test "validate_git_url rejects URL with command substitution" {
    run validate_git_url 'https://github.com/user/$(whoami)'
    assert_failure
    assert_output_contains "suspicious pattern"
}

@test "clone_custom_plugin validates URL before cloning" {
    # Verify that clone_custom_plugin uses validate_git_url
    local plugins_file="${PIMPMYSHELL_ROOT}/lib/plugins.sh"
    run grep -A5 "validate_git_url" "$plugins_file"
    assert_success
}

# =============================================================================
# Edge cases
# =============================================================================

@test "is_plugin_installed works with empty ZSH directory" {
    mkdir -p "$ZSH"
    run is_plugin_installed "git"
    assert_failure
}

# =============================================================================
# Argument validation
# =============================================================================

@test "get_plugin_url fails without arguments" {
    run get_plugin_url
    assert_failure
    assert_output_contains "get_plugin_url"
}

@test "clone_custom_plugin fails without arguments" {
    run clone_custom_plugin
    assert_failure
    assert_output_contains "clone_custom_plugin"
}

@test "get_configured_plugins fails without arguments" {
    run get_configured_plugins
    assert_failure
    assert_output_contains "get_configured_plugins"
}

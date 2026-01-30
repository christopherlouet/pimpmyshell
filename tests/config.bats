#!/usr/bin/env bats
# pimpmyshell - Tests for lib/config.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Load core first, then config
    load_lib 'core'
    load_lib 'config'
}

# =============================================================================
# Guard & Constants
# =============================================================================

@test "config.sh sets _PIMPMYSHELL_CONFIG_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_CONFIG_LOADED:-}" ]]
}

@test "DEFAULT_THEME is cyberpunk" {
    [[ "$DEFAULT_THEME" == "cyberpunk" ]]
}

@test "DEFAULT_FRAMEWORK is ohmyzsh" {
    [[ "$DEFAULT_FRAMEWORK" == "ohmyzsh" ]]
}

@test "DEFAULT_PROMPT_ENGINE is starship" {
    [[ "$DEFAULT_PROMPT_ENGINE" == "starship" ]]
}

@test "DEFAULT_CONFIG_FILE points to pimpmyshell.yaml" {
    [[ "$DEFAULT_CONFIG_FILE" == *"pimpmyshell.yaml" ]]
}

# =============================================================================
# yq detection
# =============================================================================

@test "detect_yq_version returns go, python, or empty" {
    run detect_yq_version
    assert_success
    [[ "$output" == "go" || "$output" == "python" || -z "$output" ]]
}

@test "require_yq succeeds when yq is installed" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    run require_yq
    assert_success
}

@test "require_yq fails when yq is missing" {
    # Temporarily hide yq by using a subshell with modified PATH
    run bash -c '
        export PATH="/nonexistent"
        source "'"${PIMPMYSHELL_LIB_DIR}/core.sh"'"
        source "'"${PIMPMYSHELL_LIB_DIR}/config.sh"'"
        require_yq
    '
    assert_failure
}

# =============================================================================
# yq_get - Read YAML values
# =============================================================================

@test "yq_get reads simple string value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)

    run yq_get "$config_file" '.theme'
    assert_success
    assert_output_contains "cyberpunk"
}

@test "yq_get reads nested value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)

    run yq_get "$config_file" '.shell.framework'
    assert_success
    assert_output_contains "ohmyzsh"
}

@test "yq_get returns empty for missing key" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)

    run yq_get "$config_file" '.nonexistent_key'
    assert_success
    [[ -z "$output" || "$output" == "" ]]
}

@test "yq_get fails for non-existent file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    run yq_get "/nonexistent/file.yaml" '.theme'
    assert_failure
}

@test "yq_get reads boolean value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)

    run yq_get "$config_file" '.aliases.enabled'
    assert_success
    assert_output_contains "true"
}

# =============================================================================
# get_config - Read with defaults
# =============================================================================

@test "get_config returns value from config file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config '.theme' 'default_theme'
    assert_success
    assert_output_contains "cyberpunk"
}

@test "get_config returns default when key is missing" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config '.nonexistent' 'fallback_value'
    assert_success
    assert_output_contains "fallback_value"
}

@test "get_config returns default when value is empty" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/empty_key.yaml"
    echo "theme:" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config '.theme' 'cyberpunk'
    assert_success
    assert_output_contains "cyberpunk"
}

@test "get_config uses DEFAULT_CONFIG_FILE when PIMPMYSHELL_CONFIG_FILE is not set" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    unset PIMPMYSHELL_CONFIG_FILE
    local config_file="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
    mkdir -p "$(dirname "$config_file")"
    echo "theme: matrix" > "$config_file"

    run get_config '.theme' 'cyberpunk'
    assert_success
    assert_output_contains "matrix"
}

# =============================================================================
# config_enabled - Boolean config
# =============================================================================

@test "config_enabled returns true for 'true' value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run config_enabled '.aliases.enabled'
    assert_success
}

@test "config_enabled returns false for missing key" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run config_enabled '.nonexistent.key'
    assert_failure
}

@test "config_enabled handles 'yes' as true" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/yes_config.yaml"
    echo "feature_enabled: yes" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run config_enabled '.feature_enabled'
    assert_success
}

@test "config_enabled handles '1' as true" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/one_config.yaml"
    echo "feature_enabled: 1" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run config_enabled '.feature_enabled'
    assert_success
}

@test "config_enabled returns false for 'false' value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/false_config.yaml"
    echo "feature_enabled: false" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run config_enabled '.feature_enabled'
    assert_failure
}

# =============================================================================
# get_config_list - Read YAML lists
# =============================================================================

@test "get_config_list returns list items" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config_list '.plugins.ohmyzsh'
    assert_success
    assert_output_contains "git"
    assert_output_contains "fzf"
}

@test "get_config_list returns custom plugins" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config_list '.plugins.custom'
    assert_success
    assert_output_contains "zsh-autosuggestions"
}

@test "get_config_list returns tools list" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config_list '.tools.required'
    assert_success
    assert_output_contains "eza"
    assert_output_contains "bat"
}

@test "get_config_list returns empty for missing key" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config_list '.nonexistent.list'
    assert_success
    [[ -z "$output" || "$output" == "" ]]
}

@test "get_config_list returns alias groups" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config_list '.aliases.groups'
    assert_success
    assert_output_contains "git"
    assert_output_contains "files"
}

# =============================================================================
# Edge cases
# =============================================================================

@test "get_config handles minimal config file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/minimal.yaml"
    echo "theme: nord" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config '.theme' 'cyberpunk'
    assert_success
    assert_output_contains "nord"
}

@test "get_config handles config with only comments" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/comments.yaml"
    echo "# This is a comment" > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config '.theme' 'cyberpunk'
    assert_success
    assert_output_contains "cyberpunk"
}

@test "config functions work with spaces in values" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/spaces.yaml"
    echo 'custom_message: "Hello World"' > "$config_file"
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run get_config '.custom_message' ''
    assert_success
    assert_output_contains "Hello World"
}

# =============================================================================
# Argument validation
# =============================================================================

@test "yq_get fails without arguments" {
    run yq_get
    assert_failure
    assert_output_contains "yq_get"
}

@test "get_config fails without arguments" {
    run get_config
    assert_failure
    assert_output_contains "get_config"
}

@test "set_config fails without arguments" {
    run set_config
    assert_failure
    assert_output_contains "set_config"
}

@test "config_enabled fails without arguments" {
    run config_enabled
    assert_failure
    assert_output_contains "config_enabled"
}

@test "get_config_list fails without arguments" {
    run get_config_list
    assert_failure
    assert_output_contains "get_config_list"
}

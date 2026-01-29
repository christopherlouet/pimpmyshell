#!/usr/bin/env bats
# pimpmyshell - Tests for lib/wizard.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME"
    mkdir -p "$HOME/.config"

    export PIMPMYSHELL_THEMES_DIR="${PIMPMYSHELL_ROOT}/themes"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'themes'
    load_lib 'plugins'
    load_lib 'tools'
    load_lib 'wizard'
}

# =============================================================================
# Guard
# =============================================================================

@test "wizard.sh sets _PIMPMYSHELL_WIZARD_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_WIZARD_LOADED:-}" ]]
}

# =============================================================================
# _use_gum
# =============================================================================

@test "_use_gum function exists" {
    declare -F _use_gum
}

@test "_use_gum returns status based on gum availability" {
    # Should not crash regardless of gum presence
    _use_gum || true
}

# =============================================================================
# _wizard_header
# =============================================================================

@test "_wizard_header function exists" {
    declare -F _wizard_header
}

@test "_wizard_header outputs title text" {
    run _wizard_header "Test Title"
    assert_success
    assert_output_contains "Test Title"
}

# =============================================================================
# _wizard_step
# =============================================================================

@test "_wizard_step function exists" {
    declare -F _wizard_step
}

@test "_wizard_step shows step number and description" {
    run _wizard_step 1 5 "Choose theme"
    assert_success
    assert_output_contains "1"
    assert_output_contains "5"
    assert_output_contains "Choose theme"
}

# =============================================================================
# _wizard_choose (non-interactive testing via env override)
# =============================================================================

@test "_wizard_choose function exists" {
    declare -F _wizard_choose
}

@test "_wizard_choose returns first option when WIZARD_AUTO is set" {
    export WIZARD_AUTO=1
    run _wizard_choose "Pick one:" "alpha" "beta" "gamma"
    assert_success
    assert_output_contains "alpha"
}

@test "_wizard_choose returns specified default when WIZARD_AUTO is set" {
    export WIZARD_AUTO=1
    export WIZARD_DEFAULT="beta"
    run _wizard_choose "Pick one:" "alpha" "beta" "gamma"
    assert_success
    assert_output_contains "beta"
    unset WIZARD_DEFAULT
}

# =============================================================================
# _wizard_choose_multi (non-interactive testing)
# =============================================================================

@test "_wizard_choose_multi function exists" {
    declare -F _wizard_choose_multi
}

@test "_wizard_choose_multi returns all options when WIZARD_AUTO is set" {
    export WIZARD_AUTO=1
    run _wizard_choose_multi "Pick many:" "git" "docker" "kubernetes"
    assert_success
    assert_output_contains "git"
    assert_output_contains "docker"
    assert_output_contains "kubernetes"
}

# =============================================================================
# _wizard_confirm (non-interactive testing)
# =============================================================================

@test "_wizard_confirm function exists" {
    declare -F _wizard_confirm
}

@test "_wizard_confirm returns default true when WIZARD_AUTO is set" {
    export WIZARD_AUTO=1
    run _wizard_confirm "Continue?" "true"
    assert_success
    assert_output_contains "true"
}

@test "_wizard_confirm returns default false when specified" {
    export WIZARD_AUTO=1
    run _wizard_confirm "Continue?" "false"
    assert_success
    assert_output_contains "false"
}

# =============================================================================
# _wizard_input (non-interactive testing)
# =============================================================================

@test "_wizard_input function exists" {
    declare -F _wizard_input
}

@test "_wizard_input returns default when WIZARD_AUTO is set" {
    export WIZARD_AUTO=1
    run _wizard_input "Enter name:" "default_value"
    assert_success
    assert_output_contains "default_value"
}

# =============================================================================
# _wizard_generate_config
# =============================================================================

@test "_wizard_generate_config function exists" {
    declare -F _wizard_generate_config
}

@test "_wizard_generate_config creates YAML file" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    # Set wizard variables
    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git fzf"
    export WIZARD_CUSTOM_PLUGINS="zsh-autosuggestions"
    export WIZARD_ALIAS_GROUPS="git files"
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"
    assert_file_exists "$config_file"
}

@test "_wizard_generate_config includes theme" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    export WIZARD_THEME="matrix"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS="git"
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "theme: matrix"
}

@test "_wizard_generate_config includes framework" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "framework: ohmyzsh"
}

@test "_wizard_generate_config includes prompt engine" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "engine: starship"
}

@test "_wizard_generate_config includes omz plugins" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git fzf docker"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "- git"
    assert_file_contains "$config_file" "- fzf"
    assert_file_contains "$config_file" "- docker"
}

@test "_wizard_generate_config includes custom plugins" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS="zsh-autosuggestions zsh-syntax-highlighting"
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "- zsh-autosuggestions"
    assert_file_contains "$config_file" "- zsh-syntax-highlighting"
}

@test "_wizard_generate_config includes alias groups" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS="git docker navigation"
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "- git"
    assert_file_contains "$config_file" "- docker"
    assert_file_contains "$config_file" "- navigation"
}

@test "_wizard_generate_config produces valid YAML" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/generated.yaml"

    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git fzf"
    export WIZARD_CUSTOM_PLUGINS="zsh-autosuggestions"
    export WIZARD_ALIAS_GROUPS="git files"
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config "$config_file"

    # Validate YAML syntax with yq
    if command -v yq &>/dev/null; then
        run yq eval '.' "$config_file"
        assert_success
    fi
}

@test "_wizard_generate_config uses default config dir when no path given" {
    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"

    _wizard_generate_config
    assert_file_exists "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
}

# =============================================================================
# run_wizard (auto mode)
# =============================================================================

@test "run_wizard function exists" {
    declare -F run_wizard
}

@test "run_wizard succeeds in auto mode" {
    export WIZARD_AUTO=1

    run run_wizard
    assert_success
}

@test "run_wizard generates config in auto mode" {
    export WIZARD_AUTO=1

    run_wizard
    assert_file_exists "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
}

@test "run_wizard config contains theme in auto mode" {
    export WIZARD_AUTO=1

    run_wizard
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "theme:"
}

@test "run_wizard config contains plugins section in auto mode" {
    export WIZARD_AUTO=1

    run_wizard
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "plugins:"
}

# =============================================================================
# CLI integration
# =============================================================================

@test "cmd_wizard calls run_wizard" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"

    export WIZARD_AUTO=1

    run cmd_wizard
    assert_success
}

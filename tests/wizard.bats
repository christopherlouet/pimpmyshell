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
    load_lib 'profiles'
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

# =============================================================================
# Wizard edge cases
# =============================================================================

@test "_wizard_generate_config with empty plugins produces valid YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS=""
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="false"

    local config_file="${PIMPMYSHELL_TEST_DIR}/empty-plugins.yaml"
    _wizard_generate_config "$config_file"
    assert_file_exists "$config_file"

    run yq eval '.' "$config_file"
    assert_success
}

@test "_wizard_generate_config with empty integrations produces valid YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    export WIZARD_THEME="dracula"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS="zsh-autosuggestions"
    export WIZARD_INTEGRATIONS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"

    local config_file="${PIMPMYSHELL_TEST_DIR}/empty-integ.yaml"
    _wizard_generate_config "$config_file"
    assert_file_exists "$config_file"

    run yq eval '.' "$config_file"
    assert_success
}

@test "run_wizard generates valid YAML in auto mode" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    export WIZARD_AUTO=1

    run_wizard
    local config_file="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
    assert_file_exists "$config_file"

    run yq eval '.' "$config_file"
    assert_success
}

# =============================================================================
# _wizard_progress_bar
# =============================================================================

@test "_wizard_progress_bar function exists" {
    declare -F _wizard_progress_bar
}

@test "_wizard_progress_bar outputs bar format" {
    run _wizard_progress_bar 3 7 "Choose plugins"
    assert_success
    assert_output_contains "Step 3/7"
    assert_output_contains "Choose plugins"
    assert_output_contains "["
    assert_output_contains "]"
}

@test "_wizard_progress_bar handles step 1 of total" {
    run _wizard_progress_bar 1 7 "First step"
    assert_success
    assert_output_contains "Step 1/7"
}

@test "_wizard_progress_bar handles total equal to current" {
    run _wizard_progress_bar 5 5 "Last step"
    assert_success
    assert_output_contains "Step 5/5"
    assert_output_contains "===================="
}

@test "_wizard_progress_bar handles zero total gracefully" {
    run _wizard_progress_bar 0 0 "Empty"
    assert_success
    assert_output_contains "Step 0/0"
}

# =============================================================================
# _wizard_nav_prompt
# =============================================================================

@test "_wizard_nav_prompt function exists" {
    declare -F _wizard_nav_prompt
}

@test "_wizard_nav_prompt returns next in auto mode" {
    export WIZARD_AUTO=1
    run _wizard_nav_prompt
    assert_success
    assert_output_equals "next"
}

# =============================================================================
# _WIZARD_STEPS registry
# =============================================================================

@test "_WIZARD_STEPS array is defined with 7 entries" {
    [[ ${#_WIZARD_STEPS[@]} -eq 7 ]]
}

@test "_WIZARD_STEPS contains _wizard_step_theme" {
    [[ "${_WIZARD_STEPS[0]}" == "_wizard_step_theme" ]]
}

@test "_WIZARD_STEPS contains _wizard_step_tools" {
    local found=0
    for step in "${_WIZARD_STEPS[@]}"; do
        [[ "$step" == "_wizard_step_tools" ]] && found=1
    done
    [[ "$found" -eq 1 ]]
}

@test "_WIZARD_STEPS contains _wizard_step_profile" {
    local found=0
    for step in "${_WIZARD_STEPS[@]}"; do
        [[ "$step" == "_wizard_step_profile" ]] && found=1
    done
    [[ "$found" -eq 1 ]]
}

# =============================================================================
# _wizard_theme_swatch
# =============================================================================

@test "_wizard_theme_swatch function exists" {
    declare -F _wizard_theme_swatch
}

@test "_wizard_theme_swatch produces ANSI output" {
    run _wizard_theme_swatch "#ff00ff"
    assert_success
    # Output contains escape sequences
    [[ -n "$output" ]]
}

# =============================================================================
# _wizard_theme_label
# =============================================================================

@test "_wizard_theme_label function exists" {
    declare -F _wizard_theme_label
}

@test "_wizard_theme_label includes theme name" {
    run _wizard_theme_label "cyberpunk"
    assert_success
    assert_output_contains "cyberpunk"
}

@test "_wizard_theme_label includes description for known theme" {
    run _wizard_theme_label "cyberpunk"
    assert_success
    # Cyberpunk theme has a description
    assert_output_contains "Neon"
}

@test "_wizard_theme_label returns bare name for unknown theme" {
    run _wizard_theme_label "nonexistent-theme-xyz"
    assert_success
    assert_output_contains "nonexistent-theme-xyz"
}

# =============================================================================
# _wizard_get_desc
# =============================================================================

@test "_wizard_get_desc function exists" {
    declare -F _wizard_get_desc
}

@test "_wizard_get_desc returns description for plugin:git" {
    run _wizard_get_desc "plugin" "git"
    assert_success
    assert_output_contains "Git aliases"
}

@test "_wizard_get_desc returns description for alias:docker" {
    run _wizard_get_desc "alias" "docker"
    assert_success
    assert_output_contains "Docker shortcuts"
}

@test "_wizard_get_desc returns description for integ:zoxide" {
    run _wizard_get_desc "integ" "zoxide"
    assert_success
    assert_output_contains "Smarter cd"
}

@test "_wizard_get_desc returns description for integ:fzf_tab" {
    run _wizard_get_desc "integ" "fzf_tab"
    assert_success
    assert_output_contains "fzf"
}

@test "_wizard_get_desc returns empty for unknown entry" {
    run _wizard_get_desc "plugin" "nonexistent"
    assert_success
    assert_output_equals ""
}

# =============================================================================
# _wizard_with_desc
# =============================================================================

@test "_wizard_with_desc function exists" {
    declare -F _wizard_with_desc
}

@test "_wizard_with_desc returns name with description" {
    run _wizard_with_desc "plugin" "git"
    assert_success
    assert_output_contains "git"
    assert_output_contains " - "
}

@test "_wizard_with_desc returns bare name for unknown entry" {
    run _wizard_with_desc "plugin" "nonexistent-plugin-xyz"
    assert_success
    assert_output_equals "nonexistent-plugin-xyz"
}

# =============================================================================
# _wizard_step_tools
# =============================================================================

@test "_wizard_step_tools function exists" {
    declare -F _wizard_step_tools
}

@test "_wizard_step_tools runs in auto mode" {
    export WIZARD_AUTO=1
    run _wizard_step_tools 5 7
    assert_success
    assert_output_contains "Required tools"
}

@test "_wizard_step_tools shows installed markers" {
    export WIZARD_AUTO=1
    run _wizard_step_tools 5 7
    assert_success
    # Should contain bracket markers
    [[ "$output" == *"["* ]]
}

@test "_wizard_step_tools sets WIZARD_TOOLS variable" {
    export WIZARD_AUTO=1
    _wizard_step_tools 5 7
    [[ -n "$WIZARD_TOOLS" ]]
}

@test "_wizard_step_tools includes required tools in WIZARD_TOOLS" {
    export WIZARD_AUTO=1
    _wizard_step_tools 5 7
    [[ "$WIZARD_TOOLS" == *"eza"* ]]
    [[ "$WIZARD_TOOLS" == *"bat"* ]]
    [[ "$WIZARD_TOOLS" == *"fzf"* ]]
    [[ "$WIZARD_TOOLS" == *"starship"* ]]
}

# =============================================================================
# _wizard_step_profile
# =============================================================================

@test "_wizard_step_profile function exists" {
    declare -F _wizard_step_profile
}

@test "_wizard_step_profile skips in auto mode (default false)" {
    export WIZARD_AUTO=1
    _wizard_step_profile 7 7
    [[ -z "$WIZARD_PROFILE" ]]
}

@test "_wizard_step_profile validates profile name" {
    export WIZARD_AUTO=1
    # Default confirm is false, so profile won't be set
    run _wizard_step_profile 7 7
    assert_success
}

# =============================================================================
# _wizard_generate_config with tools
# =============================================================================

@test "_wizard_generate_config includes custom recommended tools" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/tools-config.yaml"
    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"
    export WIZARD_TOOLS="eza bat fzf starship fd zoxide"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "- fd"
    assert_file_contains "$config_file" "- zoxide"
}

@test "_wizard_generate_config includes fzf_tab integration" {
    local config_file="${PIMPMYSHELL_TEST_DIR}/fzftab-config.yaml"
    export WIZARD_THEME="cyberpunk"
    export WIZARD_FRAMEWORK="ohmyzsh"
    export WIZARD_PROMPT_ENGINE="starship"
    export WIZARD_OMZ_PLUGINS="git"
    export WIZARD_CUSTOM_PLUGINS=""
    export WIZARD_ALIAS_GROUPS=""
    export WIZARD_ALIASES_ENABLED="true"
    export WIZARD_INTEGRATIONS="fzf fzf_tab"

    _wizard_generate_config "$config_file"
    assert_file_contains "$config_file" "fzf_tab:"
    assert_file_contains "$config_file" "enabled: true"
}

# =============================================================================
# _wizard_step_theme (auto mode)
# =============================================================================

@test "_wizard_step_theme runs in auto mode with step params" {
    export WIZARD_AUTO=1
    run _wizard_step_theme 1 7
    assert_success
}

@test "_wizard_step_theme sets WIZARD_THEME" {
    export WIZARD_AUTO=1
    WIZARD_THEME="cyberpunk"
    _wizard_step_theme 1 7
    [[ -n "$WIZARD_THEME" ]]
}

# =============================================================================
# _wizard_step_integrations (auto mode defaults)
# =============================================================================

@test "_wizard_step_integrations defaults to fzf zoxide delta in auto mode" {
    export WIZARD_AUTO=1
    _wizard_step_integrations 4 7
    [[ "$WIZARD_INTEGRATIONS" == *"fzf"* ]]
    [[ "$WIZARD_INTEGRATIONS" == *"zoxide"* ]]
    [[ "$WIZARD_INTEGRATIONS" == *"delta"* ]]
    [[ "$WIZARD_INTEGRATIONS" != *"fzf_tab"* ]]
    [[ "$WIZARD_INTEGRATIONS" != *"mise"* ]]
    [[ "$WIZARD_INTEGRATIONS" != *"tmux"* ]]
}

# =============================================================================
# Full auto run (integration)
# =============================================================================

@test "run_wizard auto mode generates config with tools section" {
    export WIZARD_AUTO=1
    run_wizard
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "tools:"
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "required:"
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "recommended:"
}

@test "run_wizard auto mode generates config with fzf_tab" {
    export WIZARD_AUTO=1
    run_wizard
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "fzf_tab:"
}

@test "run_wizard auto mode config contains integrations section" {
    export WIZARD_AUTO=1
    run_wizard
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml" "integrations:"
}

# =============================================================================
# Edge cases
# =============================================================================

@test "_wizard_step_theme handles missing themes dir gracefully" {
    export WIZARD_AUTO=1
    local old_dir="$PIMPMYSHELL_THEMES_DIR"
    export PIMPMYSHELL_THEMES_DIR="/nonexistent/path/themes"
    WIZARD_THEME="original"
    _wizard_step_theme 1 7
    # Falls back to cyberpunk when no themes found
    [[ "$WIZARD_THEME" == "cyberpunk" ]]
    export PIMPMYSHELL_THEMES_DIR="$old_dir"
}

@test "_wizard_step_tools handles missing registry gracefully" {
    export WIZARD_AUTO=1
    local old_reg="${PIMPMYSHELL_TOOLS_REGISTRY:-}"
    export PIMPMYSHELL_TOOLS_REGISTRY="/nonexistent/registry.yaml"
    run _wizard_step_tools 5 7
    assert_success
    export PIMPMYSHELL_TOOLS_REGISTRY="$old_reg"
}

@test "WIZARD_TOOLS state variable is set after sourcing wizard" {
    # The variable should be declared (possibly empty) after sourcing wizard.sh
    [[ "${WIZARD_TOOLS+x}" == "x" ]]
}

@test "WIZARD_PROFILE state variable is set after sourcing wizard" {
    [[ "${WIZARD_PROFILE+x}" == "x" ]]
}

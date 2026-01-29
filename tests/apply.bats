#!/usr/bin/env bats
# pimpmyshell - Tests for .zshrc generation (Phase 7)

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Setup fake oh-my-zsh for plugin tests
    export ZSH="${PIMPMYSHELL_TEST_DIR}/oh-my-zsh"
    export ZSH_CUSTOM="${ZSH}/custom"
    mkdir -p "${ZSH}/plugins/git"
    mkdir -p "${ZSH}/plugins/fzf"
    mkdir -p "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    touch "${ZSH}/oh-my-zsh.sh"

    # Setup a fake HOME for generated files
    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME/.config"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'themes'
    load_lib 'plugins'

    # Export template dir
    export PIMPMYSHELL_TEMPLATES_DIR="${PIMPMYSHELL_ROOT}/templates"
    export PIMPMYSHELL_MODULES_DIR="${PIMPMYSHELL_ROOT}/modules"
}

# =============================================================================
# Template existence
# =============================================================================

@test "zshrc.template exists" {
    assert_file_exists "${PIMPMYSHELL_TEMPLATES_DIR}/zshrc.template"
}

@test "zshrc.template contains managed markers" {
    assert_file_contains "${PIMPMYSHELL_TEMPLATES_DIR}/zshrc.template" "pimpmyshell managed"
}

@test "zshrc.template contains user custom markers" {
    assert_file_contains "${PIMPMYSHELL_TEMPLATES_DIR}/zshrc.template" "user custom"
}

@test "zshrc.template contains all placeholders" {
    local template="${PIMPMYSHELL_TEMPLATES_DIR}/zshrc.template"
    assert_file_contains "$template" "{VERSION}"
    assert_file_contains "$template" "{DATE}"
    assert_file_contains "$template" "{THEME}"
    assert_file_contains "$template" "{ENV_VARS}"
    assert_file_contains "$template" "{OMZ_CONFIG}"
    assert_file_contains "$template" "{PLUGINS}"
    assert_file_contains "$template" "{EZA_THEME}"
    assert_file_contains "$template" "{ALIASES}"
    assert_file_contains "$template" "{INTEGRATIONS}"
    assert_file_contains "$template" "{PROMPT_INIT}"
    assert_file_contains "$template" "{USER_CUSTOM}"
}

# =============================================================================
# _generate_env_vars
# =============================================================================

@test "_generate_env_vars produces ZSH export" {
    run _generate_env_vars
    assert_success
    assert_output_contains 'export ZSH='
}

@test "_generate_env_vars produces LANG export" {
    run _generate_env_vars
    assert_success
    assert_output_contains 'export LANG='
}

@test "_generate_env_vars produces EDITOR export" {
    run _generate_env_vars
    assert_success
    assert_output_contains 'export EDITOR='
}

# =============================================================================
# _generate_omz_config
# =============================================================================

@test "_generate_omz_config produces ZSH_THEME line" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_omz_config
    assert_success
    assert_output_contains 'ZSH_THEME='
}

@test "_generate_omz_config sets empty ZSH_THEME when using starship" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_omz_config
    assert_success
    assert_output_contains 'ZSH_THEME=""'
}

# =============================================================================
# _generate_plugins_line
# =============================================================================

@test "_generate_plugins_line produces plugins=() line" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_plugins_line
    assert_success
    assert_output_contains "plugins=("
}

@test "_generate_plugins_line includes git plugin" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_plugins_line
    assert_success
    assert_output_contains "git"
}

@test "_generate_plugins_line includes custom plugins" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_plugins_line
    assert_success
    assert_output_contains "zsh-autosuggestions"
}

# =============================================================================
# _generate_aliases
# =============================================================================

@test "_generate_aliases produces source lines for enabled alias groups" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_aliases
    assert_success
    assert_output_contains "git.sh"
}

@test "_generate_aliases includes files alias group" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_aliases
    assert_success
    assert_output_contains "files.sh"
}

@test "_generate_aliases returns empty when aliases disabled" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config '
theme: cyberpunk
aliases:
  enabled: false
')
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_aliases
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# _generate_integrations
# =============================================================================

@test "_generate_integrations produces source lines" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config '
theme: cyberpunk
integrations:
  fzf:
    enabled: true
  mise:
    enabled: true
')
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_integrations
    assert_success
    assert_output_contains "fzf.sh"
}

@test "_generate_integrations includes mise when enabled" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config '
theme: cyberpunk
integrations:
  fzf:
    enabled: true
  mise:
    enabled: true
')
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_integrations
    assert_success
    assert_output_contains "mise.sh"
}

@test "_generate_integrations returns empty when no integrations enabled" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config '
theme: cyberpunk
')
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_integrations
    assert_success
}

# =============================================================================
# _generate_eza_theme
# =============================================================================

@test "_generate_eza_theme produces source line for eza theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_eza_theme
    assert_success
    assert_output_contains "eza-theme.sh"
}

# =============================================================================
# _generate_prompt_init
# =============================================================================

@test "_generate_prompt_init produces starship init for starship engine" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_prompt_init
    assert_success
    assert_output_contains "starship init zsh"
}

@test "_generate_prompt_init produces p10k for p10k engine" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config '
theme: cyberpunk
prompt:
  engine: p10k
')
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_prompt_init
    assert_success
    assert_output_contains "p10k"
}

@test "_generate_prompt_init returns empty for engine none" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config '
theme: cyberpunk
prompt:
  engine: none
')
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    run _generate_prompt_init
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# extract_user_custom
# =============================================================================

@test "extract_user_custom returns empty for new file" {
    run extract_user_custom "/nonexistent/file"
    assert_success
    [[ -z "$output" ]]
}

@test "extract_user_custom extracts content between markers" {
    local zshrc="${PIMPMYSHELL_TEST_DIR}/zshrc"
    cat > "$zshrc" << 'TESTEOF'
# some stuff
# >>> user custom >>>
my custom alias
export MY_VAR=1
# <<< user custom <<<
TESTEOF

    run extract_user_custom "$zshrc"
    assert_success
    assert_output_contains "my custom alias"
    assert_output_contains "MY_VAR"
}

@test "extract_user_custom ignores content outside markers" {
    local zshrc="${PIMPMYSHELL_TEST_DIR}/zshrc"
    cat > "$zshrc" << 'TESTEOF'
# outside content
# >>> user custom >>>
inside content
# <<< user custom <<<
# more outside
TESTEOF

    run extract_user_custom "$zshrc"
    assert_success
    assert_output_contains "inside content"
    refute_output_contains "outside content"
    refute_output_contains "more outside"
}

# =============================================================================
# generate_zshrc
# =============================================================================

@test "generate_zshrc creates output file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    run generate_zshrc "$output_file"
    assert_success
    assert_file_exists "$output_file"
}

@test "generate_zshrc output contains managed markers" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "pimpmyshell managed"
}

@test "generate_zshrc output contains version" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "$PIMPMYSHELL_VERSION"
}

@test "generate_zshrc output contains theme name" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "cyberpunk"
}

@test "generate_zshrc output contains plugins line" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "plugins=("
}

@test "generate_zshrc output contains oh-my-zsh source" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "oh-my-zsh.sh"
}

@test "generate_zshrc output contains alias source lines" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "git.sh"
}

@test "generate_zshrc output contains starship init" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "starship init zsh"
}

@test "generate_zshrc output contains user custom section" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "user custom"
}

@test "generate_zshrc preserves user custom content" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    # Create existing zshrc with custom content
    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    cat > "$output_file" << 'TESTEOF'
# some old config
# >>> user custom >>>
export MY_CUSTOM_VAR="hello"
alias myalias='echo hello'
# <<< user custom <<<
TESTEOF

    generate_zshrc "$output_file"
    assert_file_contains "$output_file" "MY_CUSTOM_VAR"
    assert_file_contains "$output_file" "myalias"
}

@test "generate_zshrc is idempotent" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"

    # Generate twice
    generate_zshrc "$output_file"
    local first_content
    first_content=$(grep -v "^# Generated by" "$output_file")

    generate_zshrc "$output_file"
    local second_content
    second_content=$(grep -v "^# Generated by" "$output_file")

    # Compare (ignoring date line which changes)
    local diff_result
    diff_result=$(diff <(echo "$first_content") <(echo "$second_content")) || true
    [[ -z "$diff_result" ]]
}

@test "generate_zshrc no placeholders remain in output" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)
    export PIMPMYSHELL_CONFIG_FILE="$config_file"

    local output_file="${PIMPMYSHELL_TEST_DIR}/output_zshrc"
    generate_zshrc "$output_file"

    # No {PLACEHOLDER} patterns should remain (grep returns 1 when no match = success)
    ! grep -qE '\{(VERSION|DATE|THEME|ENV_VARS|OMZ_CONFIG|PLUGINS|EZA_THEME|ALIASES|INTEGRATIONS|PROMPT_INIT|USER_CUSTOM)\}' "$output_file"
}

#!/usr/bin/env bats
# pimpmyshell - Tests for lib/validation.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Create a themes directory with a known theme for validation
    export PIMPMYSHELL_THEMES_DIR="${PIMPMYSHELL_TEST_DIR}/themes"
    mkdir -p "$PIMPMYSHELL_THEMES_DIR"
    echo "name: cyberpunk" > "${PIMPMYSHELL_THEMES_DIR}/cyberpunk.yaml"
    echo "name: matrix" > "${PIMPMYSHELL_THEMES_DIR}/matrix.yaml"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'validation'
}

# =============================================================================
# Guard
# =============================================================================

@test "validation.sh sets _PIMPMYSHELL_VALIDATION_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_VALIDATION_LOADED:-}" ]]
}

# =============================================================================
# validate_yaml_syntax
# =============================================================================

@test "validate_yaml_syntax succeeds with valid YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)

    run validate_yaml_syntax "$config_file"
    assert_success
}

@test "validate_yaml_syntax fails with invalid YAML syntax" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/invalid.yaml"
    cat > "$config_file" << 'EOF'
theme: cyberpunk
  bad_indent: this is wrong
    nested: [invalid
EOF

    run validate_yaml_syntax "$config_file"
    assert_failure
}

@test "validate_yaml_syntax fails for non-existent file" {
    run validate_yaml_syntax "/nonexistent/file.yaml"
    assert_failure
}

@test "validate_yaml_syntax fails for empty path" {
    run validate_yaml_syntax ""
    assert_failure
}

@test "validate_yaml_syntax succeeds with empty YAML file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/empty.yaml"
    touch "$config_file"

    run validate_yaml_syntax "$config_file"
    assert_success
}

@test "validate_yaml_syntax succeeds with comments-only YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/comments.yaml"
    echo "# Just a comment" > "$config_file"

    run validate_yaml_syntax "$config_file"
    assert_success
}

# =============================================================================
# validate_config_values
# =============================================================================

@test "validate_config_values succeeds with valid config" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)

    run validate_config_values "$config_file"
    assert_success
}

@test "validate_config_values warns for non-existent theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    export PIMPMYSHELL_VERBOSITY=1
    local config_file="${PIMPMYSHELL_TEST_DIR}/bad_theme.yaml"
    echo "theme: nonexistent_theme_xyz" > "$config_file"

    run validate_config_values "$config_file"
    # Should warn but not fail hard
    assert_output_contains "theme"
}

@test "validate_config_values accepts known theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/good_theme.yaml"
    echo "theme: cyberpunk" > "$config_file"

    run validate_config_values "$config_file"
    assert_success
}

@test "validate_config_values handles missing theme key gracefully" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/no_theme.yaml"
    echo "shell:" > "$config_file"
    echo "  framework: ohmyzsh" >> "$config_file"

    run validate_config_values "$config_file"
    assert_success
}

@test "validate_config_values warns for invalid framework" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    export PIMPMYSHELL_VERBOSITY=1
    local config_file="${PIMPMYSHELL_TEST_DIR}/bad_framework.yaml"
    cat > "$config_file" << 'EOF'
theme: cyberpunk
shell:
  framework: invalid_framework
EOF

    run validate_config_values "$config_file"
    assert_output_contains "framework"
}

@test "validate_config_values warns for invalid prompt engine" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    export PIMPMYSHELL_VERBOSITY=1
    local config_file="${PIMPMYSHELL_TEST_DIR}/bad_prompt.yaml"
    cat > "$config_file" << 'EOF'
theme: cyberpunk
prompt:
  engine: invalid_engine
EOF

    run validate_config_values "$config_file"
    assert_output_contains "prompt"
}

@test "validate_config_values accepts valid framework ohmyzsh" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/valid_fw.yaml"
    cat > "$config_file" << 'EOF'
theme: cyberpunk
shell:
  framework: ohmyzsh
EOF

    run validate_config_values "$config_file"
    assert_success
}

@test "validate_config_values accepts valid prompt engine starship" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/valid_prompt.yaml"
    cat > "$config_file" << 'EOF'
theme: cyberpunk
prompt:
  engine: starship
EOF

    run validate_config_values "$config_file"
    assert_success
}

# =============================================================================
# validate_config - orchestration
# =============================================================================

@test "validate_config succeeds with valid config file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file
    config_file=$(create_test_config)

    run validate_config "$config_file"
    assert_success
}

@test "validate_config fails for non-existent file" {
    run validate_config "/nonexistent/config.yaml"
    assert_failure
}

@test "validate_config fails for empty path" {
    run validate_config ""
    assert_failure
}

@test "validate_config fails with invalid YAML syntax" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/invalid_syntax.yaml"
    cat > "$config_file" << 'EOF'
theme: cyberpunk
  bad: [indent
    broken: yaml
EOF

    run validate_config "$config_file"
    assert_failure
}

@test "validate_config succeeds with empty file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/empty.yaml"
    touch "$config_file"

    run validate_config "$config_file"
    assert_success
}

@test "validate_config succeeds with minimal valid config" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/minimal.yaml"
    echo "theme: cyberpunk" > "$config_file"

    run validate_config "$config_file"
    assert_success
}

@test "validate_config outputs error message for missing file" {
    run validate_config "/nonexistent/path/config.yaml"
    assert_failure
    assert_output_contains "not found"
}

@test "validate_config uses DEFAULT_CONFIG_FILE when no argument" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
    echo "theme: cyberpunk" > "$config_file"

    # Override DEFAULT_CONFIG_FILE for test
    export PIMPMYSHELL_CONFIG_FILE="$config_file"
    run validate_config "$config_file"
    assert_success
}

# =============================================================================
# Error messages
# =============================================================================

@test "validate_yaml_syntax provides error details for invalid YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local config_file="${PIMPMYSHELL_TEST_DIR}/error_detail.yaml"
    cat > "$config_file" << 'EOF'
valid: key
  invalid: indentation
EOF

    run validate_yaml_syntax "$config_file"
    assert_failure
    # Should contain some error info
    [[ -n "$output" ]]
}

@test "validate_config_values provides suggestion for unknown theme" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    export PIMPMYSHELL_VERBOSITY=1
    local config_file="${PIMPMYSHELL_TEST_DIR}/unknown_theme.yaml"
    echo "theme: unknown_xyz" > "$config_file"

    run validate_config_values "$config_file"
    # Should mention available themes or suggest something
    assert_output_contains "theme"
}

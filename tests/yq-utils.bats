#!/usr/bin/env bats
# pimpmyshell - Tests for lib/yq-utils.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Load libs
    load_lib 'core'
    load_lib 'yq-utils'
}

# =============================================================================
# Guard
# =============================================================================

@test "yq-utils.sh sets _PIMPMYSHELL_YQ_UTILS_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_YQ_UTILS_LOADED:-}" ]]
}

# =============================================================================
# detect_yq_version
# =============================================================================

@test "detect_yq_version returns a value when yq is installed" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    run detect_yq_version
    assert_success
    [[ "$output" == "go" || "$output" == "python" ]]
}

@test "detect_yq_version returns go for mikefarah yq" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    if ! yq --version 2>&1 | grep -q "mikefarah"; then
        skip "Not mikefarah yq"
    fi
    run detect_yq_version
    assert_success
    assert_output_equals "go"
}

@test "detect_yq_version returns empty when yq not available" {
    # Override PATH to an empty temp dir to hide yq
    local empty_dir="${PIMPMYSHELL_TEST_DIR}/empty_bin"
    mkdir -p "$empty_dir"
    PATH="$empty_dir" run detect_yq_version
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# require_yq
# =============================================================================

@test "require_yq succeeds when yq is installed" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    run require_yq
    assert_success
}

@test "require_yq fails when yq not available" {
    local empty_dir="${PIMPMYSHELL_TEST_DIR}/empty_bin"
    mkdir -p "$empty_dir"
    PATH="$empty_dir" run require_yq
    assert_failure
    assert_output_contains "yq is required"
}

# =============================================================================
# yq_eval - Single value extraction
# =============================================================================

@test "yq_eval reads a simple value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/test.yaml"
    echo "theme: cyberpunk" > "$yaml_file"

    run yq_eval "$yaml_file" '.theme'
    assert_success
    assert_output_equals "cyberpunk"
}

@test "yq_eval reads a nested value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/test.yaml"
    cat > "$yaml_file" << 'EOF'
shell:
  framework: ohmyzsh
EOF

    run yq_eval "$yaml_file" '.shell.framework'
    assert_success
    assert_output_equals "ohmyzsh"
}

@test "yq_eval returns empty for missing key" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/test.yaml"
    echo "theme: cyberpunk" > "$yaml_file"

    run yq_eval "$yaml_file" '.nonexistent'
    assert_success
    [[ -z "$output" ]]
}

@test "yq_eval fails for non-existent file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    run yq_eval "/nonexistent/file.yaml" '.theme'
    assert_failure
    assert_output_contains "File not found"
}

# =============================================================================
# yq_eval_list - List extraction
# =============================================================================

@test "yq_eval_list reads a list" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/test.yaml"
    cat > "$yaml_file" << 'EOF'
tools:
  required:
    - eza
    - bat
    - fzf
EOF

    run yq_eval_list "$yaml_file" '.tools.required'
    assert_success
    assert_output_contains "eza"
    assert_output_contains "bat"
    assert_output_contains "fzf"
}

@test "yq_eval_list returns empty for missing list" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/test.yaml"
    echo "theme: cyberpunk" > "$yaml_file"

    run yq_eval_list "$yaml_file" '.nonexistent'
    assert_success
    [[ -z "$output" ]]
}

@test "yq_eval_list returns empty for non-existent file" {
    run yq_eval_list "/nonexistent/file.yaml" '.tools'
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# yq_write - Value writing
# =============================================================================

@test "yq_write updates a value" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/test.yaml"
    echo "theme: cyberpunk" > "$yaml_file"

    run yq_write "$yaml_file" '.theme' 'dracula'
    assert_success

    run yq_eval "$yaml_file" '.theme'
    assert_output_equals "dracula"
}

@test "yq_write fails for non-existent file" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    run yq_write "/nonexistent/file.yaml" '.theme' 'dracula'
    assert_failure
    assert_output_contains "File not found"
}

# =============================================================================
# yq_validate - YAML validation
# =============================================================================

@test "yq_validate succeeds with valid YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/valid.yaml"
    echo "theme: cyberpunk" > "$yaml_file"

    run yq_validate "$yaml_file"
    assert_success
}

@test "yq_validate fails with invalid YAML" {
    if ! command -v yq &>/dev/null; then
        skip "yq not installed"
    fi
    local yaml_file="${PIMPMYSHELL_TEST_DIR}/invalid.yaml"
    echo "invalid: yaml: content: [broken" > "$yaml_file"

    run yq_validate "$yaml_file"
    assert_failure
}

@test "yq_validate fails for non-existent file" {
    run yq_validate "/nonexistent/file.yaml"
    assert_failure
    assert_output_contains "File not found"
}

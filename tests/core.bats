#!/usr/bin/env bats
# pimpmyshell - Tests for lib/core.sh

load 'test_helper'

setup() {
    # Call parent setup
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Load the core library
    load_lib 'core'
}

# =============================================================================
# Constants
# =============================================================================

@test "PIMPMYSHELL_VERSION is set" {
    [[ -n "$PIMPMYSHELL_VERSION" ]]
}

@test "PIMPMYSHELL_VERSION follows semver format" {
    [[ "$PIMPMYSHELL_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "PIMPMYSHELL_CONFIG_DIR uses XDG path" {
    [[ "$PIMPMYSHELL_CONFIG_DIR" == *"pimpmyshell"* ]]
}

@test "PIMPMYSHELL_DATA_DIR uses XDG path" {
    [[ "$PIMPMYSHELL_DATA_DIR" == *"pimpmyshell"* ]]
}

@test "PIMPMYSHELL_CACHE_DIR uses XDG path" {
    [[ "$PIMPMYSHELL_CACHE_DIR" == *"pimpmyshell"* ]]
}

# =============================================================================
# Platform detection
# =============================================================================

@test "get_platform returns a valid platform" {
    run get_platform
    assert_success
    [[ "$output" =~ ^(linux|macos|wsl|windows|unknown)$ ]]
}

@test "is_macos returns correct value" {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        run is_macos
        assert_success
    else
        run is_macos
        assert_failure
    fi
}

@test "is_linux returns correct value on Linux" {
    if [[ "$(uname -s)" == "Linux" ]] && ! grep -qEi "microsoft|wsl" /proc/version 2>/dev/null; then
        run is_linux
        assert_success
    fi
}

@test "is_wsl returns failure when not in WSL" {
    if ! grep -qEi "microsoft|wsl" /proc/version 2>/dev/null; then
        run is_wsl
        assert_failure
    fi
}

# =============================================================================
# Command checking
# =============================================================================

@test "check_command returns 0 for existing command" {
    run check_command "ls"
    assert_success
}

@test "check_command returns 1 for non-existing command" {
    run check_command "nonexistent_command_xyz_12345"
    assert_failure
}

@test "check_command returns 0 for bash" {
    run check_command "bash"
    assert_success
}

@test "require_command succeeds for existing command" {
    run require_command "ls"
    assert_success
}

@test "require_command fails for missing command" {
    run require_command "nonexistent_command_xyz_12345"
    assert_failure
}

@test "require_command shows package hint on failure" {
    run require_command "nonexistent_xyz" "apt install nonexistent_xyz"
    assert_failure
    assert_output_contains "nonexistent_xyz"
}

@test "check_dependency returns 0 for existing command" {
    run check_dependency "bash"
    assert_success
}

@test "check_dependency returns 1 for missing command" {
    run check_dependency "nonexistent_command_xyz_12345"
    assert_failure
}

# =============================================================================
# Logging functions
# =============================================================================

@test "log_error always outputs regardless of verbosity" {
    export PIMPMYSHELL_VERBOSITY=0
    run log_error "test error message"
    assert_success
    assert_output_contains "ERROR"
    assert_output_contains "test error message"
}

@test "log_info outputs at verbosity >= 1" {
    export PIMPMYSHELL_VERBOSITY=1
    run log_info "test info message"
    assert_success
    assert_output_contains "INFO"
}

@test "log_info is silent at verbosity 0" {
    export PIMPMYSHELL_VERBOSITY=0
    run log_info "test info"
    assert_success
    [[ -z "$output" ]]
}

@test "log_success outputs at verbosity >= 1" {
    export PIMPMYSHELL_VERBOSITY=1
    run log_success "operation completed"
    assert_success
    assert_output_contains "OK"
}

@test "log_success is silent at verbosity 0" {
    export PIMPMYSHELL_VERBOSITY=0
    run log_success "operation completed"
    assert_success
    [[ -z "$output" ]]
}

@test "log_warn outputs at verbosity >= 1" {
    export PIMPMYSHELL_VERBOSITY=1
    run log_warn "test warning"
    assert_success
    assert_output_contains "WARN"
}

@test "log_warn is silent at verbosity 0" {
    export PIMPMYSHELL_VERBOSITY=0
    run log_warn "test warning"
    assert_success
    [[ -z "$output" ]]
}

@test "log_debug outputs at verbosity >= 3" {
    export PIMPMYSHELL_VERBOSITY=3
    run log_debug "debug message"
    assert_success
    assert_output_contains "DEBUG"
}

@test "log_debug is silent at verbosity < 3" {
    export PIMPMYSHELL_VERBOSITY=2
    run log_debug "debug message"
    assert_success
    [[ -z "$output" ]]
}

@test "log_verbose outputs at verbosity >= 2" {
    export PIMPMYSHELL_VERBOSITY=2
    run log_verbose "verbose message"
    assert_success
    assert_output_contains "VERBOSE"
}

@test "log_verbose is silent at verbosity < 2" {
    export PIMPMYSHELL_VERBOSITY=1
    run log_verbose "verbose message"
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# Enhanced error functions
# =============================================================================

@test "error_with_suggestion outputs error and suggestion" {
    run error_with_suggestion "Config not found" "Run pimpmyshell wizard"
    assert_success
    assert_output_contains "ERROR"
    assert_output_contains "Config not found"
    assert_output_contains "Suggestion"
}

@test "error_with_suggestion works with empty suggestion" {
    run error_with_suggestion "Something failed" ""
    assert_success
    assert_output_contains "ERROR"
    assert_output_contains "Something failed"
}

@test "die_with_help outputs fatal error and hint" {
    run die_with_help "Unknown command" "pimpmyshell help"
    assert_failure
    assert_output_contains "FATAL"
    assert_output_contains "Unknown command"
    assert_output_contains "pimpmyshell help"
}

@test "log_error_detail outputs title and details" {
    run log_error_detail "Validation failed" "Line 5: unknown theme"
    assert_success
    assert_output_contains "Validation failed"
    assert_output_contains "Line 5"
}

@test "log_error_box creates boxed output" {
    run log_error_box "Critical Error"
    assert_success
    assert_output_contains "Critical Error"
}

@test "warn_with_action outputs warning and action" {
    run warn_with_action "Deprecated option" "Use new_option instead"
    assert_success
    assert_output_contains "WARN"
    assert_output_contains "Deprecated"
    assert_output_contains "Action"
}

# =============================================================================
# _require_args
# =============================================================================

@test "_require_args succeeds when enough arguments" {
    run _require_args "my_func" 2 3
    assert_success
}

@test "_require_args succeeds when exact argument count" {
    run _require_args "my_func" 2 2
    assert_success
}

@test "_require_args fails when too few arguments" {
    run _require_args "my_func" 2 0
    assert_failure
    assert_output_contains "my_func"
    assert_output_contains "expected at least 2"
}

@test "_require_args fails with zero args when one required" {
    run _require_args "test_fn" 1 0
    assert_failure
}

# =============================================================================
# String utilities
# =============================================================================

@test "trim removes leading whitespace" {
    result=$(trim "  hello")
    [[ "$result" == "hello" ]]
}

@test "trim removes trailing whitespace" {
    result=$(trim "hello  ")
    [[ "$result" == "hello" ]]
}

@test "trim removes both leading and trailing whitespace" {
    result=$(trim "  hello world  ")
    [[ "$result" == "hello world" ]]
}

@test "trim handles empty string" {
    result=$(trim "")
    [[ "$result" == "" ]]
}

@test "is_empty returns true for empty string" {
    run is_empty ""
    assert_success
}

@test "is_empty returns true for whitespace-only string" {
    run is_empty "   "
    assert_success
}

@test "is_empty returns false for non-empty string" {
    run is_empty "hello"
    assert_failure
}

@test "to_lower converts uppercase to lowercase" {
    result=$(to_lower "HELLO WORLD")
    [[ "$result" == "hello world" ]]
}

@test "to_lower handles mixed case" {
    result=$(to_lower "Hello World")
    [[ "$result" == "hello world" ]]
}

@test "to_upper converts lowercase to uppercase" {
    result=$(to_upper "hello world")
    [[ "$result" == "HELLO WORLD" ]]
}

# =============================================================================
# Array utilities
# =============================================================================

@test "array_contains returns 0 when element exists" {
    run array_contains "b" "a" "b" "c"
    assert_success
}

@test "array_contains returns 1 when element does not exist" {
    run array_contains "d" "a" "b" "c"
    assert_failure
}

@test "array_contains handles single element" {
    run array_contains "a" "a"
    assert_success
}

@test "array_contains returns 1 for empty array" {
    run array_contains "a"
    assert_failure
}

# =============================================================================
# File operations
# =============================================================================

@test "ensure_dir creates directory if not exists" {
    local test_dir="${PIMPMYSHELL_TEST_DIR}/new_dir"
    run ensure_dir "$test_dir"
    assert_success
    assert_dir_exists "$test_dir"
}

@test "ensure_dir is idempotent" {
    local test_dir="${PIMPMYSHELL_TEST_DIR}/existing_dir"
    mkdir -p "$test_dir"
    run ensure_dir "$test_dir"
    assert_success
    assert_dir_exists "$test_dir"
}

@test "backup_file creates backup of existing file" {
    local test_file="${PIMPMYSHELL_TEST_DIR}/test_file.txt"
    echo "test content" > "$test_file"

    run backup_file "$test_file"
    assert_success

    # Check backup was created in data dir
    local backup_dir="${PIMPMYSHELL_DATA_DIR}/backups"
    [[ -d "$backup_dir" ]]
    [[ -n "$(ls -A "$backup_dir" 2>/dev/null)" ]]
}

@test "backup_file returns empty for non-existing file" {
    run backup_file "/nonexistent/file"
    assert_success
    [[ -z "$output" ]]
}

@test "symlink_safe creates symlink" {
    local source="${PIMPMYSHELL_TEST_DIR}/source"
    local target="${PIMPMYSHELL_TEST_DIR}/target"
    echo "source content" > "$source"

    run symlink_safe "$source" "$target"
    assert_success
    [[ -L "$target" ]]
}

@test "symlink_safe backs up existing file before symlinking" {
    local source="${PIMPMYSHELL_TEST_DIR}/source"
    local target="${PIMPMYSHELL_TEST_DIR}/target"
    echo "source content" > "$source"
    echo "existing content" > "$target"

    run symlink_safe "$source" "$target"
    assert_success
    [[ -L "$target" ]]

    # Check backup exists
    local backup_dir="${PIMPMYSHELL_DATA_DIR}/backups"
    [[ -n "$(ls -A "$backup_dir" 2>/dev/null)" ]]
}

# =============================================================================
# Module loading
# =============================================================================

@test "load_module returns 1 for non-existent optional module" {
    run load_module "/nonexistent/module.sh" "optional"
    assert_failure
}

@test "load_module loads existing module" {
    local test_module="${PIMPMYSHELL_TEST_DIR}/test_module.sh"
    echo 'TEST_MODULE_VAR="loaded"' > "$test_module"

    run load_module "$test_module" "optional"
    assert_success
}

@test "is_module_loaded returns false for unloaded module" {
    run is_module_loaded "nonexistent_module"
    assert_failure
}

@test "list_loaded_modules runs without error" {
    run list_loaded_modules
    assert_success
}

# =============================================================================
# Initialization
# =============================================================================

@test "init_directories creates all required directories" {
    rm -rf "$PIMPMYSHELL_CONFIG_DIR" "$PIMPMYSHELL_DATA_DIR" "$PIMPMYSHELL_CACHE_DIR"

    run init_directories
    assert_success

    assert_dir_exists "$PIMPMYSHELL_CONFIG_DIR"
    assert_dir_exists "$PIMPMYSHELL_DATA_DIR"
    assert_dir_exists "$PIMPMYSHELL_CACHE_DIR"
    assert_dir_exists "${PIMPMYSHELL_DATA_DIR}/backups"
}

# =============================================================================
# Guard against re-sourcing
# =============================================================================

@test "core.sh can be sourced twice without error" {
    run load_lib 'core'
    assert_success
}

#!/usr/bin/env bash
# pimpmyshell - Test helper for bats

# Get the project root directory
export PIMPMYSHELL_ROOT="${BATS_TEST_DIRNAME}/.."
export PIMPMYSHELL_LIB_DIR="${PIMPMYSHELL_ROOT}/lib"

# Create temp directories for tests
export PIMPMYSHELL_TEST_DIR="${BATS_TMPDIR}/pimpmyshell-test-$$"
export PIMPMYSHELL_CONFIG_DIR="${PIMPMYSHELL_TEST_DIR}/config"
export PIMPMYSHELL_DATA_DIR="${PIMPMYSHELL_TEST_DIR}/data"
export PIMPMYSHELL_CACHE_DIR="${PIMPMYSHELL_TEST_DIR}/cache"

# Disable colors in tests
export NO_COLOR=1
export PIMPMYSHELL_VERBOSITY=0

# Setup function - runs before each test
setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"
}

# Teardown function - runs after each test
teardown() {
    rm -rf "$PIMPMYSHELL_TEST_DIR"
}

# Load a library file
load_lib() {
    local lib_name="$1"
    # shellcheck disable=SC1090
    source "${PIMPMYSHELL_LIB_DIR}/${lib_name}.sh"
}

# Assert that a command succeeds
assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "Expected success but got status $status"
        echo "Output: $output"
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "Expected failure but got success"
        echo "Output: $output"
        return 1
    fi
}

# Assert output contains a string
assert_output_contains() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
        echo "Expected output to contain: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

# Assert output equals a string
assert_output_equals() {
    local expected="$1"
    if [[ "$output" != "$expected" ]]; then
        echo "Expected output: $expected"
        echo "Actual output: $output"
        return 1
    fi
}

# Assert output does NOT contain a string
refute_output_contains() {
    local unexpected="$1"
    if [[ "$output" == *"$unexpected"* ]]; then
        echo "Expected output NOT to contain: $unexpected"
        echo "Actual output: $output"
        return 1
    fi
}

# Assert a file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Expected file to exist: $file"
        return 1
    fi
}

# Assert a directory exists
assert_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        echo "Expected directory to exist: $dir"
        return 1
    fi
}

# Assert a file contains a string
assert_file_contains() {
    local file="$1"
    local expected="$2"
    if ! grep -qF -- "$expected" "$file" 2>/dev/null; then
        echo "Expected file $file to contain: $expected"
        return 1
    fi
}

# Create a test YAML config
create_test_config() {
    local content="${1:-}"
    local config_file="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    if [[ -z "$content" ]]; then
        content='
theme: cyberpunk

shell:
  framework: ohmyzsh

prompt:
  engine: starship

plugins:
  ohmyzsh:
    - git
    - fzf
  custom:
    - zsh-autosuggestions

tools:
  required:
    - eza
    - bat

aliases:
  enabled: true
  groups:
    - git
    - files
'
    fi

    echo "$content" > "$config_file"
    echo "$config_file"
}

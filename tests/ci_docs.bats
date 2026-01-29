#!/usr/bin/env bats
# pimpmyshell - Tests for Phase 14: CI/CD workflows & Documentation

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME"

    load_lib 'core'
}

# =============================================================================
# T057 - .github/workflows/test.yml
# =============================================================================

@test "test.yml workflow file exists" {
    assert_file_exists "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml"
}

@test "test.yml triggers on push" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "push"
}

@test "test.yml triggers on pull_request" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "pull_request"
}

@test "test.yml uses ubuntu matrix" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "ubuntu-latest"
}

@test "test.yml uses macos matrix" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "macos-latest"
}

@test "test.yml installs bats" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "bats"
}

@test "test.yml installs yq" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "yq"
}

@test "test.yml runs shellcheck" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "shellcheck"
}

@test "test.yml runs bats tests" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/test.yml" "bats tests/"
}

# =============================================================================
# T058 - .github/workflows/release.yml
# =============================================================================

@test "release.yml workflow file exists" {
    assert_file_exists "${PIMPMYSHELL_ROOT}/.github/workflows/release.yml"
}

@test "release.yml triggers on version tags" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/release.yml" "v*"
}

@test "release.yml creates GitHub release" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/release.yml" "release"
}

@test "release.yml uses checkout action" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/.github/workflows/release.yml" "actions/checkout"
}

# =============================================================================
# T059 - README.md
# =============================================================================

@test "README.md exists" {
    assert_file_exists "${PIMPMYSHELL_ROOT}/README.md"
}

@test "README.md contains project name" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/README.md" "pimpmyshell"
}

@test "README.md contains installation section" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/README.md" "Installation"
}

@test "README.md contains usage section" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/README.md" "Usage"
}

@test "README.md contains themes section" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/README.md" "Themes"
}

@test "README.md contains commands section" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/README.md" "Commands"
}

@test "README.md contains configuration section" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/README.md" "Configuration"
}

@test "README.md mentions install.sh" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/README.md" "install.sh"
}

# =============================================================================
# T060 - CHANGELOG.md
# =============================================================================

@test "CHANGELOG.md exists" {
    assert_file_exists "${PIMPMYSHELL_ROOT}/CHANGELOG.md"
}

@test "CHANGELOG.md follows Keep a Changelog format" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/CHANGELOG.md" "Changelog"
}

@test "CHANGELOG.md contains v0.1.0 entry" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/CHANGELOG.md" "0.1.0"
}

@test "CHANGELOG.md contains Added section" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/CHANGELOG.md" "Added"
}

@test "CHANGELOG.md contains Unreleased section" {
    assert_file_contains "${PIMPMYSHELL_ROOT}/CHANGELOG.md" "Unreleased"
}

#!/usr/bin/env bats
# pimpmyshell - Tests for lib/profiles.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    export HOME="${PIMPMYSHELL_TEST_DIR}/home"
    mkdir -p "$HOME/.config"

    export PIMPMYSHELL_THEMES_DIR="${PIMPMYSHELL_ROOT}/themes"

    # Load libs
    load_lib 'core'
    load_lib 'config'
    load_lib 'profiles'
}

# =============================================================================
# Guard
# =============================================================================

@test "profiles.sh sets _PIMPMYSHELL_PROFILES_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_PROFILES_LOADED:-}" ]]
}

# =============================================================================
# init_profiles
# =============================================================================

@test "init_profiles function exists" {
    declare -F init_profiles
}

@test "init_profiles creates profiles directory" {
    init_profiles
    assert_dir_exists "${PIMPMYSHELL_CONFIG_DIR}/profiles"
}

@test "init_profiles creates default profile directory" {
    init_profiles
    assert_dir_exists "${PIMPMYSHELL_CONFIG_DIR}/profiles/default"
}

@test "init_profiles creates current symlink to default" {
    init_profiles
    [[ -L "${PIMPMYSHELL_CONFIG_DIR}/profiles/current" ]]
    local target
    target=$(readlink "${PIMPMYSHELL_CONFIG_DIR}/profiles/current")
    [[ "$target" == "default" ]]
}

@test "init_profiles is idempotent" {
    init_profiles
    init_profiles
    assert_dir_exists "${PIMPMYSHELL_CONFIG_DIR}/profiles/default"
    [[ -L "${PIMPMYSHELL_CONFIG_DIR}/profiles/current" ]]
}

# =============================================================================
# list_profiles
# =============================================================================

@test "list_profiles function exists" {
    declare -F list_profiles
}

@test "list_profiles returns default after init" {
    init_profiles
    run list_profiles
    assert_success
    assert_output_contains "default"
}

@test "list_profiles returns multiple profiles" {
    init_profiles
    mkdir -p "${PIMPMYSHELL_CONFIG_DIR}/profiles/work"
    mkdir -p "${PIMPMYSHELL_CONFIG_DIR}/profiles/personal"
    run list_profiles
    assert_success
    assert_output_contains "default"
    assert_output_contains "work"
    assert_output_contains "personal"
}

@test "list_profiles does not include current symlink" {
    init_profiles
    run list_profiles
    assert_success
    # "current" should not appear as a profile name
    refute_output_contains "current"
}

@test "list_profiles ignores regular files" {
    init_profiles
    touch "${PIMPMYSHELL_CONFIG_DIR}/profiles/some_file.txt"
    run list_profiles
    assert_success
    refute_output_contains "some_file.txt"
}

# =============================================================================
# profile_exists
# =============================================================================

@test "profile_exists function exists" {
    declare -F profile_exists
}

@test "profile_exists returns true for existing profile" {
    init_profiles
    profile_exists "default"
}

@test "profile_exists returns false for non-existing profile" {
    init_profiles
    ! profile_exists "nonexistent"
}

# =============================================================================
# get_current_profile
# =============================================================================

@test "get_current_profile function exists" {
    declare -F get_current_profile
}

@test "get_current_profile returns default after init" {
    init_profiles
    run get_current_profile
    assert_success
    assert_output_contains "default"
}

# =============================================================================
# is_valid_profile_name
# =============================================================================

@test "is_valid_profile_name function exists" {
    declare -F is_valid_profile_name
}

@test "is_valid_profile_name accepts alphanumeric names" {
    is_valid_profile_name "work"
    is_valid_profile_name "personal123"
}

@test "is_valid_profile_name accepts dash and underscore" {
    is_valid_profile_name "my-profile"
    is_valid_profile_name "my_profile"
}

@test "is_valid_profile_name rejects empty name" {
    ! is_valid_profile_name ""
}

@test "is_valid_profile_name rejects spaces" {
    ! is_valid_profile_name "my profile"
}

@test "is_valid_profile_name rejects path traversal" {
    ! is_valid_profile_name "../etc"
    ! is_valid_profile_name "foo/bar"
}

@test "is_valid_profile_name rejects reserved name current" {
    ! is_valid_profile_name "current"
}

# =============================================================================
# create_profile
# =============================================================================

@test "create_profile function exists" {
    declare -F create_profile
}

@test "create_profile creates a new profile directory" {
    init_profiles
    create_profile "work"
    assert_dir_exists "${PIMPMYSHELL_CONFIG_DIR}/profiles/work"
}

@test "create_profile copies config from current profile" {
    init_profiles
    # Create a config in default profile
    echo "theme: cyberpunk" > "${PIMPMYSHELL_CONFIG_DIR}/profiles/default/pimpmyshell.yaml"
    create_profile "work"
    assert_file_exists "${PIMPMYSHELL_CONFIG_DIR}/profiles/work/pimpmyshell.yaml"
    assert_file_contains "${PIMPMYSHELL_CONFIG_DIR}/profiles/work/pimpmyshell.yaml" "theme: cyberpunk"
}

@test "create_profile fails for duplicate name" {
    init_profiles
    create_profile "work"
    run create_profile "work"
    assert_failure
}

@test "create_profile fails for invalid name" {
    init_profiles
    run create_profile "bad name"
    assert_failure
}

@test "create_profile fails for empty name" {
    init_profiles
    run create_profile ""
    assert_failure
}

# =============================================================================
# switch_profile
# =============================================================================

@test "switch_profile function exists" {
    declare -F switch_profile
}

@test "switch_profile changes current symlink" {
    init_profiles
    create_profile "work"
    switch_profile "work"
    local current
    current=$(get_current_profile)
    [[ "$current" == "work" ]]
}

@test "switch_profile fails for non-existing profile" {
    init_profiles
    run switch_profile "nonexistent"
    assert_failure
}

@test "switch_profile updates config symlink" {
    init_profiles
    echo "theme: matrix" > "${PIMPMYSHELL_CONFIG_DIR}/profiles/default/pimpmyshell.yaml"
    create_profile "work"
    echo "theme: dracula" > "${PIMPMYSHELL_CONFIG_DIR}/profiles/work/pimpmyshell.yaml"
    switch_profile "work"
    local current
    current=$(readlink "${PIMPMYSHELL_CONFIG_DIR}/profiles/current")
    [[ "$current" == "work" ]]
}

# =============================================================================
# delete_profile
# =============================================================================

@test "delete_profile function exists" {
    declare -F delete_profile
}

@test "delete_profile removes profile directory" {
    init_profiles
    create_profile "work"
    delete_profile "work"
    [[ ! -d "${PIMPMYSHELL_CONFIG_DIR}/profiles/work" ]]
}

@test "delete_profile fails for default profile" {
    init_profiles
    run delete_profile "default"
    assert_failure
}

@test "delete_profile fails for current active profile" {
    init_profiles
    create_profile "work"
    switch_profile "work"
    run delete_profile "work"
    assert_failure
}

@test "delete_profile fails for non-existing profile" {
    init_profiles
    run delete_profile "nonexistent"
    assert_failure
}

# =============================================================================
# get_profile_config_path
# =============================================================================

@test "get_profile_config_path function exists" {
    declare -F get_profile_config_path
}

@test "get_profile_config_path returns correct path" {
    init_profiles
    run get_profile_config_path "default"
    assert_success
    assert_output_contains "profiles/default/pimpmyshell.yaml"
}

@test "get_profile_config_path fails for non-existing profile" {
    init_profiles
    run get_profile_config_path "nonexistent"
    assert_failure
}

# =============================================================================
# get_active_config_path
# =============================================================================

@test "get_active_config_path function exists" {
    declare -F get_active_config_path
}

@test "get_active_config_path returns current profile config" {
    init_profiles
    run get_active_config_path
    assert_success
    assert_output_contains "profiles/default/pimpmyshell.yaml"
}

@test "get_active_config_path follows profile switch" {
    init_profiles
    create_profile "work"
    switch_profile "work"
    run get_active_config_path
    assert_success
    assert_output_contains "profiles/work/pimpmyshell.yaml"
}

# =============================================================================
# CLI integration
# =============================================================================

@test "cmd_profile calls profile functions" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    init_profiles
    run cmd_profile list
    assert_success
    assert_output_contains "default"
}

@test "cmd_profile create creates profile" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    init_profiles
    run cmd_profile create "testprofile"
    assert_success
    assert_dir_exists "${PIMPMYSHELL_CONFIG_DIR}/profiles/testprofile"
}

@test "cmd_profile switch changes active profile" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    init_profiles
    create_profile "testprofile"
    run cmd_profile switch "testprofile"
    assert_success
}

@test "cmd_profile delete removes profile" {
    source "${PIMPMYSHELL_ROOT}/bin/pimpmyshell"
    init_profiles
    create_profile "testprofile"
    run cmd_profile delete "testprofile"
    assert_success
}

#!/usr/bin/env bats
# pimpmyshell - Tests for lib/distro.sh

load 'test_helper'

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"

    # Load libs
    load_lib 'core'
    load_lib 'distro'
}

# =============================================================================
# Guard
# =============================================================================

@test "distro.sh sets _PIMPMYSHELL_DISTRO_LOADED guard" {
    [[ -n "${_PIMPMYSHELL_DISTRO_LOADED:-}" ]]
}

# =============================================================================
# get_distro_id
# =============================================================================

@test "get_distro_id returns a non-empty string on Linux" {
    if [[ "$(uname -s)" != "Linux" ]]; then
        skip "Not Linux"
    fi
    run get_distro_id
    assert_success
    [[ -n "$output" ]]
}

@test "get_distro_id returns unknown on macOS" {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "Not macOS"
    fi
    run get_distro_id
    assert_success
    assert_output_equals "unknown"
}

@test "get_distro_id reads from /etc/os-release" {
    # Create a fake os-release
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 24.04 LTS"
EOF
    run get_distro_id "$fake_os_release"
    assert_success
    assert_output_equals "ubuntu"
}

@test "get_distro_id reads fedora from /etc/os-release" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=fedora
PRETTY_NAME="Fedora Linux 40"
EOF
    run get_distro_id "$fake_os_release"
    assert_success
    assert_output_equals "fedora"
}

@test "get_distro_id reads alpine from /etc/os-release" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=alpine
PRETTY_NAME="Alpine Linux v3.20"
EOF
    run get_distro_id "$fake_os_release"
    assert_success
    assert_output_equals "alpine"
}

@test "get_distro_id reads opensuse-tumbleweed from /etc/os-release" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=opensuse-tumbleweed
ID_LIKE="opensuse suse"
PRETTY_NAME="openSUSE Tumbleweed"
EOF
    run get_distro_id "$fake_os_release"
    assert_success
    assert_output_equals "opensuse-tumbleweed"
}

@test "get_distro_id returns unknown when os-release missing" {
    run get_distro_id "/nonexistent/os-release"
    assert_success
    assert_output_equals "unknown"
}

# =============================================================================
# get_distro_family
# =============================================================================

@test "get_distro_family maps ubuntu to debian" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=ubuntu
ID_LIKE=debian
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "debian"
}

@test "get_distro_family maps debian to debian" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=debian
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "debian"
}

@test "get_distro_family maps fedora to fedora" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=fedora
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "fedora"
}

@test "get_distro_family maps centos to fedora" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=centos
ID_LIKE="rhel fedora"
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "fedora"
}

@test "get_distro_family maps rhel to fedora" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=rhel
ID_LIKE=fedora
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "fedora"
}

@test "get_distro_family maps arch to arch" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=arch
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "arch"
}

@test "get_distro_family maps manjaro to arch" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=manjaro
ID_LIKE=arch
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "arch"
}

@test "get_distro_family maps opensuse-tumbleweed to suse" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=opensuse-tumbleweed
ID_LIKE="opensuse suse"
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "suse"
}

@test "get_distro_family maps opensuse-leap to suse" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=opensuse-leap
ID_LIKE="suse opensuse"
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "suse"
}

@test "get_distro_family maps alpine to alpine" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=alpine
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "alpine"
}

@test "get_distro_family returns unknown for unrecognized distro" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=someunknowndistro
EOF
    run get_distro_family "$fake_os_release"
    assert_success
    assert_output_equals "unknown"
}

# =============================================================================
# get_distro_pretty
# =============================================================================

@test "get_distro_pretty returns PRETTY_NAME" {
    local fake_os_release="${PIMPMYSHELL_TEST_DIR}/os-release"
    cat > "$fake_os_release" << 'EOF'
ID=ubuntu
PRETTY_NAME="Ubuntu 24.04 LTS"
EOF
    run get_distro_pretty "$fake_os_release"
    assert_success
    assert_output_equals "Ubuntu 24.04 LTS"
}

@test "get_distro_pretty returns unknown when file missing" {
    run get_distro_pretty "/nonexistent/os-release"
    assert_success
    assert_output_equals "unknown"
}

# =============================================================================
# run_privileged
# =============================================================================

@test "run_privileged function exists" {
    declare -F run_privileged
}

@test "run_privileged executes command directly when PIMPMYSHELL_SKIP_SUDO is set" {
    export PIMPMYSHELL_SKIP_SUDO=1
    run run_privileged echo "hello_direct"
    assert_success
    assert_output_contains "hello_direct"
    unset PIMPMYSHELL_SKIP_SUDO
}

@test "run_privileged passes all arguments correctly" {
    export PIMPMYSHELL_SKIP_SUDO=1
    run run_privileged echo "arg1" "arg2" "arg3"
    assert_success
    assert_output_contains "arg1"
    assert_output_contains "arg2"
    assert_output_contains "arg3"
    unset PIMPMYSHELL_SKIP_SUDO
}

@test "run_privileged fails without arguments" {
    run run_privileged
    assert_failure
    assert_output_contains "no command specified"
}

# =============================================================================
# Argument validation
# =============================================================================

@test "get_distro_id works without arguments (uses default path)" {
    run get_distro_id
    assert_success
    # Should return something (distro id or "unknown")
    [[ -n "$output" ]]
}

@test "get_distro_family works without arguments" {
    run get_distro_family
    assert_success
    [[ -n "$output" ]]
}

@test "get_distro_pretty works without arguments" {
    run get_distro_pretty
    assert_success
    [[ -n "$output" ]]
}

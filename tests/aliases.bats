#!/usr/bin/env bats
# pimpmyshell - Tests for modules/aliases/

load 'test_helper'

export PIMPMYSHELL_MODULES_DIR="${PIMPMYSHELL_ROOT}/modules"

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"
}

# =============================================================================
# Alias module files exist
# =============================================================================

@test "git.sh alias module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh"
}

@test "docker.sh alias module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh"
}

@test "kubernetes.sh alias module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh"
}

@test "navigation.sh alias module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/aliases/navigation.sh"
}

@test "files.sh alias module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh"
}

# =============================================================================
# Sourcability - each file sources without error
# =============================================================================

@test "git.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'"
    assert_success
}

@test "docker.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'"
    assert_success
}

@test "kubernetes.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh'"
    assert_success
}

@test "navigation.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/navigation.sh'"
    assert_success
}

@test "files.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh'"
    assert_success
}

# =============================================================================
# Guard checks
# =============================================================================

@test "git.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; echo \$_PIMPMYSHELL_ALIASES_GIT_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "docker.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'; echo \$_PIMPMYSHELL_ALIASES_DOCKER_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "kubernetes.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh'; echo \$_PIMPMYSHELL_ALIASES_K8S_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "navigation.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/navigation.sh'; echo \$_PIMPMYSHELL_ALIASES_NAV_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "files.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh'; echo \$_PIMPMYSHELL_ALIASES_FILES_LOADED"
    assert_success
    assert_output_contains "1"
}

# =============================================================================
# Git aliases content
# =============================================================================

@test "git.sh defines ga alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias ga"
    assert_success
    assert_output_contains "git add"
}

@test "git.sh defines gc alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gc"
    assert_success
    assert_output_contains "git commit"
}

@test "git.sh defines gp alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gp"
    assert_success
    assert_output_contains "git push"
}

@test "git.sh defines gs alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gs"
    assert_success
    assert_output_contains "git status"
}

@test "git.sh defines gd alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gd"
    assert_success
    assert_output_contains "git diff"
}

@test "git.sh defines gcm alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gcm"
    assert_success
    assert_output_contains "git commit -m"
}

@test "git.sh defines gco alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gco"
    assert_success
    assert_output_contains "git checkout"
}

@test "git.sh defines gb alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gb"
    assert_success
    assert_output_contains "git branch"
}

@test "git.sh defines gl alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; alias gl"
    assert_success
    assert_output_contains "git log"
}

# =============================================================================
# Docker aliases content
# =============================================================================

@test "docker.sh defines dps alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'; alias dps"
    assert_success
    assert_output_contains "docker ps"
}

@test "docker.sh defines dex alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'; alias dex"
    assert_success
    assert_output_contains "docker exec"
}

@test "docker.sh defines dcup alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'; alias dcup"
    assert_success
    assert_output_contains "docker compose up"
}

@test "docker.sh defines dcdn alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'; alias dcdn"
    assert_success
    assert_output_contains "docker compose down"
}

@test "docker.sh defines dlogs alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'; alias dlogs"
    assert_success
    assert_output_contains "docker logs"
}

# =============================================================================
# Kubernetes aliases content
# =============================================================================

@test "kubernetes.sh defines k alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh'; alias k"
    assert_success
    assert_output_contains "kubectl"
}

@test "kubernetes.sh defines kg alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh'; alias kg"
    assert_success
    assert_output_contains "kubectl get"
}

@test "kubernetes.sh defines kgp alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh'; alias kgp"
    assert_success
    assert_output_contains "kubectl get pods"
}

@test "kubernetes.sh defines kd alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh'; alias kd"
    assert_success
    assert_output_contains "kubectl describe"
}

@test "kubernetes.sh defines kl alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/kubernetes.sh'; alias kl"
    assert_success
    assert_output_contains "kubectl logs"
}

# =============================================================================
# Navigation aliases content
# =============================================================================

@test "navigation.sh defines .. alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/navigation.sh'; alias .."
    assert_success
    assert_output_contains "cd .."
}

@test "navigation.sh defines ... alias" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/navigation.sh'; alias ..."
    assert_success
    assert_output_contains "cd ../.."
}

@test "navigation.sh defines mkcd function" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/navigation.sh'; declare -F mkcd"
    assert_success
    assert_output_contains "mkcd"
}

@test "navigation.sh defines take function" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/navigation.sh'; declare -F take"
    assert_success
    assert_output_contains "take"
}

# =============================================================================
# Files aliases content
# =============================================================================

@test "files.sh defines eza aliases when eza is available" {
    if ! command -v eza &>/dev/null; then
        skip "eza not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh'; alias ls"
    assert_success
    assert_output_contains "eza"
}

@test "files.sh defines ll alias when eza is available" {
    if ! command -v eza &>/dev/null; then
        skip "eza not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh'; alias ll"
    assert_success
    assert_output_contains "eza"
}

@test "files.sh defines la alias when eza is available" {
    if ! command -v eza &>/dev/null; then
        skip "eza not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh'; alias la"
    assert_success
    assert_output_contains "eza"
}

@test "files.sh defines lt alias when eza is available" {
    if ! command -v eza &>/dev/null; then
        skip "eza not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh'; alias lt"
    assert_success
    assert_output_contains "eza"
}

@test "files.sh defines cat alias when bat is available" {
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        skip "bat/batcat not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/files.sh'; alias cat"
    assert_success
    [[ "$output" == *"bat"* ]]
}

# =============================================================================
# Re-sourcing guard
# =============================================================================

@test "git.sh re-sourcing is guarded" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'; source '${PIMPMYSHELL_MODULES_DIR}/aliases/git.sh'"
    assert_success
}

@test "docker.sh re-sourcing is guarded" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'; source '${PIMPMYSHELL_MODULES_DIR}/aliases/docker.sh'"
    assert_success
}

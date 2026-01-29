#!/usr/bin/env bats
# pimpmyshell - Tests for modules/integrations/

load 'test_helper'

export PIMPMYSHELL_MODULES_DIR="${PIMPMYSHELL_ROOT}/modules"

setup() {
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_CACHE_DIR"
}

# =============================================================================
# Integration module files exist
# =============================================================================

@test "fzf.sh integration module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh"
}

@test "mise.sh integration module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/integrations/mise.sh"
}

@test "tmux.sh integration module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh"
}

@test "zoxide.sh integration module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/integrations/zoxide.sh"
}

@test "delta.sh integration module exists" {
    assert_file_exists "${PIMPMYSHELL_MODULES_DIR}/integrations/delta.sh"
}

# =============================================================================
# Sourcability - each file sources without error
# =============================================================================

@test "fzf.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'"
    assert_success
}

@test "mise.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/mise.sh'"
    assert_success
}

@test "tmux.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'"
    assert_success
}

@test "zoxide.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/zoxide.sh'"
    assert_success
}

@test "delta.sh sources without error" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/delta.sh'"
    assert_success
}

# =============================================================================
# Guard checks
# =============================================================================

@test "fzf.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'; echo \$_PIMPMYSHELL_INTEG_FZF_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "mise.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/mise.sh'; echo \$_PIMPMYSHELL_INTEG_MISE_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "tmux.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'; echo \$_PIMPMYSHELL_INTEG_TMUX_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "zoxide.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/zoxide.sh'; echo \$_PIMPMYSHELL_INTEG_ZOXIDE_LOADED"
    assert_success
    assert_output_contains "1"
}

@test "delta.sh sets guard variable" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/delta.sh'; echo \$_PIMPMYSHELL_INTEG_DELTA_LOADED"
    assert_success
    assert_output_contains "1"
}

# =============================================================================
# fzf integration specifics
# =============================================================================

@test "fzf.sh sets FZF_DEFAULT_OPTS when fzf is available" {
    if ! command -v fzf &>/dev/null; then
        skip "fzf not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'; echo \"\$FZF_DEFAULT_OPTS\""
    assert_success
    assert_output_contains "reverse"
}

@test "fzf.sh sets FZF_DEFAULT_OPTS with pointer" {
    if ! command -v fzf &>/dev/null; then
        skip "fzf not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'; echo \"\$FZF_DEFAULT_OPTS\""
    assert_success
    assert_output_contains "pointer"
}

@test "fzf.sh sets FZF_CTRL_R_OPTS when fzf is available" {
    if ! command -v fzf &>/dev/null; then
        skip "fzf not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'; echo \"\$FZF_CTRL_R_OPTS\""
    assert_success
    assert_output_contains "preview"
}

@test "fzf.sh sets FZF_DEFAULT_COMMAND when fd is available" {
    if ! command -v fzf &>/dev/null; then
        skip "fzf not installed"
    fi
    if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
        skip "fd/fdfind not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'; echo \"\$FZF_DEFAULT_COMMAND\""
    assert_success
    [[ "$output" == *"fd"* ]]
}

@test "fzf.sh sets FZF_CTRL_T_OPTS with bat preview" {
    if ! command -v fzf &>/dev/null; then
        skip "fzf not installed"
    fi
    if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
        skip "bat/batcat not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'; echo \"\$FZF_CTRL_T_OPTS\""
    assert_success
    assert_output_contains "preview"
}

@test "fzf.sh skips silently when fzf not installed" {
    run bash -c "PATH=/nonexistent source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'"
    assert_success
}

# =============================================================================
# tmux integration specifics
# =============================================================================

@test "tmux.sh sets ZSH_TMUX_AUTOSTART when tmux is available" {
    if ! command -v tmux &>/dev/null; then
        skip "tmux not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'; echo \"\$ZSH_TMUX_AUTOSTART\""
    assert_success
    assert_output_contains "false"
}

@test "tmux.sh sets ZSH_TMUX_AUTOCONNECT when tmux is available" {
    if ! command -v tmux &>/dev/null; then
        skip "tmux not installed"
    fi
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'; echo \"\$ZSH_TMUX_AUTOCONNECT\""
    assert_success
    assert_output_contains "true"
}

@test "tmux.sh respects PIMPMYSHELL_TMUX_AUTOSTART override" {
    if ! command -v tmux &>/dev/null; then
        skip "tmux not installed"
    fi
    run bash -c "export PIMPMYSHELL_TMUX_AUTOSTART=true; source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'; echo \"\$ZSH_TMUX_AUTOSTART\""
    assert_success
    assert_output_contains "true"
}

@test "tmux.sh skips silently when tmux not installed" {
    run bash -c "PATH=/nonexistent source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'"
    assert_success
}

# =============================================================================
# delta integration specifics
# =============================================================================

@test "delta.sh defines configure_delta function" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/delta.sh'; declare -F configure_delta"
    assert_success
    assert_output_contains "configure_delta"
}

@test "delta.sh configure_delta succeeds without delta installed" {
    run bash -c "PATH=/nonexistent; source '${PIMPMYSHELL_MODULES_DIR}/integrations/delta.sh'; configure_delta"
    assert_success
}

# =============================================================================
# mise integration specifics
# =============================================================================

@test "mise.sh skips silently when mise not installed" {
    run bash -c "PATH=/nonexistent source '${PIMPMYSHELL_MODULES_DIR}/integrations/mise.sh'"
    assert_success
}

# =============================================================================
# zoxide integration specifics
# =============================================================================

@test "zoxide.sh skips silently when zoxide not installed" {
    run bash -c "PATH=/nonexistent source '${PIMPMYSHELL_MODULES_DIR}/integrations/zoxide.sh'"
    assert_success
}

# =============================================================================
# Re-sourcing guard
# =============================================================================

@test "fzf.sh re-sourcing is guarded" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'; source '${PIMPMYSHELL_MODULES_DIR}/integrations/fzf.sh'"
    assert_success
}

@test "tmux.sh re-sourcing is guarded" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'; source '${PIMPMYSHELL_MODULES_DIR}/integrations/tmux.sh'"
    assert_success
}

@test "delta.sh re-sourcing is guarded" {
    run bash -c "source '${PIMPMYSHELL_MODULES_DIR}/integrations/delta.sh'; source '${PIMPMYSHELL_MODULES_DIR}/integrations/delta.sh'"
    assert_success
}

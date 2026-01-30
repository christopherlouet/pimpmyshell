#!/usr/bin/env bash
# pimpmyshell - Environment diagnostics
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_DOCTOR_LOADED:-}" ]] && return 0
_PIMPMYSHELL_DOCTOR_LOADED=1

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

if [[ -z "${_PIMPMYSHELL_CONFIG_LOADED:-}" ]]; then
    # shellcheck source=./config.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/config.sh"
fi

if [[ -z "${_PIMPMYSHELL_THEMES_LOADED:-}" ]]; then
    # shellcheck source=./themes.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/themes.sh"
fi

if [[ -z "${_PIMPMYSHELL_PLUGINS_LOADED:-}" ]]; then
    # shellcheck source=./plugins.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/plugins.sh"
fi

if [[ -z "${_PIMPMYSHELL_TOOLS_LOADED:-}" ]]; then
    # shellcheck source=./tools.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/tools.sh"
fi

# -----------------------------------------------------------------------------
# Counters
# -----------------------------------------------------------------------------

_DOCTOR_PASS=0
_DOCTOR_WARN=0
_DOCTOR_FAIL=0

_doctor_pass() {
    echo -e "${GREEN}  [OK]${RESET} $*"
    ((_DOCTOR_PASS++)) || true
}

_doctor_warn() {
    echo -e "${YELLOW}  [WARN]${RESET} $*"
    ((_DOCTOR_WARN++)) || true
}

_doctor_fail() {
    echo -e "${RED}  [FAIL]${RESET} $*"
    ((_DOCTOR_FAIL++)) || true
}

_doctor_section() {
    echo ""
    echo -e "${BOLD}$*${RESET}"
}

# -----------------------------------------------------------------------------
# Individual Checks
# -----------------------------------------------------------------------------

## Check zsh shell
check_shell() {
    _doctor_section "Shell"

    # Check zsh is installed
    if check_command zsh; then
        local zsh_version
        zsh_version=$(zsh --version 2>/dev/null | head -1)
        _doctor_pass "zsh installed: ${zsh_version:-unknown version}"
    else
        _doctor_fail "zsh is not installed"
    fi

    # Check default shell
    local current_shell
    current_shell=$(basename "${SHELL:-unknown}")
    if [[ "$current_shell" == "zsh" ]]; then
        _doctor_pass "zsh is default shell"
    else
        _doctor_warn "zsh is not default shell (current: $current_shell)"
    fi

    # Check bash version
    local bash_major="${BASH_VERSINFO[0]:-0}"
    if [[ "$bash_major" -ge 4 ]]; then
        _doctor_pass "bash ${BASH_VERSION} (4.0+ required)"
    else
        _doctor_warn "bash ${BASH_VERSION} - version 4.0+ recommended"
    fi

    return 0
}

## Check oh-my-zsh framework
check_framework() {
    _doctor_section "Framework"

    local omz_dir="${OMZ_DIR:-${ZSH:-$HOME/.oh-my-zsh}}"

    if [[ -d "$omz_dir" && -f "${omz_dir}/oh-my-zsh.sh" ]]; then
        _doctor_pass "oh-my-zsh installed: $omz_dir"
    else
        _doctor_warn "oh-my-zsh not found at $omz_dir"
    fi

    return 0
}

## Check CLI tools from configuration
check_doctor_tools() {
    _doctor_section "Tools"

    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
    if [[ ! -f "$config_file" ]]; then
        _doctor_warn "No config file, skipping tools check"
        return 0
    fi

    # Required tools
    local required_tools
    required_tools=$(get_all_tools "required")
    if [[ -n "$required_tools" ]]; then
        while IFS= read -r tool; do
            [[ -z "$tool" ]] && continue
            if is_tool_installed "$tool"; then
                _doctor_pass "$tool (required)"
            else
                _doctor_fail "$tool (required) - not installed"
            fi
        done <<< "$required_tools"
    fi

    # Recommended tools
    local recommended_tools
    recommended_tools=$(get_all_tools "recommended")
    if [[ -n "$recommended_tools" ]]; then
        while IFS= read -r tool; do
            [[ -z "$tool" ]] && continue
            if is_tool_installed "$tool"; then
                _doctor_pass "$tool (recommended)"
            else
                _doctor_warn "$tool (recommended) - not installed"
            fi
        done <<< "$recommended_tools"
    fi

    # Check yq specifically
    if check_command yq; then
        _doctor_pass "yq (YAML parser)"
    else
        _doctor_fail "yq (YAML parser) - required for configuration"
    fi

    return 0
}

## Check plugins from configuration
check_doctor_plugins() {
    _doctor_section "Plugins"

    local omz_dir="${OMZ_DIR:-${ZSH:-$HOME/.oh-my-zsh}}"

    if [[ ! -d "$omz_dir" || ! -f "${omz_dir}/oh-my-zsh.sh" ]]; then
        _doctor_warn "oh-my-zsh not installed, skipping plugin check"
        return 0
    fi

    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
    if [[ ! -f "$config_file" ]]; then
        _doctor_warn "No config file, skipping plugin check"
        return 0
    fi

    # Standard plugins
    local omz_plugins
    omz_plugins=$(get_config_list '.plugins.ohmyzsh')
    if [[ -n "$omz_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            if [[ -d "${omz_dir}/plugins/${plugin}" ]]; then
                _doctor_pass "$plugin (standard)"
            else
                _doctor_warn "$plugin (standard) - not found"
            fi
        done <<< "$omz_plugins"
    fi

    # Custom plugins
    local custom_plugins
    custom_plugins=$(get_config_list '.plugins.custom')
    local custom_dir="${OMZ_CUSTOM_DIR:-${omz_dir}/custom}"
    if [[ -n "$custom_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            if [[ -d "${custom_dir}/plugins/${plugin}" ]]; then
                _doctor_pass "$plugin (custom)"
            else
                _doctor_fail "$plugin (custom) - not installed"
            fi
        done <<< "$custom_plugins"
    fi

    return 0
}

## Check theme files
check_doctor_theme() {
    _doctor_section "Theme"

    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
    local theme_name

    if [[ -f "$config_file" ]]; then
        theme_name=$(get_config '.theme' "$DEFAULT_THEME")
    else
        theme_name="$DEFAULT_THEME"
    fi

    echo -e "  Configured theme: ${CYAN}${theme_name}${RESET}"

    # Check theme YAML exists
    if get_theme_path "$theme_name" >/dev/null 2>&1; then
        _doctor_pass "$theme_name theme definition found"
    else
        _doctor_fail "$theme_name theme definition not found"
    fi

    # Check starship theme data
    local data_dir="${PIMPMYSHELL_THEMES_DIR}/data"
    if [[ -f "${data_dir}/${theme_name}.toml" ]]; then
        _doctor_pass "Starship theme file present"
    else
        _doctor_warn "Starship theme file missing: ${data_dir}/${theme_name}.toml"
    fi

    # Check eza theme data
    if [[ -f "${data_dir}/eza-${theme_name}.sh" ]]; then
        _doctor_pass "Eza theme file present"
    else
        _doctor_warn "Eza theme file missing: ${data_dir}/eza-${theme_name}.sh"
    fi

    # Check starship is installed
    if check_command starship; then
        _doctor_pass "Starship prompt engine installed"
    else
        _doctor_warn "Starship not installed (install: curl -sS https://starship.rs/install.sh | sh)"
    fi

    return 0
}

## Check configuration file
check_doctor_config() {
    _doctor_section "Config"

    local config_file="${PIMPMYSHELL_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"

    if [[ ! -f "$config_file" ]]; then
        _doctor_warn "Config file not found: $config_file"
        _doctor_warn "Create one with: pimpmyshell wizard"
        return 0
    fi

    _doctor_pass "Config file: $config_file"

    # Validate YAML syntax
    if check_command yq; then
        if yq_validate "$config_file" 2>/dev/null; then
            _doctor_pass "YAML syntax valid"
        else
            _doctor_fail "YAML syntax invalid"
        fi
    else
        _doctor_warn "Cannot validate YAML (yq not installed)"
    fi

    return 0
}

## Check for Nerd Font (heuristic)
check_nerd_font() {
    _doctor_section "Fonts"

    # Heuristic: check if fc-list is available and look for Nerd Font
    if check_command fc-list; then
        local nerd_fonts
        nerd_fonts=$(fc-list 2>/dev/null | grep -i "nerd\|powerline" | head -5)
        if [[ -n "$nerd_fonts" ]]; then
            _doctor_pass "Nerd Font detected"
        else
            _doctor_warn "No Nerd Font detected (icons may not display correctly)"
            echo "  Install from: https://www.nerdfonts.com/"
        fi
    else
        _doctor_warn "Cannot check fonts (fc-list not available)"
    fi

    return 0
}

## Check true color terminal support
check_true_color() {
    _doctor_section "Terminal"

    # Check COLORTERM
    if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
        _doctor_pass "True color support detected (COLORTERM=$COLORTERM)"
    elif [[ -n "${COLORTERM:-}" ]]; then
        _doctor_warn "Limited color support (COLORTERM=$COLORTERM)"
    else
        _doctor_warn "COLORTERM not set - true color support unknown"
    fi

    # Check TERM
    local term="${TERM:-unknown}"
    echo -e "  TERM: ${term}"

    return 0
}

# -----------------------------------------------------------------------------
# Orchestration
# -----------------------------------------------------------------------------

## Run all diagnostic checks
## Usage: run_doctor
run_doctor() {
    _DOCTOR_PASS=0
    _DOCTOR_WARN=0
    _DOCTOR_FAIL=0

    echo -e "${BOLD}pimpmyshell doctor${RESET} - Environment diagnostics"
    echo ""

    check_shell
    check_framework
    check_doctor_config
    check_doctor_theme
    check_doctor_tools
    check_doctor_plugins
    check_nerd_font
    check_true_color

    # Summary
    echo ""
    echo -e "${BOLD}Summary${RESET}"
    echo -e "  ${GREEN}${_DOCTOR_PASS} pass${RESET}, ${YELLOW}${_DOCTOR_WARN} warnings${RESET}, ${RED}${_DOCTOR_FAIL} failures${RESET}"

    if [[ $_DOCTOR_FAIL -gt 0 ]]; then
        echo ""
        echo "Run 'pimpmyshell tools install' to fix missing tools."
    fi

    return 0
}

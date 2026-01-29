#!/usr/bin/env bash
# pimpmyshell - Oh-My-Zsh plugin management
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_PLUGINS_LOADED:-}" ]] && return 0
_PIMPMYSHELL_PLUGINS_LOADED=1

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

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
OMZ_CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

# -----------------------------------------------------------------------------
# Plugin URL Registry
# -----------------------------------------------------------------------------

## Get the clone URL for a custom plugin
## Usage: get_plugin_url <plugin_name>
## Returns: URL or empty string if unknown
get_plugin_url() {
    local plugin_name="$1"
    case "$plugin_name" in
        zsh-autosuggestions)
            echo "https://github.com/zsh-users/zsh-autosuggestions.git" ;;
        zsh-syntax-highlighting)
            echo "https://github.com/zsh-users/zsh-syntax-highlighting.git" ;;
        zsh-bat)
            echo "https://github.com/fdellwing/zsh-bat.git" ;;
        zsh-completions)
            echo "https://github.com/zsh-users/zsh-completions.git" ;;
        zsh-history-substring-search)
            echo "https://github.com/zsh-users/zsh-history-substring-search.git" ;;
        fast-syntax-highlighting)
            echo "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" ;;
        fzf-tab)
            echo "https://github.com/Aloxaf/fzf-tab.git" ;;
        you-should-use)
            echo "https://github.com/MichaelAquil662/you-should-use.git" ;;
        *)
            echo "" ;;
    esac
}

# -----------------------------------------------------------------------------
# Oh-My-Zsh Detection
# -----------------------------------------------------------------------------

## Check if oh-my-zsh is installed
## Usage: is_omz_installed
is_omz_installed() {
    [[ -d "$OMZ_DIR" && -f "${OMZ_DIR}/oh-my-zsh.sh" ]]
}

## Install oh-my-zsh (unattended mode)
## Usage: install_omz
install_omz() {
    if is_omz_installed; then
        log_verbose "Oh-My-Zsh already installed: $OMZ_DIR"
        return 0
    fi

    log_info "Installing Oh-My-Zsh..."

    if ! check_command git; then
        log_error "git is required to install Oh-My-Zsh"
        return 1
    fi

    if ! check_command curl && ! check_command wget; then
        log_error "curl or wget is required to install Oh-My-Zsh"
        return 1
    fi

    # Use the official unattended install
    if check_command curl; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    local status=$?
    if [[ $status -eq 0 ]]; then
        log_success "Oh-My-Zsh installed successfully"
    else
        log_error "Oh-My-Zsh installation failed"
    fi
    return $status
}

# -----------------------------------------------------------------------------
# Plugin Detection
# -----------------------------------------------------------------------------

## Check if a plugin is a standard oh-my-zsh plugin
## Usage: is_standard_plugin <plugin_name>
is_standard_plugin() {
    local plugin_name="$1"
    [[ -d "${OMZ_DIR}/plugins/${plugin_name}" ]]
}

## Check if a plugin is installed (standard or custom)
## Usage: is_plugin_installed <plugin_name>
is_plugin_installed() {
    local plugin_name="$1"

    # Check standard plugins
    if [[ -d "${OMZ_DIR}/plugins/${plugin_name}" ]]; then
        return 0
    fi

    # Check custom plugins
    if [[ -d "${OMZ_CUSTOM_DIR}/plugins/${plugin_name}" ]]; then
        return 0
    fi

    return 1
}

# -----------------------------------------------------------------------------
# Plugin Installation
# -----------------------------------------------------------------------------

## Clone a custom plugin from its git URL
## Usage: clone_custom_plugin <plugin_name> [url]
clone_custom_plugin() {
    local plugin_name="$1"
    local url="${2:-}"
    local target_dir="${OMZ_CUSTOM_DIR}/plugins/${plugin_name}"

    # Already installed
    if [[ -d "$target_dir" ]]; then
        log_verbose "Plugin already installed: $plugin_name"
        return 0
    fi

    # Resolve URL if not provided
    if [[ -z "$url" ]]; then
        url=$(get_plugin_url "$plugin_name")
    fi

    if [[ -z "$url" ]]; then
        log_error "No URL found for custom plugin: $plugin_name"
        return 1
    fi

    if ! check_command git; then
        log_error "git is required to install custom plugins"
        return 1
    fi

    log_info "Cloning custom plugin: $plugin_name"
    mkdir -p "$(dirname "$target_dir")"

    if git clone --depth 1 "$url" "$target_dir" 2>/dev/null; then
        log_success "Installed plugin: $plugin_name"
        return 0
    else
        log_error "Failed to clone plugin: $plugin_name from $url"
        return 1
    fi
}

## Install all plugins from configuration
## Usage: install_plugins
install_plugins() {
    if ! is_omz_installed; then
        log_warn "Oh-My-Zsh is not installed. Run 'pimpmyshell tools install' first."
        return 1
    fi

    # Install custom plugins
    local custom_plugins
    custom_plugins=$(get_configured_plugins "custom")

    if [[ -n "$custom_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            clone_custom_plugin "$plugin"
        done <<< "$custom_plugins"
    fi

    log_verbose "Plugin installation complete"
    return 0
}

# -----------------------------------------------------------------------------
# Configuration Queries
# -----------------------------------------------------------------------------

## Get configured plugins by type
## Usage: get_configured_plugins <type>
## Types: "ohmyzsh" or "custom"
get_configured_plugins() {
    local plugin_type="$1"
    get_config_list ".plugins.${plugin_type}"
}

## Generate the full plugins list for .zshrc
## Usage: generate_plugins_list
## Returns: space-separated list of all plugins (standard + custom)
generate_plugins_list() {
    local all_plugins=""

    # Get ohmyzsh standard plugins
    local omz_plugins
    omz_plugins=$(get_configured_plugins "ohmyzsh")
    if [[ -n "$omz_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            if [[ -n "$all_plugins" ]]; then
                all_plugins="${all_plugins}"$'\n'"${plugin}"
            else
                all_plugins="$plugin"
            fi
        done <<< "$omz_plugins"
    fi

    # Get custom plugins
    local custom_plugins
    custom_plugins=$(get_configured_plugins "custom")
    if [[ -n "$custom_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            if [[ -n "$all_plugins" ]]; then
                all_plugins="${all_plugins}"$'\n'"${plugin}"
            else
                all_plugins="$plugin"
            fi
        done <<< "$custom_plugins"
    fi

    echo "$all_plugins"
}

# -----------------------------------------------------------------------------
# Status Reporting
# -----------------------------------------------------------------------------

## Check and report plugin installation status
## Usage: check_plugins_status
check_plugins_status() {
    local omz_plugins custom_plugins

    omz_plugins=$(get_configured_plugins "ohmyzsh")
    custom_plugins=$(get_configured_plugins "custom")

    if ! is_omz_installed; then
        log_warn "Oh-My-Zsh is not installed"
        return 0
    fi

    log_info "Checking plugin status..."

    # Check standard plugins
    if [[ -n "$omz_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            if is_plugin_installed "$plugin"; then
                log_success "$plugin (standard)"
            else
                log_warn "$plugin (standard) - not found"
            fi
        done <<< "$omz_plugins"
    fi

    # Check custom plugins
    if [[ -n "$custom_plugins" ]]; then
        while IFS= read -r plugin; do
            [[ -z "$plugin" ]] && continue
            if is_plugin_installed "$plugin"; then
                log_success "$plugin (custom)"
            else
                log_warn "$plugin (custom) - not installed"
            fi
        done <<< "$custom_plugins"
    fi

    return 0
}

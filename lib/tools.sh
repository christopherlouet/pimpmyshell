#!/usr/bin/env bash
# pimpmyshell - CLI tools detection and installation
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_TOOLS_LOADED:-}" ]] && return 0
_PIMPMYSHELL_TOOLS_LOADED=1

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
# Package Manager Detection
# -----------------------------------------------------------------------------

## Detect the system package manager
## Returns: apt, dnf, pacman, brew, or unknown
detect_pkg_manager() {
    if check_command brew; then
        echo "brew"
    elif check_command apt; then
        echo "apt"
    elif check_command dnf; then
        echo "dnf"
    elif check_command pacman; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# -----------------------------------------------------------------------------
# Tool Command Resolution
# -----------------------------------------------------------------------------

## Get the actual command name for a tool
## Some tools have different command names on different systems
## Usage: get_tool_command <tool_name>
get_tool_command() {
    local tool_name="$1"
    case "$tool_name" in
        bat)
            # Debian/Ubuntu installs as 'batcat'
            if check_command bat; then
                echo "bat"
            elif check_command batcat; then
                echo "batcat"
            else
                echo "bat"
            fi
            ;;
        fd)
            # Debian/Ubuntu installs as 'fdfind'
            if check_command fd; then
                echo "fd"
            elif check_command fdfind; then
                echo "fdfind"
            else
                echo "fd"
            fi
            ;;
        ripgrep)
            echo "rg"
            ;;
        delta)
            echo "delta"
            ;;
        *)
            echo "$tool_name"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Tool Installation
# -----------------------------------------------------------------------------

## Check if a tool is installed (using resolved command name)
## Usage: is_tool_installed <tool_name>
is_tool_installed() {
    local tool_name="$1"
    local cmd
    cmd=$(get_tool_command "$tool_name")
    check_command "$cmd"
}

## Get the package name for a tool on a given package manager
## Usage: get_tool_pkg_name <tool_name> <pkg_manager>
get_tool_pkg_name() {
    local tool_name="$1"
    local pkg_manager="$2"

    case "${tool_name}:${pkg_manager}" in
        fd:apt)         echo "fd-find" ;;
        fd:dnf)         echo "fd-find" ;;
        fd:pacman)      echo "fd" ;;
        fd:brew)        echo "fd" ;;
        delta:apt)      echo "git-delta" ;;
        delta:dnf)      echo "git-delta" ;;
        delta:pacman)   echo "git-delta" ;;
        delta:brew)     echo "git-delta" ;;
        ripgrep:*)      echo "ripgrep" ;;
        dust:apt)       echo "dust" ;;
        dust:brew)      echo "dust" ;;
        *)              echo "$tool_name" ;;
    esac
}

## Get the alternative installation command for a tool
## Usage: get_tool_alt_install <tool_name>
## Returns: install command string or empty
get_tool_alt_install() {
    local tool_name="$1"
    case "$tool_name" in
        eza)        echo "cargo install eza" ;;
        bat)        echo "cargo install bat" ;;
        fd)         echo "cargo install fd-find" ;;
        ripgrep)    echo "cargo install ripgrep" ;;
        zoxide)     echo "cargo install zoxide" ;;
        delta)      echo "cargo install git-delta" ;;
        dust)       echo "cargo install du-dust" ;;
        hyperfine)  echo "cargo install hyperfine" ;;
        starship)   echo "curl -sS https://starship.rs/install.sh | sh" ;;
        tldr)       echo "npm install -g tldr" ;;
        fzf)        echo "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install" ;;
        *)          echo "" ;;
    esac
}

## Install a tool using its alternative method (cargo, npm, git clone, etc.)
## Direct dispatch without eval for security
## Usage: _install_tool_alternative <tool_name>
_install_tool_alternative() {
    local tool_name="$1"
    case "$tool_name" in
        eza)        cargo install eza ;;
        bat)        cargo install bat ;;
        fd)         cargo install fd-find ;;
        ripgrep)    cargo install ripgrep ;;
        zoxide)     cargo install zoxide ;;
        delta)      cargo install git-delta ;;
        dust)       cargo install du-dust ;;
        hyperfine)  cargo install hyperfine ;;
        starship)
            local tmp_script
            tmp_script=$(mktemp)
            trap 'rm -f "$tmp_script"' RETURN
            if curl -sS -o "$tmp_script" https://starship.rs/install.sh; then
                sh "$tmp_script"
            else
                log_error "Failed to download starship installer"
                return 1
            fi
            ;;
        tldr)       npm install -g tldr ;;
        fzf)
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
            ;;
        *)
            log_error "No alternative install method for: $tool_name"
            return 1
            ;;
    esac
}

## Install a single tool using the system package manager
## Usage: install_tool <tool_name> [pkg_manager]
install_tool() {
    local tool_name="$1"
    local pkg_manager="${2:-}"

    if is_tool_installed "$tool_name"; then
        log_verbose "$tool_name is already installed"
        return 0
    fi

    if [[ -z "$pkg_manager" ]]; then
        pkg_manager=$(detect_pkg_manager)
    fi

    local pkg_name
    pkg_name=$(get_tool_pkg_name "$tool_name" "$pkg_manager")

    log_info "Installing $tool_name ($pkg_name via $pkg_manager)..."

    case "$pkg_manager" in
        apt)
            sudo apt install -y "$pkg_name"
            ;;
        dnf)
            sudo dnf install -y "$pkg_name"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$pkg_name"
            ;;
        brew)
            brew install "$pkg_name"
            ;;
        *)
            # Try alternative install (direct dispatch, no eval)
            if ! _install_tool_alternative "$tool_name"; then
                log_error "Cannot install $tool_name: no package manager or alternative found"
                return 1
            fi
            ;;
    esac

    local status=$?
    if [[ $status -eq 0 ]] && is_tool_installed "$tool_name"; then
        log_success "Installed: $tool_name"
    else
        log_warn "Could not install $tool_name via $pkg_manager"
        # Try alternative
        local alt_cmd
        alt_cmd=$(get_tool_alt_install "$tool_name")
        if [[ -n "$alt_cmd" ]]; then
            log_info "Alternative: $alt_cmd"
        fi
        return 1
    fi
    return 0
}

## Install all tools from configuration
## Usage: install_all_tools [--required-only]
install_all_tools() {
    local required_only="${1:-false}"
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)

    log_info "Package manager: $pkg_manager"

    # Install required tools
    local required_tools
    required_tools=$(get_all_tools "required")
    if [[ -n "$required_tools" ]]; then
        log_info "Installing required tools..."
        while IFS= read -r tool; do
            [[ -z "$tool" ]] && continue
            install_tool "$tool" "$pkg_manager"
        done <<< "$required_tools"
    fi

    # Install recommended tools (unless --required-only)
    if [[ "$required_only" != "--required-only" ]]; then
        local recommended_tools
        recommended_tools=$(get_all_tools "recommended")
        if [[ -n "$recommended_tools" ]]; then
            log_info "Installing recommended tools..."
            while IFS= read -r tool; do
                [[ -z "$tool" ]] && continue
                install_tool "$tool" "$pkg_manager"
            done <<< "$recommended_tools"
        fi
    fi

    return 0
}

# -----------------------------------------------------------------------------
# Configuration Queries
# -----------------------------------------------------------------------------

## Get tools from configuration by category
## Usage: get_all_tools <category>
## Categories: "required" or "recommended"
get_all_tools() {
    local category="$1"
    get_config_list ".tools.${category}"
}

# -----------------------------------------------------------------------------
# Status Reporting
# -----------------------------------------------------------------------------

## Check and report tool installation status
## Usage: check_tools
check_tools() {
    local required_tools recommended_tools

    required_tools=$(get_all_tools "required")
    recommended_tools=$(get_all_tools "recommended")

    local installed=0
    local missing=0

    if [[ -n "$required_tools" ]]; then
        log_info "Required tools:"
        while IFS= read -r tool; do
            [[ -z "$tool" ]] && continue
            local cmd
            cmd=$(get_tool_command "$tool")
            if is_tool_installed "$tool"; then
                local version=""
                version=$($cmd --version 2>/dev/null | head -1) || true
                log_success "$tool ($cmd) ${version:+- $version}"
                ((installed++))
            else
                local alt
                alt=$(get_tool_alt_install "$tool")
                log_warn "$tool - NOT INSTALLED${alt:+ (install: $alt)}"
                ((missing++))
            fi
        done <<< "$required_tools"
    fi

    if [[ -n "$recommended_tools" ]]; then
        echo ""
        log_info "Recommended tools:"
        while IFS= read -r tool; do
            [[ -z "$tool" ]] && continue
            local cmd
            cmd=$(get_tool_command "$tool")
            if is_tool_installed "$tool"; then
                local version=""
                version=$($cmd --version 2>/dev/null | head -1) || true
                log_success "$tool ($cmd) ${version:+- $version}"
                ((installed++))
            else
                local alt
                alt=$(get_tool_alt_install "$tool")
                log_info "$tool - not installed${alt:+ (install: $alt)}"
                ((missing++))
            fi
        done <<< "$recommended_tools"
    fi

    echo ""
    log_info "Summary: $installed installed, $missing missing"
    return 0
}

#!/usr/bin/env bash
# pimpmyshell installer
# https://github.com/christopherlouet/pimpmyshell
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/christopherlouet/pimpmyshell/main/install.sh | bash
#   or
#   git clone https://github.com/christopherlouet/pimpmyshell.git && cd pimpmyshell && ./install.sh

set -euo pipefail

# -----------------------------------------------------------------------------
# Colors and formatting
# -----------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Disable colors if not interactive
if [[ ! -t 1 ]]; then
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' DIM='' RESET=''
fi

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

info() {
    echo -e "${GREEN}[INFO]${RESET} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

success() {
    echo -e "${GREEN}[OK]${RESET} $*"
}

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

PIMPMYSHELL_VERSION="0.2.0"
PIMPMYSHELL_REPO="https://github.com/christopherlouet/pimpmyshell.git"
PIMPMYSHELL_INSTALL_DIR="${PIMPMYSHELL_INSTALL_DIR:-$HOME/.pimpmyshell}"
PIMPMYSHELL_CONFIG_DIR="${PIMPMYSHELL_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pimpmyshell}"
PIMPMYSHELL_DATA_DIR="${PIMPMYSHELL_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/pimpmyshell}"
PIMPMYSHELL_BIN_DIR="${PIMPMYSHELL_BIN_DIR:-$HOME/.local/bin}"

# Detect script directory (if running from local clone)
PIMPMYSHELL_SCRIPT_DIR="${PIMPMYSHELL_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")}"

# -----------------------------------------------------------------------------
# Platform detection
# -----------------------------------------------------------------------------

get_platform() {
    local uname_out
    uname_out="$(uname -s)"

    case "${uname_out}" in
        Linux*)
            if grep -qEi "(microsoft|wsl)" /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------

check_prerequisite_command() {
    command -v "$1" &>/dev/null
}

# -----------------------------------------------------------------------------
# Package manager detection
# -----------------------------------------------------------------------------

detect_package_manager() {
    if check_prerequisite_command brew; then
        echo "brew"
    elif check_prerequisite_command apt-get; then
        echo "apt"
    elif check_prerequisite_command dnf; then
        echo "dnf"
    elif check_prerequisite_command pacman; then
        echo "pacman"
    elif check_prerequisite_command apk; then
        echo "apk"
    elif check_prerequisite_command zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# -----------------------------------------------------------------------------
# Prerequisite checks
# -----------------------------------------------------------------------------

check_prerequisites() {
    local missing=()
    local platform
    platform=$(get_platform)

    # Required: git
    if ! check_prerequisite_command git; then
        missing+=("git")
    fi

    # Required: zsh (warn but don't block)
    if ! check_prerequisite_command zsh; then
        warn "zsh not found - pimpmyshell is designed for zsh"
        echo ""
        echo "Install zsh with:"
        case "$platform" in
            macos)
                echo "  zsh is included with macOS"
                ;;
            linux|wsl)
                echo "  sudo apt install zsh    # Debian/Ubuntu"
                echo "  sudo dnf install zsh    # Fedora"
                echo "  sudo pacman -S zsh      # Arch"
                ;;
        esac
        echo ""
    fi

    # Required: bash 4+ (for associative arrays etc.)
    local bash_major
    bash_major="${BASH_VERSINFO[0]:-0}"
    if [[ "$bash_major" -lt 4 ]]; then
        warn "bash $BASH_VERSION detected. Recommended: bash 4.0+"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        echo ""
        echo "Install them with:"
        case "$platform" in
            macos)
                echo "  brew install ${missing[*]}"
                ;;
            linux|wsl)
                echo "  sudo apt install ${missing[*]}    # Debian/Ubuntu"
                echo "  sudo dnf install ${missing[*]}    # Fedora"
                echo "  sudo pacman -S ${missing[*]}      # Arch"
                ;;
        esac
        return 1
    fi

    return 0
}

# -----------------------------------------------------------------------------
# Installation helpers
# -----------------------------------------------------------------------------

## Ask user for confirmation
confirm() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n] " answer
        [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
    else
        read -rp "$prompt [y/N] " answer
        [[ "$answer" =~ ^[Yy] ]]
    fi
}

## Install yq (Go version)
install_yq() {
    local pkg_manager
    pkg_manager=$(detect_package_manager)

    if check_prerequisite_command yq; then
        success "yq is already installed"
        return 0
    fi

    if [[ "$pkg_manager" == "brew" ]]; then
        brew install yq
    else
        info "Downloading yq binary..."
        local arch
        arch=$(uname -m)
        case "$arch" in
            x86_64) arch="amd64" ;;
            aarch64|arm64) arch="arm64" ;;
            armv7l) arch="arm" ;;
            *) error "Unsupported architecture: $arch"; return 1 ;;
        esac

        local os="linux"
        [[ "$(get_platform)" == "macos" ]] && os="darwin"

        local url="https://github.com/mikefarah/yq/releases/latest/download/yq_${os}_${arch}"
        local dest="/usr/local/bin/yq"

        if sudo wget -qO "$dest" "$url" 2>/dev/null || sudo curl -fsSL -o "$dest" "$url" 2>/dev/null; then
            sudo chmod +x "$dest"
            success "Installed yq to $dest"
        else
            error "Failed to download yq"
            return 1
        fi
    fi
}

## Install oh-my-zsh
install_omz() {
    local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"

    if [[ -d "$omz_dir" ]]; then
        success "oh-my-zsh is already installed"
        return 0
    fi

    info "Installing oh-my-zsh..."
    if check_prerequisite_command curl; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    elif check_prerequisite_command wget; then
        sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        error "Neither curl nor wget available. Cannot install oh-my-zsh."
        return 1
    fi

    success "Installed oh-my-zsh"
}

## Detect user's shell
detect_shell() {
    local shell_name
    shell_name=$(basename "${SHELL:-/bin/bash}")
    echo "$shell_name"
}

# -----------------------------------------------------------------------------
# Directory setup
# -----------------------------------------------------------------------------

setup_directories() {
    mkdir -p "$PIMPMYSHELL_INSTALL_DIR"
    mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
    mkdir -p "$PIMPMYSHELL_DATA_DIR"
    mkdir -p "$PIMPMYSHELL_BIN_DIR"
    mkdir -p "${PIMPMYSHELL_DATA_DIR}/backups"
}

# -----------------------------------------------------------------------------
# Symlink CLI
# -----------------------------------------------------------------------------

setup_symlink() {
    local cli_source="${PIMPMYSHELL_INSTALL_DIR}/bin/pimpmyshell"

    if [[ ! -f "$cli_source" ]]; then
        error "CLI binary not found: $cli_source"
        return 1
    fi

    chmod +x "$cli_source"
    ln -sf "$cli_source" "${PIMPMYSHELL_BIN_DIR}/pimpmyshell"
    success "CLI available at ${PIMPMYSHELL_BIN_DIR}/pimpmyshell"
}

# -----------------------------------------------------------------------------
# Copy example config
# -----------------------------------------------------------------------------

copy_config_example() {
    local example="${PIMPMYSHELL_INSTALL_DIR}/pimpmyshell.yaml.example"
    local target="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    if [[ -f "$target" ]]; then
        info "Keeping existing configuration: $target"
        return 0
    fi

    if [[ -f "$example" ]]; then
        mkdir -p "$PIMPMYSHELL_CONFIG_DIR"
        cp "$example" "$target"
        success "Created default config: $target"
    else
        warn "Example config not found: $example"
    fi
}

# -----------------------------------------------------------------------------
# Install from local repo
# -----------------------------------------------------------------------------

install_from_local() {
    local script_dir="${PIMPMYSHELL_SCRIPT_DIR:-}"

    if [[ -z "$script_dir" || ! -f "${script_dir}/bin/pimpmyshell" ]]; then
        error "Local repository not found"
        return 1
    fi

    if [[ "$script_dir" == "$PIMPMYSHELL_INSTALL_DIR" ]]; then
        info "Already in install directory"
        return 0
    fi

    info "Installing from local repository..."
    rm -rf "$PIMPMYSHELL_INSTALL_DIR"
    cp -r "$script_dir" "$PIMPMYSHELL_INSTALL_DIR"
    success "Installed from local"
}

# -----------------------------------------------------------------------------
# Install from git
# -----------------------------------------------------------------------------

install_from_git() {
    if [[ -d "${PIMPMYSHELL_INSTALL_DIR}/.git" ]]; then
        info "Updating pimpmyshell..."
        cd "$PIMPMYSHELL_INSTALL_DIR"
        if ! git remote get-url origin &>/dev/null; then
            git remote add origin "$PIMPMYSHELL_REPO"
        fi
        git pull origin main --quiet
        success "Updated to latest version"
    else
        info "Cloning pimpmyshell repository..."
        git clone --quiet "$PIMPMYSHELL_REPO" "$PIMPMYSHELL_INSTALL_DIR"
        success "Cloned repository"
    fi
}

# -----------------------------------------------------------------------------
# Shell Completions
# -----------------------------------------------------------------------------

install_completions() {
    local user_shell
    user_shell=$(detect_shell)
    local completions_dir="${PIMPMYSHELL_INSTALL_DIR}/completions"

    echo ""
    info "Setting up shell completions..."

    case "$user_shell" in
        zsh)
            install_zsh_completion
            ;;
        bash)
            install_bash_completion
            ;;
        *)
            info "Shell completions available in ${completions_dir}"
            ;;
    esac
}

install_zsh_completion() {
    local completions_dir="${PIMPMYSHELL_INSTALL_DIR}/completions"
    local zsh_completion_file="${completions_dir}/pimpmyshell.zsh"

    if [[ ! -f "$zsh_completion_file" ]]; then
        warn "Zsh completion file not found"
        return 1
    fi

    local user_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
    mkdir -p "$user_dir"
    cp "$zsh_completion_file" "${user_dir}/_pimpmyshell"
    success "Installed Zsh completion to $user_dir"

    if ! grep -q "$user_dir" ~/.zshrc 2>/dev/null; then
        echo ""
        info "Add this to your ~/.zshrc (before compinit):"
        echo "  fpath=(${user_dir} \$fpath)"
        echo "  autoload -Uz compinit && compinit"
    fi
}

install_bash_completion() {
    local completions_dir="${PIMPMYSHELL_INSTALL_DIR}/completions"
    local bash_completion_file="${completions_dir}/pimpmyshell.bash"

    if [[ ! -f "$bash_completion_file" ]]; then
        warn "Bash completion file not found"
        return 1
    fi

    local user_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    mkdir -p "$user_dir"
    cp "$bash_completion_file" "${user_dir}/pimpmyshell"
    success "Installed Bash completion to $user_dir"

    if ! grep -q "bash-completion" ~/.bashrc 2>/dev/null; then
        echo ""
        info "Add this to your ~/.bashrc to enable completions:"
        echo "  source ${user_dir}/pimpmyshell"
    fi
}

# -----------------------------------------------------------------------------
# Uninstall
# -----------------------------------------------------------------------------

uninstall_pimpmyshell() {
    echo ""
    warn "Uninstalling pimpmyshell..."

    # Remove symlink
    rm -f "${PIMPMYSHELL_BIN_DIR}/pimpmyshell"

    # Remove install directory
    rm -rf "$PIMPMYSHELL_INSTALL_DIR"

    # Remove completions
    rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions/_pimpmyshell"
    rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/pimpmyshell"

    echo ""
    info "Removed pimpmyshell installation"
    info "Config preserved at: ${PIMPMYSHELL_CONFIG_DIR}"
    info "Data preserved at: ${PIMPMYSHELL_DATA_DIR}"
    echo ""
    echo "To fully remove, also run:"
    echo "  rm -rf ${PIMPMYSHELL_CONFIG_DIR}"
    echo "  rm -rf ${PIMPMYSHELL_DATA_DIR}"
}

# -----------------------------------------------------------------------------
# Main installation
# -----------------------------------------------------------------------------

install_pimpmyshell() {
    echo ""
    echo -e "${BOLD}${MAGENTA}"
    cat << 'EOF'
        .__                                        .__           .__  .__
______  |__| _____ ______  _____ ___.__.  _____  |  |__   ____ |  | |  |
\____ \ |  |/     \\____ \/     <   |  | /     \ |  |  \_/ __ \|  | |  |
|  |_> >|  |  Y Y  \  |_> >  Y  \___  ||  Y Y  \|   Y  \  ___/|  |_|  |__
|   __/ |__|__|_|  /   __/|__|_|  / ____||__|_|  /|___|  /\___  >____/____/
|__|             \/|__|         \/\/            \/      \/     \/
EOF
    echo -e "${RESET}"
    echo -e "${DIM}Configure a complete, beautiful zsh environment${RESET}"
    echo ""

    info "Installing pimpmyshell v${PIMPMYSHELL_VERSION}..."
    echo ""

    # Check prerequisites
    info "Checking prerequisites..."
    check_prerequisites

    # Check yq
    if ! check_prerequisite_command yq; then
        echo ""
        if confirm "Install yq (required for YAML parsing)?"; then
            install_yq
        else
            warn "yq is required. Install manually: https://github.com/mikefarah/yq"
        fi
    else
        success "yq is installed"
    fi

    # Check oh-my-zsh
    local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
    if [[ ! -d "$omz_dir" ]]; then
        echo ""
        if confirm "Install oh-my-zsh (recommended)?"; then
            install_omz
        else
            info "Skipping oh-my-zsh installation"
        fi
    else
        success "oh-my-zsh is installed"
    fi

    # Create directories
    echo ""
    info "Creating directories..."
    setup_directories

    # Install from local or git
    if [[ -n "${PIMPMYSHELL_SCRIPT_DIR:-}" && -f "${PIMPMYSHELL_SCRIPT_DIR}/bin/pimpmyshell" ]]; then
        install_from_local
    else
        install_from_git
    fi

    # Create CLI symlink
    info "Setting up CLI..."
    setup_symlink

    # Install completions
    install_completions

    # Copy example config
    copy_config_example

    # Check PATH
    if [[ ":$PATH:" != *":${PIMPMYSHELL_BIN_DIR}:"* ]]; then
        echo ""
        warn "${PIMPMYSHELL_BIN_DIR} is not in your PATH"
        echo ""
        echo "Add it to your shell configuration:"
        echo ""
        echo "  # Zsh (~/.zshrc)"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        echo "  # Bash (~/.bashrc)"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    # Check default shell
    if [[ "$(basename "${SHELL:-}")" != "zsh" ]]; then
        echo ""
        info "Set zsh as your default shell:"
        echo "  chsh -s \$(which zsh)"
    fi

    # Done!
    echo ""
    echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
    echo ""
    echo "Next steps:"
    echo -e "  1. Edit config: ${CYAN}${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml${RESET}"
    echo -e "  2. Apply config: ${CYAN}pimpmyshell apply${RESET}"
    echo -e "  3. List themes:  ${CYAN}pimpmyshell theme --list${RESET}"
    echo -e "  4. Run wizard:   ${CYAN}pimpmyshell wizard${RESET}"
    echo ""
    echo "Documentation: https://github.com/christopherlouet/pimpmyshell"
    echo ""
}

# -----------------------------------------------------------------------------
# Main routing
# -----------------------------------------------------------------------------

main() {
    case "${1:-install}" in
        install)
            install_pimpmyshell
            ;;
        uninstall|remove)
            uninstall_pimpmyshell
            ;;
        --help|-h)
            echo "Usage: $0 [install|uninstall]"
            echo ""
            echo "Commands:"
            echo "  install    Install pimpmyshell (default)"
            echo "  uninstall  Remove pimpmyshell"
            ;;
        *)
            error "Unknown command: $1"
            echo "Usage: $0 [install|uninstall]"
            exit 1
            ;;
    esac
}

# Run main only if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

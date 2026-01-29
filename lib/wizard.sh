#!/usr/bin/env bash
# pimpmyshell - Interactive setup wizard
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_WIZARD_LOADED:-}" ]] && return 0
_PIMPMYSHELL_WIZARD_LOADED=1

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

# -----------------------------------------------------------------------------
# Wizard state variables
# -----------------------------------------------------------------------------

WIZARD_THEME="${WIZARD_THEME:-cyberpunk}"
WIZARD_FRAMEWORK="${WIZARD_FRAMEWORK:-ohmyzsh}"
WIZARD_PROMPT_ENGINE="${WIZARD_PROMPT_ENGINE:-starship}"
WIZARD_OMZ_PLUGINS="${WIZARD_OMZ_PLUGINS:-git fzf}"
WIZARD_CUSTOM_PLUGINS="${WIZARD_CUSTOM_PLUGINS:-zsh-autosuggestions zsh-syntax-highlighting}"
WIZARD_ALIAS_GROUPS="${WIZARD_ALIAS_GROUPS:-git docker navigation files}"
WIZARD_ALIASES_ENABLED="${WIZARD_ALIASES_ENABLED:-true}"

# -----------------------------------------------------------------------------
# UI Helpers
# -----------------------------------------------------------------------------

## Check if gum TUI toolkit is available
_use_gum() {
    [[ -z "${WIZARD_AUTO:-}" ]] && check_command gum
}

## Display a wizard header
_wizard_header() {
    local title="$1"

    if _use_gum; then
        gum style --border rounded --padding "0 2" --foreground 212 "$title"
    else
        echo ""
        echo -e "${BOLD}${MAGENTA}$title${RESET}"
        echo ""
    fi
}

## Display a step indicator
_wizard_step() {
    local current="$1"
    local total="$2"
    local description="$3"

    echo -e "${DIM}Step ${current}/${total}${RESET} - ${BOLD}${description}${RESET}"
    echo ""
}

## Single choice selector
## Usage: _wizard_choose <prompt> <option1> <option2> ...
## Returns: selected option on stdout
_wizard_choose() {
    local prompt="$1"
    shift
    local options=("$@")

    # Auto mode: return default or first option
    if [[ -n "${WIZARD_AUTO:-}" ]]; then
        if [[ -n "${WIZARD_DEFAULT:-}" ]]; then
            # Return matching option
            for opt in "${options[@]}"; do
                if [[ "$opt" == "$WIZARD_DEFAULT" || "$opt" == "${WIZARD_DEFAULT}"* ]]; then
                    echo "$opt"
                    return 0
                fi
            done
        fi
        echo "${options[0]}"
        return 0
    fi

    if _use_gum; then
        gum choose --header "$prompt" "${options[@]}"
    else
        echo "$prompt"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        echo ""
        read -rp "Enter choice (1-${#options[@]}): " choice
        if [[ -n "$choice" && "$choice" -ge 1 && "$choice" -le ${#options[@]} ]] 2>/dev/null; then
            echo "${options[$((choice - 1))]}"
        else
            echo "${options[0]}"
        fi
    fi
}

## Multiple choice selector
## Usage: _wizard_choose_multi <prompt> <option1> <option2> ...
## Returns: selected options, one per line
_wizard_choose_multi() {
    local prompt="$1"
    shift
    local options=("$@")

    # Auto mode: return all options
    if [[ -n "${WIZARD_AUTO:-}" ]]; then
        printf '%s\n' "${options[@]}"
        return 0
    fi

    if _use_gum; then
        gum choose --no-limit --header "$prompt" "${options[@]}"
    else
        echo "$prompt"
        echo "(Enter numbers separated by spaces, or 'all')"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        echo ""
        read -rp "Enter choices: " choices

        if [[ "$choices" == "all" || -z "$choices" ]]; then
            printf '%s\n' "${options[@]}"
        else
            for num in $choices; do
                if [[ "$num" -ge 1 && "$num" -le ${#options[@]} ]] 2>/dev/null; then
                    echo "${options[$((num - 1))]}"
                fi
            done
        fi
    fi
}

## Yes/No confirmation
## Usage: _wizard_confirm <prompt> [default]
## Returns: "true" or "false"
_wizard_confirm() {
    local prompt="$1"
    local default="${2:-true}"

    # Auto mode: return default
    if [[ -n "${WIZARD_AUTO:-}" ]]; then
        echo "$default"
        return 0
    fi

    if _use_gum; then
        if gum confirm "$prompt"; then
            echo "true"
        else
            echo "false"
        fi
    else
        local yn="[Y/n]"
        [[ "$default" == "false" ]] && yn="[y/N]"
        read -rp "$prompt $yn " answer

        case "${answer,,}" in
            y|yes) echo "true" ;;
            n|no) echo "false" ;;
            *) echo "$default" ;;
        esac
    fi
}

## Text input
## Usage: _wizard_input <prompt> [default] [placeholder]
## Returns: entered text
_wizard_input() {
    local prompt="$1"
    local default="${2:-}"
    local placeholder="${3:-}"

    # Auto mode: return default
    if [[ -n "${WIZARD_AUTO:-}" ]]; then
        echo "$default"
        return 0
    fi

    if _use_gum; then
        gum input --placeholder "${placeholder:-$default}" --value "$default" --header "$prompt"
    else
        read -rp "$prompt [${default}]: " answer
        echo "${answer:-$default}"
    fi
}

# -----------------------------------------------------------------------------
# Wizard Steps
# -----------------------------------------------------------------------------

## Step 1: Welcome and prerequisites
_wizard_step_welcome() {
    _wizard_header "pimpmyshell Setup Wizard"

    echo "This wizard will help you configure your shell environment."
    echo ""

    # Check prerequisites
    if check_command zsh; then
        log_success "zsh is installed"
    else
        log_warn "zsh is not installed - pimpmyshell requires zsh"
    fi

    if check_command git; then
        log_success "git is installed"
    else
        log_warn "git is not installed"
    fi

    if check_command yq; then
        log_success "yq is installed"
    else
        log_warn "yq is not installed (required for YAML parsing)"
    fi

    echo ""
}

## Step 2: Choose theme
_wizard_step_theme() {
    _wizard_step 1 6 "Choose a theme"

    local themes
    themes=$(list_themes 2>/dev/null)
    if [[ -z "$themes" ]]; then
        log_warn "No themes found, using default: cyberpunk"
        WIZARD_THEME="cyberpunk"
        return 0
    fi

    local theme_array=()
    while IFS= read -r theme; do
        [[ -n "$theme" ]] && theme_array+=("$theme")
    done <<< "$themes"

    WIZARD_THEME=$(WIZARD_DEFAULT="$WIZARD_THEME" _wizard_choose "Select a theme:" "${theme_array[@]}")
    log_info "Theme: $WIZARD_THEME"
}

## Step 3: Choose plugins
_wizard_step_plugins() {
    _wizard_step 2 6 "Choose plugins"

    # Standard plugins
    local omz_options=("git" "fzf" "tmux" "docker" "kubectl" "extract" "web-search" "wd" "mise" "eza")
    local selected_omz
    selected_omz=$(_wizard_choose_multi "Select Oh-My-Zsh plugins:" "${omz_options[@]}")

    WIZARD_OMZ_PLUGINS=""
    while IFS= read -r plugin; do
        [[ -z "$plugin" ]] && continue
        if [[ -n "$WIZARD_OMZ_PLUGINS" ]]; then
            WIZARD_OMZ_PLUGINS="${WIZARD_OMZ_PLUGINS} ${plugin}"
        else
            WIZARD_OMZ_PLUGINS="$plugin"
        fi
    done <<< "$selected_omz"

    # Custom plugins
    local custom_options=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-bat" "zsh-completions" "fzf-tab")
    local selected_custom
    selected_custom=$(_wizard_choose_multi "Select custom plugins:" "${custom_options[@]}")

    WIZARD_CUSTOM_PLUGINS=""
    while IFS= read -r plugin; do
        [[ -z "$plugin" ]] && continue
        if [[ -n "$WIZARD_CUSTOM_PLUGINS" ]]; then
            WIZARD_CUSTOM_PLUGINS="${WIZARD_CUSTOM_PLUGINS} ${plugin}"
        else
            WIZARD_CUSTOM_PLUGINS="$plugin"
        fi
    done <<< "$selected_custom"

    log_info "Standard plugins: $WIZARD_OMZ_PLUGINS"
    log_info "Custom plugins: $WIZARD_CUSTOM_PLUGINS"
}

## Step 4: Choose alias groups
_wizard_step_aliases() {
    _wizard_step 3 6 "Choose alias groups"

    local alias_options=("git" "docker" "kubernetes" "navigation" "files")
    local selected
    selected=$(_wizard_choose_multi "Select alias groups:" "${alias_options[@]}")

    WIZARD_ALIAS_GROUPS=""
    while IFS= read -r group; do
        [[ -z "$group" ]] && continue
        if [[ -n "$WIZARD_ALIAS_GROUPS" ]]; then
            WIZARD_ALIAS_GROUPS="${WIZARD_ALIAS_GROUPS} ${group}"
        else
            WIZARD_ALIAS_GROUPS="$group"
        fi
    done <<< "$selected"

    WIZARD_ALIASES_ENABLED="true"
    [[ -z "$WIZARD_ALIAS_GROUPS" ]] && WIZARD_ALIASES_ENABLED="false"

    log_info "Alias groups: ${WIZARD_ALIAS_GROUPS:-none}"
}

## Step 5: Choose integrations
_wizard_step_integrations() {
    _wizard_step 4 6 "Choose integrations"

    local integ_options=("fzf" "mise" "tmux" "zoxide" "delta")
    local selected
    selected=$(_wizard_choose_multi "Select integrations:" "${integ_options[@]}")

    WIZARD_INTEGRATIONS=""
    while IFS= read -r integ; do
        [[ -z "$integ" ]] && continue
        if [[ -n "$WIZARD_INTEGRATIONS" ]]; then
            WIZARD_INTEGRATIONS="${WIZARD_INTEGRATIONS} ${integ}"
        else
            WIZARD_INTEGRATIONS="$integ"
        fi
    done <<< "$selected"

    log_info "Integrations: ${WIZARD_INTEGRATIONS:-none}"
}

## Step 6: Preview and confirm
_wizard_step_preview() {
    _wizard_step 5 6 "Preview configuration"

    echo "Configuration summary:"
    echo ""
    echo "  Theme:           $WIZARD_THEME"
    echo "  Framework:       $WIZARD_FRAMEWORK"
    echo "  Prompt engine:   $WIZARD_PROMPT_ENGINE"
    echo "  OMZ plugins:     $WIZARD_OMZ_PLUGINS"
    echo "  Custom plugins:  $WIZARD_CUSTOM_PLUGINS"
    echo "  Alias groups:    $WIZARD_ALIAS_GROUPS"
    echo "  Integrations:    ${WIZARD_INTEGRATIONS:-none}"
    echo ""

    local confirmed
    confirmed=$(_wizard_confirm "Generate configuration with these settings?")

    if [[ "$confirmed" != "true" ]]; then
        log_info "Wizard cancelled."
        return 1
    fi

    return 0
}

# -----------------------------------------------------------------------------
# Config Generation
# -----------------------------------------------------------------------------

## Generate pimpmyshell.yaml from wizard state
## Usage: _wizard_generate_config [config_file]
_wizard_generate_config() {
    local config_file="${1:-${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml}"

    mkdir -p "$(dirname "$config_file")"

    # Build YAML content
    {
        echo "# pimpmyshell configuration"
        echo "# Generated by setup wizard on $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "theme: ${WIZARD_THEME:-cyberpunk}"
        echo ""
        echo "shell:"
        echo "  framework: ${WIZARD_FRAMEWORK:-ohmyzsh}"
        echo ""
        echo "prompt:"
        echo "  engine: ${WIZARD_PROMPT_ENGINE:-starship}"
        echo ""
        echo "plugins:"
        echo "  ohmyzsh:"

        # OMZ plugins
        for plugin in ${WIZARD_OMZ_PLUGINS:-git}; do
            echo "    - $plugin"
        done

        echo "  custom:"
        # Custom plugins
        if [[ -n "${WIZARD_CUSTOM_PLUGINS:-}" ]]; then
            for plugin in ${WIZARD_CUSTOM_PLUGINS}; do
                echo "    - $plugin"
            done
        fi

        echo ""
        echo "tools:"
        echo "  required:"
        echo "    - eza"
        echo "    - bat"
        echo "    - fzf"
        echo "    - starship"
        echo "  recommended:"
        echo "    - fd"
        echo "    - ripgrep"
        echo "    - zoxide"
        echo "    - delta"
        echo "    - tldr"

        echo ""
        echo "aliases:"
        echo "  enabled: ${WIZARD_ALIASES_ENABLED:-true}"
        echo "  groups:"
        if [[ -n "${WIZARD_ALIAS_GROUPS:-}" ]]; then
            for group in ${WIZARD_ALIAS_GROUPS}; do
                echo "    - $group"
            done
        fi

        echo ""
        echo "integrations:"
        # FZF integration
        local fzf_enabled="false"
        local mise_enabled="false"
        local tmux_enabled="false"
        local zoxide_enabled="false"
        local delta_enabled="false"

        for integ in ${WIZARD_INTEGRATIONS:-fzf mise}; do
            case "$integ" in
                fzf) fzf_enabled="true" ;;
                mise) mise_enabled="true" ;;
                tmux) tmux_enabled="true" ;;
                zoxide) zoxide_enabled="true" ;;
                delta) delta_enabled="true" ;;
            esac
        done

        echo "  fzf:"
        echo "    enabled: $fzf_enabled"
        echo "  mise:"
        echo "    enabled: $mise_enabled"
        echo "  tmux:"
        echo "    auto_start: false"
        echo "  zoxide:"
        echo "    enabled: $zoxide_enabled"
        echo "  delta:"
        echo "    enabled: $delta_enabled"
    } > "$config_file"

    log_success "Configuration saved: $config_file"
}

# -----------------------------------------------------------------------------
# Main Wizard
# -----------------------------------------------------------------------------

## Run the interactive setup wizard
## Usage: run_wizard
run_wizard() {
    _wizard_step_welcome

    _wizard_step_theme
    _wizard_step_plugins
    _wizard_step_aliases
    _wizard_step_integrations

    if ! _wizard_step_preview; then
        return 0
    fi

    # Generate config
    _wizard_step 6 6 "Generating configuration"
    local config_file="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"
    _wizard_generate_config "$config_file"

    # Ask to apply
    echo ""
    local apply_now
    apply_now=$(_wizard_confirm "Apply configuration now?")

    if [[ "$apply_now" == "true" ]]; then
        export PIMPMYSHELL_CONFIG_FILE="$config_file"
        export PIMPMYSHELL_NO_BACKUP="${PIMPMYSHELL_NO_BACKUP:-false}"

        # Apply theme (starship + eza) - use wizard state directly
        local theme_name="${WIZARD_THEME:-${DEFAULT_THEME}}"
        log_info "Applying theme: $theme_name"
        apply_theme "$theme_name" || log_warn "Could not apply theme completely"

        # Install custom plugins if oh-my-zsh is available
        if [[ -n "${_PIMPMYSHELL_PLUGINS_LOADED:-}" ]] && is_omz_installed; then
            install_plugins || log_warn "Some plugins could not be installed"
        fi

        # Generate .zshrc
        if [[ -n "${_PIMPMYSHELL_CONFIG_LOADED:-}" ]]; then
            log_info "Generating .zshrc..."
            if generate_zshrc "${HOME}/.zshrc"; then
                log_success "Generated: ${HOME}/.zshrc"
            else
                log_warn "Could not generate .zshrc"
            fi
        fi

        echo ""
        log_success "Configuration applied!"
        log_info "Theme: $theme_name"
        log_info "Reload your shell: source ~/.zshrc"
    else
        log_info "Apply later with: pimpmyshell apply"
    fi

    return 0
}

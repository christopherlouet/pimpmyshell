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

if [[ -z "${_PIMPMYSHELL_ZSHRC_GEN_LOADED:-}" ]]; then
    # shellcheck source=./zshrc-gen.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/zshrc-gen.sh"
fi

if [[ -z "${_PIMPMYSHELL_THEMES_LOADED:-}" ]]; then
    # shellcheck source=./themes.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/themes.sh"
fi

if [[ -z "${_PIMPMYSHELL_PROFILES_LOADED:-}" ]]; then
    # shellcheck source=./profiles.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/profiles.sh"
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
WIZARD_TOOLS="${WIZARD_TOOLS:-}"
WIZARD_PROFILE="${WIZARD_PROFILE:-}"

# -----------------------------------------------------------------------------
# Step Registry & Navigation
# -----------------------------------------------------------------------------

_WIZARD_STEPS=(
    "_wizard_step_theme"
    "_wizard_step_plugins"
    "_wizard_step_aliases"
    "_wizard_step_integrations"
    "_wizard_step_tools"
    "_wizard_step_preview"
    "_wizard_step_profile"
)

## Display a visual progress bar
## Usage: _wizard_progress_bar <current> <total> <description>
_wizard_progress_bar() {
    local current="$1"
    local total="$2"
    local description="$3"
    local bar_width=20

    if [[ "$total" -le 0 ]]; then
        echo "[>                   ] Step 0/0 - ${description}"
        return
    fi

    local filled=$(( (current * bar_width) / total ))
    [[ "$filled" -gt "$bar_width" ]] && filled="$bar_width"
    local empty=$(( bar_width - filled ))

    local bar=""
    local j
    for (( j = 0; j < filled; j++ )); do
        bar+="="
    done
    if [[ "$filled" -lt "$bar_width" ]]; then
        bar+=">"
        empty=$(( empty - 1 ))
    fi
    for (( j = 0; j < empty; j++ )); do
        bar+=" "
    done

    echo "[${bar}] Step ${current}/${total} - ${description}"
}

## Navigation prompt between steps
## Usage: _wizard_nav_prompt
## Returns: "next", "back", or "quit"
_wizard_nav_prompt() {
    # Auto mode always goes forward
    if [[ -n "${WIZARD_AUTO:-}" ]]; then
        echo "next"
        return 0
    fi

    if _use_gum; then
        local choice
        choice=$(gum choose --header "Navigation:" "Next" "Back" "Quit")
        case "$choice" in
            Back) echo "back" ;;
            Quit) echo "quit" ;;
            *)    echo "next" ;;
        esac
    else
        echo ""
        echo "[Enter] Next  [b] Back  [q] Quit"
        local nav_input
        read -rp "> " nav_input
        case "${nav_input,,}" in
            b|back) echo "back" ;;
            q|quit) echo "quit" ;;
            *)      echo "next" ;;
        esac
    fi
}

# -----------------------------------------------------------------------------
# Descriptions
# -----------------------------------------------------------------------------

## Get description for a category:name pair
## Usage: _wizard_get_desc <category> <name>
## Returns: description string or empty
_wizard_get_desc() {
    local category="$1"
    local name="$2"

    case "${category}|${name}" in
        # OMZ plugins
        plugin\|git)                      echo "Git aliases and functions (ga, gc, gp, ...)" ;;
        plugin\|fzf)                      echo "Fuzzy finder integration for shell" ;;
        plugin\|tmux)                     echo "Tmux terminal multiplexer aliases" ;;
        plugin\|docker)                   echo "Docker command completions and aliases" ;;
        plugin\|kubectl)                  echo "Kubernetes CLI completions" ;;
        plugin\|extract)                  echo "Extract any archive with one command" ;;
        plugin\|web-search)               echo "Search Google/DuckDuckGo from terminal" ;;
        plugin\|wd)                       echo "Warp directory - bookmark directories" ;;
        plugin\|mise)                     echo "Mise version manager integration" ;;
        plugin\|eza)                      echo "Modern ls replacement completions" ;;
        # Custom plugins
        plugin\|zsh-autosuggestions)      echo "Fish-like autosuggestions as you type" ;;
        plugin\|zsh-syntax-highlighting)  echo "Syntax highlighting for commands" ;;
        plugin\|zsh-bat)                  echo "Cat replacement with syntax highlighting" ;;
        plugin\|zsh-completions)          echo "Additional completion definitions" ;;
        # Alias groups
        alias\|git)                       echo "Git shortcuts: ga, gc, gp, gl, gst, ..." ;;
        alias\|docker)                    echo "Docker shortcuts: dk, dkc, dkps, dklogs, ..." ;;
        alias\|kubernetes)                echo "K8s shortcuts: k, kgp, kgs, kd, ..." ;;
        alias\|navigation)               echo "Navigation: .., ..., mkcd, take, ..." ;;
        alias\|files)                     echo "File shortcuts: ll, la, lt, cat->bat, ..." ;;
        # Integrations
        integ\|fzf)                       echo "Fuzzy finder for files, history, processes" ;;
        integ\|fzf_tab)                   echo "Replace zsh tab completion with fzf" ;;
        integ\|mise)                      echo "Polyglot version manager (node, python, ...)" ;;
        integ\|tmux)                      echo "Auto-start terminal multiplexer" ;;
        integ\|zoxide)                    echo "Smarter cd - learns your most used dirs" ;;
        integ\|delta)                     echo "Better git diffs with syntax highlighting" ;;
        *) echo "" ;;
    esac
}

## Get description for a category:name pair, formatted with name
## Usage: _wizard_with_desc <category> <name>
## Returns: "name - description" or just "name"
_wizard_with_desc() {
    local category="$1"
    local name="$2"
    local desc
    desc=$(_wizard_get_desc "$category" "$name")

    if [[ -n "$desc" ]]; then
        echo "${name} - ${desc}"
    else
        echo "$name"
    fi
}

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

## Single choice selector with retry loop
## Usage: _wizard_choose <prompt> <option1> <option2> ...
## Returns: selected option on stdout
_wizard_choose() {
    local prompt="$1"
    shift
    local options=("$@")

    # Auto mode: return default or first option
    if [[ -n "${WIZARD_AUTO:-}" ]]; then
        if [[ -n "${WIZARD_DEFAULT:-}" ]]; then
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

        local attempt
        for attempt in 1 2 3; do
            local choice
            read -rp "Enter choice (1-${#options[@]}): " choice
            if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#options[@]} ]] 2>/dev/null; then
                echo "${options[$((choice - 1))]}"
                return 0
            fi
            if [[ "$attempt" -lt 3 ]]; then
                echo "Invalid choice. Please enter a number between 1 and ${#options[@]}."
            fi
        done
        # After 3 failed attempts, return first option
        echo "${options[0]}"
    fi
}

## Multiple choice selector with retry loop
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
        local selected_csv
        selected_csv=$(IFS=,; echo "${options[*]}")
        gum choose --no-limit --selected="$selected_csv" --header "$prompt" "${options[@]}"
    else
        echo "$prompt"
        echo "(Enter numbers separated by spaces, 'all', or Enter to keep all)"
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        echo ""

        local attempt
        for attempt in 1 2 3; do
            local choices
            read -rp "Enter choices: " choices

            if [[ "$choices" == "all" || -z "$choices" ]]; then
                printf '%s\n' "${options[@]}"
                return 0
            fi

            local valid_count=0
            local invalid_found=0
            local valid_selections=()
            for num in $choices; do
                if [[ "$num" =~ ^[0-9]+$ && "$num" -ge 1 && "$num" -le ${#options[@]} ]] 2>/dev/null; then
                    valid_selections+=("${options[$((num - 1))]}")
                    ((valid_count++))
                else
                    ((invalid_found++))
                fi
            done

            if [[ "$valid_count" -gt 0 ]]; then
                if [[ "$invalid_found" -gt 0 ]]; then
                    echo "Warning: some invalid entries were skipped." >&2
                fi
                printf '%s\n' "${valid_selections[@]}"
                return 0
            fi

            if [[ "$attempt" -lt 3 ]]; then
                echo "No valid selections. Enter numbers between 1 and ${#options[@]}."
            fi
        done
        # After 3 failed attempts, return all options as default
        printf '%s\n' "${options[@]}"
    fi
}

## Yes/No confirmation with retry loop
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

        local attempt
        for attempt in 1 2 3; do
            local answer
            read -rp "$prompt $yn " answer

            case "${answer,,}" in
                y|yes) echo "true"; return 0 ;;
                n|no)  echo "false"; return 0 ;;
                "")    echo "$default"; return 0 ;;
                *)
                    if [[ "$attempt" -lt 3 ]]; then
                        echo "Please enter y or n."
                    fi
                    ;;
            esac
        done
        # After 3 failed attempts, return default
        echo "$default"
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
# Theme Preview Helpers
# -----------------------------------------------------------------------------

## Render an inline color swatch using ANSI truecolor
## Usage: _wizard_theme_swatch <hex_color>
## Returns: ANSI escape sequence rendering a colored block
_wizard_theme_swatch() {
    local hex="${1:-#000000}"
    hex="${hex#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\033[48;2;%d;%d;%dm  \033[0m' "$r" "$g" "$b"
}

## Build a labeled theme option with color swatches
## Usage: _wizard_theme_label <theme_name>
## Returns: "name  [swatch][swatch][swatch]  description"
_wizard_theme_label() {
    local theme_name="$1"
    local theme_file

    theme_file=$(get_theme_path "$theme_name" 2>/dev/null) || {
        echo "$theme_name"
        return
    }

    local desc
    desc=$(theme_get "$theme_file" ".description" "")
    local accent
    accent=$(theme_get "$theme_file" ".colors.accent" "")
    local accent2
    accent2=$(theme_get "$theme_file" ".colors.accent2" "")
    local bg
    bg=$(theme_get "$theme_file" ".colors.bg" "")

    local swatches=""
    if [[ -n "$accent" && "$accent" != "null" ]]; then
        swatches+=$(_wizard_theme_swatch "$accent")
    fi
    if [[ -n "$accent2" && "$accent2" != "null" ]]; then
        swatches+=$(_wizard_theme_swatch "$accent2")
    fi
    if [[ -n "$bg" && "$bg" != "null" ]]; then
        swatches+=$(_wizard_theme_swatch "$bg")
    fi

    if [[ -n "$swatches" && -n "$desc" ]]; then
        echo "${theme_name}  ${swatches}  ${desc}"
    elif [[ -n "$desc" ]]; then
        echo "${theme_name} - ${desc}"
    else
        echo "$theme_name"
    fi
}

# -----------------------------------------------------------------------------
# Wizard Steps
# -----------------------------------------------------------------------------

## Welcome and prerequisites (outside step loop)
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

## Step: Choose theme (with preview)
_wizard_step_theme() {
    local step_num="${1:-1}"
    local total="${2:-${#_WIZARD_STEPS[@]}}"

    _wizard_progress_bar "$step_num" "$total" "Choose a theme"
    echo ""

    local themes
    themes=$(list_themes 2>/dev/null) || true
    if [[ -z "$themes" ]]; then
        log_warn "No themes found, using default: cyberpunk"
        WIZARD_THEME="cyberpunk"
        return 0
    fi

    local theme_array=()
    local theme_labels=()
    while IFS= read -r theme; do
        [[ -z "$theme" ]] && continue
        theme_array+=("$theme")
        if [[ -z "${WIZARD_AUTO:-}" ]]; then
            theme_labels+=("$(_wizard_theme_label "$theme")")
        else
            theme_labels+=("$theme")
        fi
    done <<< "$themes"

    local selected
    selected=$(WIZARD_DEFAULT="$WIZARD_THEME" _wizard_choose "Select a theme:" "${theme_labels[@]}")

    # Extract theme name from label (first word before space)
    WIZARD_THEME="${selected%% *}"
    log_info "Theme: $WIZARD_THEME"

    # Show theme preview after selection (non-auto mode)
    if [[ -z "${WIZARD_AUTO:-}" ]]; then
        preview_theme "$WIZARD_THEME" 2>/dev/null || true
    fi
}

## Step: Choose plugins (with descriptions)
_wizard_step_plugins() {
    local step_num="${1:-2}"
    local total="${2:-${#_WIZARD_STEPS[@]}}"

    _wizard_progress_bar "$step_num" "$total" "Choose plugins"
    echo ""

    # Standard plugins with descriptions
    local omz_names=("git" "fzf" "tmux" "docker" "kubectl" "extract" "web-search" "wd" "mise" "eza")
    local omz_options=()
    for name in "${omz_names[@]}"; do
        omz_options+=("$(_wizard_with_desc "plugin" "$name")")
    done

    local selected_omz
    selected_omz=$(_wizard_choose_multi "Select Oh-My-Zsh plugins:" "${omz_options[@]}")

    WIZARD_OMZ_PLUGINS=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local plugin="${line%% -*}"
        plugin="${plugin%% }"
        if [[ -n "$WIZARD_OMZ_PLUGINS" ]]; then
            WIZARD_OMZ_PLUGINS="${WIZARD_OMZ_PLUGINS} ${plugin}"
        else
            WIZARD_OMZ_PLUGINS="$plugin"
        fi
    done <<< "$selected_omz"

    # Custom plugins with descriptions
    local custom_names=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-bat" "zsh-completions")
    local custom_options=()
    for name in "${custom_names[@]}"; do
        custom_options+=("$(_wizard_with_desc "plugin" "$name")")
    done

    local selected_custom
    selected_custom=$(_wizard_choose_multi "Select custom plugins:" "${custom_options[@]}")

    WIZARD_CUSTOM_PLUGINS=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local plugin="${line%% -*}"
        plugin="${plugin%% }"
        if [[ -n "$WIZARD_CUSTOM_PLUGINS" ]]; then
            WIZARD_CUSTOM_PLUGINS="${WIZARD_CUSTOM_PLUGINS} ${plugin}"
        else
            WIZARD_CUSTOM_PLUGINS="$plugin"
        fi
    done <<< "$selected_custom"

    log_info "Standard plugins: $WIZARD_OMZ_PLUGINS"
    log_info "Custom plugins: $WIZARD_CUSTOM_PLUGINS"
}

## Step: Choose alias groups (with descriptions)
_wizard_step_aliases() {
    local step_num="${1:-3}"
    local total="${2:-${#_WIZARD_STEPS[@]}}"

    _wizard_progress_bar "$step_num" "$total" "Choose alias groups"
    echo ""

    local alias_names=("git" "docker" "kubernetes" "navigation" "files")
    local alias_options=()
    for name in "${alias_names[@]}"; do
        alias_options+=("$(_wizard_with_desc "alias" "$name")")
    done

    local selected
    selected=$(_wizard_choose_multi "Select alias groups:" "${alias_options[@]}")

    WIZARD_ALIAS_GROUPS=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local group="${line%% -*}"
        group="${group%% }"
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

## Step: Choose integrations (with descriptions, includes fzf_tab)
_wizard_step_integrations() {
    local step_num="${1:-4}"
    local total="${2:-${#_WIZARD_STEPS[@]}}"

    _wizard_progress_bar "$step_num" "$total" "Choose integrations"
    echo ""

    local integ_names=("fzf" "fzf_tab" "mise" "tmux" "zoxide" "delta")
    local integ_options=()
    for name in "${integ_names[@]}"; do
        integ_options+=("$(_wizard_with_desc "integ" "$name")")
    done

    local selected
    selected=$(_wizard_choose_multi "Select integrations:" "${integ_options[@]}")

    WIZARD_INTEGRATIONS=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local integ="${line%% -*}"
        integ="${integ%% }"
        if [[ -n "$WIZARD_INTEGRATIONS" ]]; then
            WIZARD_INTEGRATIONS="${WIZARD_INTEGRATIONS} ${integ}"
        else
            WIZARD_INTEGRATIONS="$integ"
        fi
    done <<< "$selected"

    log_info "Integrations: ${WIZARD_INTEGRATIONS:-none}"
}

## Step: Tool selection
_wizard_step_tools() {
    local step_num="${1:-5}"
    local total="${2:-${#_WIZARD_STEPS[@]}}"

    _wizard_progress_bar "$step_num" "$total" "Select tools"
    echo ""

    local required_tools=("eza" "bat" "fzf" "starship")
    local recommended_tools=("fd" "ripgrep" "zoxide" "delta" "tldr" "dust" "hyperfine")

    echo "Required tools (always included):"
    for tool in "${required_tools[@]}"; do
        local marker
        if is_tool_installed "$tool" 2>/dev/null; then
            marker="✓"
        else
            marker="✗"
        fi
        echo "  [${marker}] $tool"
    done
    echo ""

    # Build selectable list with installed status
    local tool_options=()
    for tool in "${recommended_tools[@]}"; do
        local marker
        if is_tool_installed "$tool" 2>/dev/null; then
            marker="✓"
        else
            marker="✗"
        fi
        tool_options+=("[${marker}] $tool")
    done

    local selected
    selected=$(_wizard_choose_multi "Select recommended tools to include:" "${tool_options[@]}")

    # Always start with required tools
    WIZARD_TOOLS=""
    for tool in "${required_tools[@]}"; do
        if [[ -n "$WIZARD_TOOLS" ]]; then
            WIZARD_TOOLS="${WIZARD_TOOLS} ${tool}"
        else
            WIZARD_TOOLS="$tool"
        fi
    done

    # Add selected recommended tools
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        # Strip the [✓] or [✗] prefix
        local tool="${line#\[??\] }"
        # Handle both UTF-8 markers
        tool="${tool#\[✓\] }"
        tool="${tool#\[✗\] }"
        if [[ -n "$tool" && -n "$WIZARD_TOOLS" ]]; then
            WIZARD_TOOLS="${WIZARD_TOOLS} ${tool}"
        elif [[ -n "$tool" ]]; then
            WIZARD_TOOLS="$tool"
        fi
    done <<< "$selected"

    log_info "Tools: $WIZARD_TOOLS"
}

## Step: Preview and confirm
_wizard_step_preview() {
    local step_num="${1:-6}"
    local total="${2:-${#_WIZARD_STEPS[@]}}"

    _wizard_progress_bar "$step_num" "$total" "Preview configuration"
    echo ""

    echo "Configuration summary:"
    echo ""
    echo "  Theme:           $WIZARD_THEME"
    echo "  Framework:       $WIZARD_FRAMEWORK"
    echo "  Prompt engine:   $WIZARD_PROMPT_ENGINE"
    echo "  OMZ plugins:     $WIZARD_OMZ_PLUGINS"
    echo "  Custom plugins:  $WIZARD_CUSTOM_PLUGINS"
    echo "  Alias groups:    $WIZARD_ALIAS_GROUPS"
    echo "  Integrations:    ${WIZARD_INTEGRATIONS:-none}"
    echo "  Tools:           ${WIZARD_TOOLS:-default}"
    echo ""

    local confirmed
    confirmed=$(_wizard_confirm "Generate configuration with these settings?")

    if [[ "$confirmed" != "true" ]]; then
        log_info "Wizard cancelled."
        return 1
    fi

    return 0
}

## Step: Save as named profile (optional)
_wizard_step_profile() {
    local step_num="${1:-7}"
    local total="${2:-${#_WIZARD_STEPS[@]}}"

    _wizard_progress_bar "$step_num" "$total" "Save as profile"
    echo ""

    local save_profile
    save_profile=$(_wizard_confirm "Save configuration as a named profile?" "false")

    if [[ "$save_profile" != "true" ]]; then
        WIZARD_PROFILE=""
        return 0
    fi

    local profile_name
    profile_name=$(_wizard_input "Profile name:" "" "my-setup")

    if [[ -z "$profile_name" ]]; then
        log_info "No profile name given, skipping."
        WIZARD_PROFILE=""
        return 0
    fi

    if ! is_valid_profile_name "$profile_name"; then
        log_warn "Invalid profile name: '${profile_name}' (use alphanumeric, dash, underscore)"
        WIZARD_PROFILE=""
        return 0
    fi

    WIZARD_PROFILE="$profile_name"
    log_info "Will save as profile: $WIZARD_PROFILE"
}

# -----------------------------------------------------------------------------
# Config Generation
# -----------------------------------------------------------------------------

## Generate pimpmyshell.yaml from wizard state
## Usage: _wizard_generate_config [config_file]
_wizard_generate_config() {
    local config_file="${1:-${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml}"

    mkdir -p "$(dirname "$config_file")"

    # Determine recommended tools from WIZARD_TOOLS (exclude required)
    local required_set=" eza bat fzf starship "
    local recommended_list=""
    for tool in ${WIZARD_TOOLS:-fd ripgrep zoxide delta tldr}; do
        if [[ "$required_set" != *" $tool "* ]]; then
            recommended_list="${recommended_list:+$recommended_list }$tool"
        fi
    done

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
        if [[ -n "$recommended_list" ]]; then
            for tool in $recommended_list; do
                echo "    - $tool"
            done
        else
            echo "    - fd"
            echo "    - ripgrep"
            echo "    - zoxide"
            echo "    - delta"
            echo "    - tldr"
        fi

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
        local fzf_enabled="false"
        local fzf_tab_enabled="false"
        local mise_enabled="false"
        local tmux_enabled="false"
        local zoxide_enabled="false"
        local delta_enabled="false"

        for integ in ${WIZARD_INTEGRATIONS:-fzf mise}; do
            case "$integ" in
                fzf) fzf_enabled="true" ;;
                fzf_tab) fzf_tab_enabled="true" ;;
                mise) mise_enabled="true" ;;
                tmux) tmux_enabled="true" ;;
                zoxide) zoxide_enabled="true" ;;
                delta) delta_enabled="true" ;;
            esac
        done

        echo "  fzf:"
        echo "    enabled: $fzf_enabled"
        echo "  fzf_tab:"
        echo "    enabled: $fzf_tab_enabled"
        echo "  mise:"
        echo "    enabled: $mise_enabled"
        echo "  tmux:"
        echo "    auto_start: $tmux_enabled"
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

    local total=${#_WIZARD_STEPS[@]}
    local step_idx=0

    while [[ "$step_idx" -ge 0 && "$step_idx" -lt "$total" ]]; do
        local step_fn="${_WIZARD_STEPS[$step_idx]}"
        local step_num=$((step_idx + 1))

        # Call the step function with step_num and total
        if ! "$step_fn" "$step_num" "$total"; then
            # Step returned failure (e.g. preview cancelled)
            # Go back if possible, otherwise exit
            if [[ "$step_idx" -gt 0 ]]; then
                step_idx=$((step_idx - 1))
                continue
            else
                return 0
            fi
        fi

        # Navigation between steps (skip for last step)
        if [[ "$step_idx" -lt $((total - 1)) ]]; then
            local nav
            nav=$(_wizard_nav_prompt)
            case "$nav" in
                back)
                    if [[ "$step_idx" -gt 0 ]]; then
                        step_idx=$((step_idx - 1))
                    fi
                    continue
                    ;;
                quit)
                    log_info "Wizard cancelled."
                    return 0
                    ;;
                *)
                    step_idx=$((step_idx + 1))
                    ;;
            esac
        else
            step_idx=$((step_idx + 1))
        fi
    done

    # Generate config
    echo ""
    log_info "Generating configuration..."
    local config_file="${PIMPMYSHELL_CONFIG_DIR}/pimpmyshell.yaml"

    # If profile was set, save to profile path
    if [[ -n "${WIZARD_PROFILE:-}" ]]; then
        init_profiles 2>/dev/null || true
        if ! profile_exists "$WIZARD_PROFILE" 2>/dev/null; then
            create_profile "$WIZARD_PROFILE" 2>/dev/null || true
        fi
        local profile_config
        profile_config=$(get_profile_config_path "$WIZARD_PROFILE" 2>/dev/null)
        if [[ -n "$profile_config" ]]; then
            config_file="$profile_config"
        fi
    fi

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

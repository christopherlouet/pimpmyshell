#!/usr/bin/env bash
# pimpmyshell - Theme management
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_THEMES_LOADED:-}" ]] && return 0
_PIMPMYSHELL_THEMES_LOADED=1

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

# Ensure core is loaded
if [[ -z "${_PIMPMYSHELL_CORE_LOADED:-}" ]]; then
    # shellcheck source=./core.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
fi

# Ensure config is loaded (for yq_get)
if [[ -z "${_PIMPMYSHELL_CONFIG_LOADED:-}" ]]; then
    # shellcheck source=./config.sh
    source "${PIMPMYSHELL_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/config.sh"
fi

# -----------------------------------------------------------------------------
# Theme directory
# -----------------------------------------------------------------------------

PIMPMYSHELL_THEMES_DIR="${PIMPMYSHELL_THEMES_DIR:-${PIMPMYSHELL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/themes}"

# -----------------------------------------------------------------------------
# Theme functions
# -----------------------------------------------------------------------------

## List all available themes
## Usage: list_themes
list_themes() {
    local themes_dir="${PIMPMYSHELL_THEMES_DIR}"

    if [[ ! -d "$themes_dir" ]]; then
        log_error "Themes directory not found: $themes_dir"
        return 1
    fi

    for theme_file in "$themes_dir"/*.yaml; do
        if [[ -f "$theme_file" ]]; then
            basename "$theme_file" .yaml
        fi
    done
}

## Get theme file path
## Usage: get_theme_path <theme_name>
get_theme_path() {
    _require_args "get_theme_path" 1 $# || return 1
    local theme_name="$1"
    local theme_file="${PIMPMYSHELL_THEMES_DIR}/${theme_name}.yaml"

    if [[ -f "$theme_file" ]]; then
        echo "$theme_file"
        return 0
    fi

    # Check if it's a full path
    if [[ -f "$theme_name" ]]; then
        echo "$theme_name"
        return 0
    fi

    return 1
}

## Get a value from theme YAML
## Usage: theme_get <theme_file> <path> [default]
theme_get() {
    _require_args "theme_get" 2 $# || return 1
    local theme_file="$1"
    local path="$2"
    local default="${3:-}"

    if [[ ! -f "$theme_file" ]]; then
        echo "$default"
        return
    fi

    local value
    value=$(yq_get "$theme_file" "$path")

    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

## Get terminal palette from theme YAML as dconf-formatted string
## Usage: theme_get_palette <theme_file>
## Returns: "['#hex0', '#hex1', ..., '#hex15']" or empty string
theme_get_palette() {
    _require_args "theme_get_palette" 1 $# || return 1
    local theme_file="$1"

    if [[ ! -f "$theme_file" ]]; then
        echo ""
        return
    fi

    require_yq || return 1

    local colors=""
    local color
    for i in $(seq 0 15); do
        color=$(yq_eval "$theme_file" ".terminal.palette[$i]")

        if [[ -z "$color" || "$color" == "null" ]]; then
            echo ""
            return
        fi

        # Expand to full #RRRRGGGGBBBB format for dconf
        local r="${color:1:2}"
        local g="${color:3:2}"
        local b="${color:5:2}"
        local expanded="#${r}${r}${g}${g}${b}${b}"

        if [[ -n "$colors" ]]; then
            colors="${colors}, '${expanded}'"
        else
            colors="'${expanded}'"
        fi
    done

    echo "[${colors}]"
}

## Load a theme and export its colors as variables
## Usage: load_theme <theme_name>
## Sets: THEME_* variables
load_theme() {
    _require_args "load_theme" 1 $# || return 1
    local theme_name="$1"
    local theme_file

    theme_file=$(get_theme_path "$theme_name") || {
        log_error "Theme not found: $theme_name"
        return 1
    }

    log_debug "Loading theme: $theme_name from $theme_file"

    # Export theme metadata
    export THEME_NAME THEME_DESCRIPTION
    THEME_NAME=$(theme_get "$theme_file" ".name" "$theme_name")
    THEME_DESCRIPTION=$(theme_get "$theme_file" ".description" "")

    # Export colors
    export THEME_BG THEME_FG THEME_ACCENT THEME_ACCENT2
    export THEME_WARNING THEME_ERROR THEME_SUCCESS
    export THEME_COMMENT THEME_SELECTION THEME_BORDER

    THEME_BG=$(theme_get "$theme_file" ".colors.bg" "#1a1a2e")
    THEME_FG=$(theme_get "$theme_file" ".colors.fg" "#e0e0e0")
    THEME_ACCENT=$(theme_get "$theme_file" ".colors.accent" "#00d9ff")
    THEME_ACCENT2=$(theme_get "$theme_file" ".colors.accent2" "#ff00ff")
    THEME_WARNING=$(theme_get "$theme_file" ".colors.warning" "#ffcc00")
    THEME_ERROR=$(theme_get "$theme_file" ".colors.error" "#ff3333")
    THEME_SUCCESS=$(theme_get "$theme_file" ".colors.success" "#00ff88")
    THEME_COMMENT=$(theme_get "$theme_file" ".colors.comment" "#666666")
    THEME_SELECTION=$(theme_get "$theme_file" ".colors.selection" "#333355")
    THEME_BORDER=$(theme_get "$theme_file" ".colors.border" "#444466")

    # Export separators
    export THEME_SEP_LEFT THEME_SEP_RIGHT THEME_SEP_LEFT_ALT THEME_SEP_RIGHT_ALT
    THEME_SEP_LEFT=$(theme_get "$theme_file" ".separators.left" "")
    THEME_SEP_RIGHT=$(theme_get "$theme_file" ".separators.right" "")
    THEME_SEP_LEFT_ALT=$(theme_get "$theme_file" ".separators.left_alt" "")
    THEME_SEP_RIGHT_ALT=$(theme_get "$theme_file" ".separators.right_alt" "")

    # Export icons
    export THEME_ICON_SESSION THEME_ICON_WINDOW THEME_ICON_PANE
    export THEME_ICON_GIT THEME_ICON_TIME THEME_ICON_CPU THEME_ICON_MEMORY

    THEME_ICON_SESSION=$(theme_get "$theme_file" ".icons.session" "")
    THEME_ICON_WINDOW=$(theme_get "$theme_file" ".icons.window" "")
    THEME_ICON_PANE=$(theme_get "$theme_file" ".icons.pane" "")
    THEME_ICON_GIT=$(theme_get "$theme_file" ".icons.git" "")
    THEME_ICON_TIME=$(theme_get "$theme_file" ".icons.time" "")
    THEME_ICON_CPU=$(theme_get "$theme_file" ".icons.cpu" "")
    THEME_ICON_MEMORY=$(theme_get "$theme_file" ".icons.memory" "")

    # Export terminal palette (16 ANSI colors for GNOME Terminal)
    export THEME_PALETTE
    THEME_PALETTE=$(theme_get_palette "$theme_file")

    log_verbose "Loaded theme: $THEME_NAME"
    return 0
}

# -----------------------------------------------------------------------------
# Terminal Detection
# -----------------------------------------------------------------------------

## Detect the current terminal emulator
## Returns: gnome-terminal, konsole, xfce4-terminal, kitty, alacritty, wezterm, or unknown
detect_terminal() {
    # Check TERM first (most reliable for some terminals)
    case "${TERM:-}" in
        xterm-kitty)    echo "kitty"; return ;;
        alacritty)      echo "alacritty"; return ;;
    esac

    # Check TERM_PROGRAM (set by many modern terminals)
    case "${TERM_PROGRAM:-}" in
        kitty)          echo "kitty"; return ;;
        alacritty)      echo "alacritty"; return ;;
        WezTerm)        echo "wezterm"; return ;;
    esac

    # Check terminal-specific environment variables
    if [[ -n "${KONSOLE_VERSION:-}" ]]; then
        echo "konsole"
        return
    fi

    if [[ -n "${XFCE_TERMINAL_VERSION:-}" ]]; then
        echo "xfce4-terminal"
        return
    fi

    # Check for GNOME Terminal via dconf
    if check_command dconf && dconf list /org/gnome/terminal/legacy/profiles:/ &>/dev/null 2>&1; then
        echo "gnome-terminal"
        return
    fi

    echo "unknown"
}

# -----------------------------------------------------------------------------
# Theme Generation (config file content)
# -----------------------------------------------------------------------------

## Generate kitty theme config content
## Requires: THEME_FG, THEME_BG, THEME_PALETTE to be set
## Usage: _generate_kitty_theme
_generate_kitty_theme() {
    echo "# pimpmyshell theme: ${THEME_NAME:-unknown}"
    echo "foreground ${THEME_FG}"
    echo "background ${THEME_BG}"
    echo "selection_foreground ${THEME_FG}"
    echo "selection_background ${THEME_SELECTION:-#333355}"

    # Parse palette if available
    if [[ -n "${THEME_PALETTE:-}" ]]; then
        local cleaned i=0
        cleaned=$(echo "$THEME_PALETTE" | tr -d "[]'" | tr ',' '\n')
        while IFS= read -r color; do
            color=$(echo "$color" | tr -d ' ')
            [[ -z "$color" ]] && continue
            # Convert #RRRRGGGGBBBB to #RRGGBB
            if [[ ${#color} -eq 13 ]]; then
                color="#${color:1:2}${color:5:2}${color:9:2}"
            fi
            echo "color${i} ${color}"
            ((i++))
            [[ $i -ge 16 ]] && break
        done <<< "$cleaned"
    fi
}

## Generate alacritty theme config content (TOML format)
## Requires: THEME_FG, THEME_BG, THEME_PALETTE to be set
## Usage: _generate_alacritty_theme
_generate_alacritty_theme() {
    echo "# pimpmyshell theme: ${THEME_NAME:-unknown}"
    echo ""
    echo "[colors.primary]"
    echo "foreground = \"${THEME_FG}\""
    echo "background = \"${THEME_BG}\""

    # Parse palette for normal and bright colors
    if [[ -n "${THEME_PALETTE:-}" ]]; then
        local cleaned colors=()
        cleaned=$(echo "$THEME_PALETTE" | tr -d "[]'" | tr ',' '\n')
        while IFS= read -r color; do
            color=$(echo "$color" | tr -d ' ')
            [[ -z "$color" ]] && continue
            if [[ ${#color} -eq 13 ]]; then
                color="#${color:1:2}${color:5:2}${color:9:2}"
            fi
            colors+=("$color")
        done <<< "$cleaned"

        if [[ ${#colors[@]} -ge 8 ]]; then
            echo ""
            echo "[colors.normal]"
            echo "black   = \"${colors[0]}\""
            echo "red     = \"${colors[1]}\""
            echo "green   = \"${colors[2]}\""
            echo "yellow  = \"${colors[3]}\""
            echo "blue    = \"${colors[4]}\""
            echo "magenta = \"${colors[5]}\""
            echo "cyan    = \"${colors[6]}\""
            echo "white   = \"${colors[7]}\""
        fi

        if [[ ${#colors[@]} -ge 16 ]]; then
            echo ""
            echo "[colors.bright]"
            echo "black   = \"${colors[8]}\""
            echo "red     = \"${colors[9]}\""
            echo "green   = \"${colors[10]}\""
            echo "yellow  = \"${colors[11]}\""
            echo "blue    = \"${colors[12]}\""
            echo "magenta = \"${colors[13]}\""
            echo "cyan    = \"${colors[14]}\""
            echo "white   = \"${colors[15]}\""
        fi
    fi
}

## Convert hex color #RRGGBB to R,G,B decimal values
## Usage: _hex_to_rgb <hex_color>
_hex_to_rgb() {
    local hex="${1#\#}"
    # Handle #RRRRGGGGBBBB (dconf format)
    if [[ ${#hex} -eq 12 ]]; then
        hex="${hex:0:2}${hex:4:2}${hex:8:2}"
    fi
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "${r},${g},${b}"
}

## Generate KDE Konsole colorscheme content
## Requires: THEME_FG, THEME_BG, THEME_PALETTE to be set
## Usage: _generate_konsole_theme
_generate_konsole_theme() {
    echo "[General]"
    echo "Description=${THEME_NAME:-pimpmyshell}"
    echo "Opacity=1"
    echo ""
    echo "[Foreground]"
    echo "Color=$(_hex_to_rgb "$THEME_FG")"
    echo ""
    echo "[Background]"
    echo "Color=$(_hex_to_rgb "$THEME_BG")"

    # Parse palette for color slots
    if [[ -n "${THEME_PALETTE:-}" ]]; then
        local cleaned colors=()
        cleaned=$(echo "$THEME_PALETTE" | tr -d "[]'" | tr ',' '\n')
        while IFS= read -r color; do
            color=$(echo "$color" | tr -d ' ')
            [[ -z "$color" ]] && continue
            colors+=("$color")
        done <<< "$cleaned"

        local i
        for i in "${!colors[@]}"; do
            [[ $i -ge 16 ]] && break
            local rgb
            rgb=$(_hex_to_rgb "${colors[$i]}")
            echo ""
            echo "[Color${i}]"
            echo "Color=${rgb}"
        done
    fi
}

# -----------------------------------------------------------------------------
# Theme Application (write config files)
# -----------------------------------------------------------------------------

## Apply kitty theme by writing config file
## Usage: _apply_kitty_theme
_apply_kitty_theme() {
    local kitty_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
    local theme_file="${kitty_dir}/current-theme.conf"

    mkdir -p "$kitty_dir"
    _generate_kitty_theme > "$theme_file"
    log_verbose "Wrote kitty theme: $theme_file"

    # Apply immediately if kitty remote control is available
    if check_command kitty && [[ -n "${KITTY_PID:-}" ]]; then
        kitty @ set-colors --all "$theme_file" 2>/dev/null || true
        log_verbose "Applied kitty colors via remote control"
    fi
}

## Apply alacritty theme by writing config file
## Usage: _apply_alacritty_theme
_apply_alacritty_theme() {
    local alacritty_dir="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
    local theme_file="${alacritty_dir}/pimpmyshell-theme.toml"

    mkdir -p "$alacritty_dir"
    _generate_alacritty_theme > "$theme_file"
    log_verbose "Wrote alacritty theme: $theme_file"

    # Check if main config imports the theme file
    local main_config="${alacritty_dir}/alacritty.toml"
    if [[ -f "$main_config" ]]; then
        if ! grep -q "pimpmyshell-theme.toml" "$main_config" 2>/dev/null; then
            log_info "Add to ${main_config}:"
            log_info '  [general]'
            log_info '  import = ["~/.config/alacritty/pimpmyshell-theme.toml"]'
        fi
    fi
}

## Apply KDE Konsole theme by writing colorscheme file
## Usage: _apply_konsole_theme
_apply_konsole_theme() {
    local konsole_dir="${XDG_DATA_HOME:-$HOME/.local/share}/konsole"
    local scheme_file="${konsole_dir}/${THEME_NAME:-pimpmyshell}.colorscheme"

    mkdir -p "$konsole_dir"
    _generate_konsole_theme > "$scheme_file"
    log_verbose "Wrote Konsole colorscheme: $scheme_file"
}

## Apply XFCE Terminal theme via xfconf-query
## Usage: _apply_xfce_terminal_theme
_apply_xfce_terminal_theme() {
    if ! check_command xfconf-query; then
        log_warn "xfconf-query not available, cannot apply XFCE Terminal theme"
        return 1
    fi

    local channel="xfce4-terminal"
    xfconf-query -c "$channel" -p /color-foreground -s "$THEME_FG" 2>/dev/null || true
    xfconf-query -c "$channel" -p /color-background -s "$THEME_BG" 2>/dev/null || true
    log_verbose "Applied XFCE Terminal colors"
}

# -----------------------------------------------------------------------------
# Theme application functions
# -----------------------------------------------------------------------------

## Find a GNOME Terminal profile UUID by visible name
## Usage: _gnome_find_profile <name>
## Returns: UUID or empty string
_gnome_find_profile() {
    local target_name="$1"
    local uuid name

    for uuid in $(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | grep -oP '[a-f0-9-]{36}'); do
        name=$(dconf read "/org/gnome/terminal/legacy/profiles:/:${uuid}/visible-name" 2>/dev/null | tr -d "'")
        if [[ "$name" == "$target_name" ]]; then
            echo "$uuid"
            return 0
        fi
    done
    return 1
}

## Send OSC 4 escape sequences to reprogram the 16 ANSI palette colors
## Usage: _apply_osc_palette <dconf_palette_string>
## Input format: "['#RRRRGGGGBBBB', '#RRRRGGGGBBBB', ...]"
_apply_osc_palette() {
    local palette_str="$1"

    # Strip brackets and quotes, split by comma
    local cleaned
    cleaned=$(echo "$palette_str" | tr -d "[]'" | tr ',' '\n')

    local i=0
    while IFS= read -r color; do
        color=$(echo "$color" | tr -d ' ')
        [[ -z "$color" ]] && continue
        # Convert #RRRRGGGGBBBB to #RRGGBB (take first 2 hex digits of each channel)
        if [[ ${#color} -eq 13 ]]; then
            color="#${color:1:2}${color:5:2}${color:9:2}"
        fi
        # OSC 4;index;color ST
        printf '\033]4;%d;%s\033\\' "$i" "$color"
        ((i++))
        [[ $i -ge 16 ]] && break
    done <<< "$cleaned"
}

## Apply terminal foreground and background colors
## Uses OSC escape codes for immediate effect + terminal-specific config for persistence
## Usage: apply_terminal_colors
## Requires: THEME_BG, THEME_FG, THEME_NAME, THEME_PALETTE to be set (via load_theme)
apply_terminal_colors() {
    local profile_id=""
    local terminal
    terminal=$(detect_terminal)

    # 0. Terminal-specific persistent config
    case "$terminal" in
        kitty)
            _apply_kitty_theme
            ;;
        alacritty)
            _apply_alacritty_theme
            ;;
        konsole)
            _apply_konsole_theme
            ;;
        xfce4-terminal)
            _apply_xfce_terminal_theme
            ;;
    esac

    # 1. Tmux: set pane fg/bg for immediate effect
    if [[ -n "${TMUX:-}" ]] && check_command tmux; then
        tmux set -g window-style "fg=${THEME_FG},bg=${THEME_BG}"
        tmux set -g window-active-style "fg=${THEME_FG},bg=${THEME_BG}"
        log_verbose "Applied tmux pane colors: fg=$THEME_FG bg=$THEME_BG"
    fi

    # 2. OSC escape codes: immediate fg/bg/palette change in current terminal
    if (echo -n > /dev/tty) 2>/dev/null; then
        {
            printf '\033]10;%s\033\\' "$THEME_FG"
            printf '\033]11;%s\033\\' "$THEME_BG"
            # Apply ANSI palette colors (OSC 4) if available
            if [[ -n "${THEME_PALETTE:-}" ]]; then
                _apply_osc_palette "$THEME_PALETTE"
            fi
        } > /dev/tty
        log_verbose "Applied OSC terminal colors: fg=$THEME_FG bg=$THEME_BG"
    fi

    # 3. GNOME Terminal: update profile via dconf for persistence (new windows/tabs)
    if check_command dconf && dconf list /org/gnome/terminal/legacy/profiles:/ &>/dev/null; then
        profile_id=$(_gnome_find_profile "$THEME_NAME")

        if [[ -n "$profile_id" ]]; then
            local profile_path="/org/gnome/terminal/legacy/profiles:/:${profile_id}"
            dconf write "${profile_path}/foreground-color" "'${THEME_FG}'"
            dconf write "${profile_path}/background-color" "'${THEME_BG}'"
            dconf write "${profile_path}/use-theme-colors" "false"
            dconf write "${profile_path}/bold-is-bright" "true"
            if [[ -n "${THEME_PALETTE:-}" ]]; then
                dconf write "${profile_path}/palette" "${THEME_PALETTE}"
            fi
            dconf write /org/gnome/terminal/legacy/profiles:/default "'${profile_id}'"
            log_verbose "Switched GNOME Terminal to profile: $THEME_NAME ($profile_id)"
        else
            profile_id=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")
            if [[ -n "$profile_id" ]]; then
                local profile_path="/org/gnome/terminal/legacy/profiles:/:${profile_id}"
                dconf write "${profile_path}/foreground-color" "'${THEME_FG}'"
                dconf write "${profile_path}/background-color" "'${THEME_BG}'"
                dconf write "${profile_path}/use-theme-colors" "false"
                dconf write "${profile_path}/bold-is-bright" "true"
                dconf write "${profile_path}/visible-name" "'${THEME_NAME}'"
                if [[ -n "${THEME_PALETTE:-}" ]]; then
                    dconf write "${profile_path}/palette" "${THEME_PALETTE}"
                fi
                log_verbose "Updated default GNOME Terminal profile for: $THEME_NAME"
            fi
        fi
    fi

    # Generate a shell script for startup so colors persist across new shells
    local colors_dir="${PIMPMYSHELL_DATA_DIR}/colors"
    local colors_file="${colors_dir}/terminal-colors.sh"

    mkdir -p "$colors_dir"

    cat > "$colors_file" <<COLORS
# Terminal colors generated by pimpmyshell
# Theme: ${THEME_NAME}
# Applied: $(date '+%Y-%m-%d %H:%M:%S')
COLORS

    # Tmux pane colors
    cat >> "$colors_file" <<'COLORS'
if [[ -n "${TMUX:-}" ]] && command -v tmux &>/dev/null; then
COLORS
    cat >> "$colors_file" <<COLORS
    tmux set -g window-style "fg=${THEME_FG},bg=${THEME_BG}" 2>/dev/null
    tmux set -g window-active-style "fg=${THEME_FG},bg=${THEME_BG}" 2>/dev/null
fi
COLORS

    # OSC escape codes for immediate fg/bg/palette in current terminal
    cat >> "$colors_file" <<COLORS
if [[ -w /dev/tty ]]; then
    printf '\\033]10;${THEME_FG}\\033\\\\' > /dev/tty 2>/dev/null
    printf '\\033]11;${THEME_BG}\\033\\\\' > /dev/tty 2>/dev/null
COLORS

    # Add OSC 4 palette sequences if palette is available
    if [[ -n "${THEME_PALETTE:-}" ]]; then
        local cleaned i=0
        cleaned=$(echo "$THEME_PALETTE" | tr -d "[]'" | tr ',' '\n')
        while IFS= read -r color; do
            color=$(echo "$color" | tr -d ' ')
            [[ -z "$color" ]] && continue
            # Convert #RRRRGGGGBBBB to #RRGGBB
            if [[ ${#color} -eq 13 ]]; then
                color="#${color:1:2}${color:5:2}${color:9:2}"
            fi
            cat >> "$colors_file" <<COLORS
    printf '\\033]4;${i};${color}\\033\\\\' > /dev/tty 2>/dev/null
COLORS
            ((i++))
            [[ $i -ge 16 ]] && break
        done <<< "$cleaned"
    fi

    cat >> "$colors_file" <<'COLORS'
fi
COLORS

    log_verbose "Applied terminal colors: fg=$THEME_FG bg=$THEME_BG"
    return 0
}

## Apply Starship prompt theme
## Usage: apply_starship_theme <theme_name>
apply_starship_theme() {
    _require_args "apply_starship_theme" 1 $# || return 1
    local theme_name="$1"
    local data_dir="${PIMPMYSHELL_THEMES_DIR}/data"
    local source_toml="${data_dir}/${theme_name}.toml"
    local starship_config="${STARSHIP_CONFIG:-${HOME}/.config/starship.toml}"

    if [[ ! -f "$source_toml" ]]; then
        log_error "Starship theme not found: $source_toml"
        return 1
    fi

    # Backup existing config
    if [[ -f "$starship_config" ]]; then
        backup_file "$starship_config"
    fi

    # Ensure directory exists
    mkdir -p "$(dirname "$starship_config")"

    # Copy theme
    cp "$source_toml" "$starship_config"
    log_verbose "Applied Starship theme: $theme_name -> $starship_config"
    return 0
}

## Apply eza color theme
## Usage: apply_eza_theme <theme_name>
apply_eza_theme() {
    _require_args "apply_eza_theme" 1 $# || return 1
    local theme_name="$1"
    local data_dir="${PIMPMYSHELL_THEMES_DIR}/data"
    local source_sh="${data_dir}/eza-${theme_name}.sh"
    local eza_dir="${PIMPMYSHELL_DATA_DIR}/eza"
    local target_sh="${eza_dir}/eza-theme.sh"

    if [[ ! -f "$source_sh" ]]; then
        log_error "Eza theme not found: $source_sh"
        return 1
    fi

    # Ensure directory exists
    mkdir -p "$eza_dir"

    # Copy theme
    cp "$source_sh" "$target_sh"
    log_verbose "Applied eza theme: $theme_name -> $target_sh"
    return 0
}

## Apply theme to all components (orchestration)
## Usage: apply_theme <theme_name>
apply_theme() {
    _require_args "apply_theme" 1 $# || return 1
    local theme_name="$1"

    # Verify theme exists
    get_theme_path "$theme_name" >/dev/null || {
        log_error "Theme not found: $theme_name"
        return 1
    }

    log_verbose "Applying theme: $theme_name"

    # Load theme variables
    load_theme "$theme_name" || return 1

    # Apply Starship theme
    apply_starship_theme "$theme_name" || log_warn "Could not apply Starship theme"

    # Apply eza theme
    apply_eza_theme "$theme_name" || log_warn "Could not apply eza theme"

    # Apply terminal colors (foreground + background)
    apply_terminal_colors || log_warn "Could not apply terminal colors"

    # Persist theme choice in config
    set_config '.theme' "$theme_name" || log_warn "Could not persist theme in config"

    log_verbose "Theme applied: $theme_name"
    return 0
}

## Preview theme colors in terminal
## Usage: preview_theme <theme_name>
preview_theme() {
    _require_args "preview_theme" 1 $# || return 1
    local theme_name="$1"

    load_theme "$theme_name" || return 1

    echo ""
    echo -e "${BOLD}Theme: ${THEME_NAME}${RESET}"
    echo -e "${DIM}${THEME_DESCRIPTION}${RESET}"
    echo ""

    # Show color swatches
    local colors=("bg:$THEME_BG" "fg:$THEME_FG" "accent:$THEME_ACCENT" "accent2:$THEME_ACCENT2" "warning:$THEME_WARNING" "error:$THEME_ERROR" "success:$THEME_SUCCESS")

    for color_entry in "${colors[@]}"; do
        local label="${color_entry%%:*}"
        local hex="${color_entry#*:}"

        # Convert hex to RGB
        local r=$((16#${hex:1:2}))
        local g=$((16#${hex:3:2}))
        local b=$((16#${hex:5:2}))

        printf "  %-12s" "${label}:"
        printf "\033[48;2;%d;%d;%dm    \033[0m" "$r" "$g" "$b"
        echo " ${hex}"
    done

    echo ""
    echo "  Separators: ${THEME_SEP_LEFT} ${THEME_SEP_RIGHT}"
    echo ""
}

## Display a gallery of all available themes
## Usage: theme_gallery
theme_gallery() {
    echo -e "${BOLD}Theme Gallery${RESET}"
    echo ""

    local themes
    themes=$(list_themes)

    while IFS= read -r theme; do
        [[ -z "$theme" ]] && continue
        preview_theme "$theme"
    done <<< "$themes"
}

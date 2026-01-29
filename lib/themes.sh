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

## Load a theme and export its colors as variables
## Usage: load_theme <theme_name>
## Sets: THEME_* variables
load_theme() {
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

    log_verbose "Loaded theme: $THEME_NAME"
    return 0
}

# -----------------------------------------------------------------------------
# Theme application functions
# -----------------------------------------------------------------------------

## Apply Starship prompt theme
## Usage: apply_starship_theme <theme_name>
apply_starship_theme() {
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

    log_verbose "Theme applied: $theme_name"
    return 0
}

## Preview theme colors in terminal
## Usage: preview_theme <theme_name>
preview_theme() {
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

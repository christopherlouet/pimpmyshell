#!/usr/bin/env bash
# pimpmyshell - Core utility functions
# https://github.com/christopherlouet/pimpmyshell

# Guard against re-sourcing
[[ -n "${_PIMPMYSHELL_CORE_LOADED:-}" ]] && return 0
_PIMPMYSHELL_CORE_LOADED=1

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

PIMPMYSHELL_VERSION="${PIMPMYSHELL_VERSION:-0.2.1}"
PIMPMYSHELL_CONFIG_DIR="${PIMPMYSHELL_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/pimpmyshell}"
PIMPMYSHELL_DATA_DIR="${PIMPMYSHELL_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/pimpmyshell}"
PIMPMYSHELL_CACHE_DIR="${PIMPMYSHELL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pimpmyshell}"

# Colors for output (respect NO_COLOR)
if [[ -z "${NO_COLOR:-}" && -t 2 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    # shellcheck disable=SC2034
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' DIM='' RESET=''
fi

# Verbosity level (0=quiet, 1=normal, 2=verbose, 3=debug)
PIMPMYSHELL_VERBOSITY="${PIMPMYSHELL_VERBOSITY:-1}"

# -----------------------------------------------------------------------------
# Logging functions
# -----------------------------------------------------------------------------

## Log an info message (shown at verbosity >= 1)
log_info() {
    [[ "${PIMPMYSHELL_VERBOSITY}" -ge 1 ]] && echo -e "${GREEN}[INFO]${RESET} $*" >&2
    return 0
}

## Log a success message (shown at verbosity >= 1)
log_success() {
    [[ "${PIMPMYSHELL_VERBOSITY}" -ge 1 ]] && echo -e "${GREEN}[OK]${RESET} $*" >&2
    return 0
}

## Log a warning message (shown at verbosity >= 1)
log_warn() {
    [[ "${PIMPMYSHELL_VERBOSITY}" -ge 1 ]] && echo -e "${YELLOW}[WARN]${RESET} $*" >&2
    return 0
}

## Log an error message (always shown)
log_error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
    return 0
}

## Log a debug message (shown at verbosity >= 3)
log_debug() {
    [[ "${PIMPMYSHELL_VERBOSITY}" -ge 3 ]] && echo -e "${DIM}[DEBUG]${RESET} $*" >&2
    return 0
}

## Log a verbose message (shown at verbosity >= 2)
log_verbose() {
    [[ "${PIMPMYSHELL_VERBOSITY}" -ge 2 ]] && echo -e "${CYAN}[VERBOSE]${RESET} $*" >&2
    return 0
}

# -----------------------------------------------------------------------------
# Enhanced Error Functions
# -----------------------------------------------------------------------------

## Log an error with a suggested action
error_with_suggestion() {
    local error_msg="$1"
    local suggestion="$2"

    echo -e "${RED}${BOLD}[ERROR]${RESET} ${error_msg}" >&2
    if [[ -n "$suggestion" ]]; then
        echo -e "        ${YELLOW}Suggestion:${RESET} ${suggestion}" >&2
    fi
    return 0
}

## Log a fatal error and exit
die() {
    local message="$1"
    local exit_code="${2:-1}"

    echo -e "${RED}${BOLD}[FATAL]${RESET} ${message}" >&2
    exit "$exit_code"
}

## Log a fatal error with help hint and exit
die_with_help() {
    local message="$1"
    local hint="${2:-pimpmyshell help}"

    echo -e "${RED}${BOLD}[FATAL]${RESET} ${message}" >&2
    echo -e "        ${DIM}Run '${hint}' for usage information${RESET}" >&2
    exit 1
}

## Log an error with detailed context (multiline)
log_error_detail() {
    local title="$1"
    local details="$2"

    echo -e "${RED}${BOLD}[ERROR]${RESET} ${title}" >&2
    echo -e "${RED}────────────────────────────────────────${RESET}" >&2
    echo -e "${details}" >&2
    echo -e "${RED}────────────────────────────────────────${RESET}" >&2
    return 0
}

## Display a boxed error message for critical errors
log_error_box() {
    local message="$1"
    local len=${#message}
    local border=""

    for ((i = 0; i < len + 4; i++)); do
        border+="─"
    done

    echo -e "${RED}┌${border}┐${RESET}" >&2
    echo -e "${RED}│${RESET}  ${BOLD}${message}${RESET}  ${RED}│${RESET}" >&2
    echo -e "${RED}└${border}┘${RESET}" >&2
    return 0
}

## Log a warning with suggested action
warn_with_action() {
    local warning="$1"
    local action="$2"

    echo -e "${YELLOW}[WARN]${RESET} ${warning}" >&2
    if [[ -n "$action" ]]; then
        echo -e "       ${DIM}Action:${RESET} ${action}" >&2
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Platform detection
# -----------------------------------------------------------------------------

## Detect the current platform
## Returns: linux, macos, wsl, or unknown
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

## Check if running on macOS
is_macos() {
    [[ "$(get_platform)" == "macos" ]]
}

## Check if running on Linux
is_linux() {
    [[ "$(get_platform)" == "linux" ]]
}

## Check if running in WSL
is_wsl() {
    [[ "$(get_platform)" == "wsl" ]]
}

# -----------------------------------------------------------------------------
# Dependency checking
# -----------------------------------------------------------------------------

## Check if a command exists
check_command() {
    command -v "$1" &>/dev/null
}

## Require a command to exist, exit with error if not found
require_command() {
    local cmd="$1"
    local hint="${2:-}"

    if ! check_command "$cmd"; then
        log_error "Required command '$cmd' not found."
        if [[ -n "$hint" ]]; then
            log_error "Install with: $hint"
        fi
        return 1
    fi
    log_debug "Found required command: $cmd"
}

## Check if a dependency exists (soft check, returns status)
check_dependency() {
    local cmd="$1"
    if check_command "$cmd"; then
        log_debug "Dependency found: $cmd"
        return 0
    else
        log_debug "Dependency missing: $cmd"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# File operations
# -----------------------------------------------------------------------------

## Create a backup of a file with timestamp
backup_file() {
    local file="$1"
    local backup_dir="${PIMPMYSHELL_DATA_DIR}/backups"
    local timestamp backup_path

    if [[ ! -f "$file" ]]; then
        log_debug "No file to backup: $file"
        return 0
    fi

    mkdir -p "$backup_dir"
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_path="${backup_dir}/$(basename "$file").${timestamp}.bak"

    cp "$file" "$backup_path"
    log_verbose "Backed up $file to $backup_path"
    echo "$backup_path"
}

## Create a symlink safely (with backup of existing file)
symlink_safe() {
    local source="$1"
    local target="$2"

    if [[ -e "$target" && ! -L "$target" ]]; then
        log_info "Backing up existing file: $target"
        backup_file "$target"
        rm -f "$target"
    elif [[ -L "$target" ]]; then
        rm -f "$target"
    fi

    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    log_verbose "Created symlink: $target -> $source"
}

## Ensure a directory exists
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "Created directory: $dir"
    fi
}

# -----------------------------------------------------------------------------
# Module Loading
# -----------------------------------------------------------------------------

# Track loaded modules
declare -a _PIMPMYSHELL_LOADED_MODULES=()

## Load a module/library file with explicit error handling
load_module() {
    local module_path="$1"
    local required="${2:-optional}"
    local module_name
    module_name=$(basename "$module_path" .sh)

    if array_contains "$module_path" "${_PIMPMYSHELL_LOADED_MODULES[@]:-}"; then
        log_debug "Module already loaded: $module_name"
        return 0
    fi

    if [[ ! -f "$module_path" ]]; then
        if [[ "$required" == "required" ]]; then
            die "Required module not found: $module_path"
        else
            log_debug "Optional module not found: $module_path"
            return 1
        fi
    fi

    if [[ ! -r "$module_path" ]]; then
        if [[ "$required" == "required" ]]; then
            die "Cannot read required module: $module_path"
        else
            log_warn "Cannot read optional module: $module_path"
            return 1
        fi
    fi

    log_debug "Loading module: $module_name ($module_path)"
    # shellcheck disable=SC1090
    if source "$module_path"; then
        _PIMPMYSHELL_LOADED_MODULES+=("$module_path")
        log_debug "Loaded module: $module_name"
        return 0
    else
        if [[ "$required" == "required" ]]; then
            die "Failed to load required module: $module_path"
        else
            log_warn "Failed to load optional module: $module_path"
            return 1
        fi
    fi
}

## Load a library from the lib directory
load_lib() {
    local lib_name="$1"
    local required="${2:-required}"
    local lib_path="${PIMPMYSHELL_LIB_DIR}/${lib_name}.sh"

    load_module "$lib_path" "$required"
}

## List all loaded modules
list_loaded_modules() {
    if [[ -z "${_PIMPMYSHELL_LOADED_MODULES[*]:-}" ]] || [[ ${#_PIMPMYSHELL_LOADED_MODULES[@]} -eq 0 ]]; then
        echo "No modules loaded"
        return 0
    fi

    echo "Loaded modules:"
    local module
    for module in "${_PIMPMYSHELL_LOADED_MODULES[@]}"; do
        echo "  - $(basename "$module" .sh)"
    done
}

## Check if a module is loaded
is_module_loaded() {
    local module="$1"

    if array_contains "$module" "${_PIMPMYSHELL_LOADED_MODULES[@]:-}"; then
        return 0
    fi

    local loaded
    for loaded in "${_PIMPMYSHELL_LOADED_MODULES[@]:-}"; do
        if [[ "$(basename "$loaded" .sh)" == "$module" ]]; then
            return 0
        fi
    done

    return 1
}

# -----------------------------------------------------------------------------
# String utilities
# -----------------------------------------------------------------------------

## Trim whitespace from a string
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

## Check if a string is empty or contains only whitespace
is_empty() {
    local trimmed
    trimmed=$(trim "$1")
    [[ -z "$trimmed" ]]
}

## Convert string to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

## Convert string to uppercase
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# -----------------------------------------------------------------------------
# Array utilities
# -----------------------------------------------------------------------------

## Check if an array contains a value
array_contains() {
    local needle="$1"
    shift
    local element
    for element in "$@"; do
        [[ "$element" == "$needle" ]] && return 0
    done
    return 1
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

## Initialize pimpmyshell directories
init_directories() {
    ensure_dir "$PIMPMYSHELL_CONFIG_DIR"
    ensure_dir "$PIMPMYSHELL_DATA_DIR"
    ensure_dir "$PIMPMYSHELL_CACHE_DIR"
    ensure_dir "${PIMPMYSHELL_DATA_DIR}/backups"
    log_debug "Initialized pimpmyshell directories"
}

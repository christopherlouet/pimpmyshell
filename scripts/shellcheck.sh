#!/usr/bin/env bash
# pimpmyshell - Run shellcheck on all shell scripts
# Same configuration as CI to ensure local/CI parity.
#
# Usage: ./scripts/shellcheck.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if ! command -v shellcheck &>/dev/null; then
    echo "ERROR: shellcheck is not installed"
    echo "  macOS:  brew install shellcheck"
    echo "  Linux:  sudo apt install shellcheck"
    exit 1
fi

echo "Running shellcheck on pimpmyshell..."

errors=0

check_files() {
    local label="$1"
    shift
    local files=("$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        return
    fi

    echo "  Checking ${label}..."
    for f in "${files[@]}"; do
        if [[ -f "$f" ]]; then
            if ! shellcheck -S warning -e SC1091 "$f"; then
                ((errors++))
            fi
        fi
    done
}

# Main binary
check_files "bin/" "${ROOT_DIR}/bin/pimpmyshell"

# Library files
mapfile -t lib_files < <(find "${ROOT_DIR}/lib" -name "*.sh" -type f | sort)
check_files "lib/" "${lib_files[@]}"

# Install script
check_files "install.sh" "${ROOT_DIR}/install.sh"

# Module files
mapfile -t alias_files < <(find "${ROOT_DIR}/modules/aliases" -name "*.sh" -type f 2>/dev/null | sort)
if [[ ${#alias_files[@]} -gt 0 ]]; then
    check_files "modules/aliases/" "${alias_files[@]}"
fi

mapfile -t integ_files < <(find "${ROOT_DIR}/modules/integrations" -name "*.sh" -type f 2>/dev/null | sort)
if [[ ${#integ_files[@]} -gt 0 ]]; then
    check_files "modules/integrations/" "${integ_files[@]}"
fi

if [[ $errors -gt 0 ]]; then
    echo ""
    echo "FAIL: $errors file(s) had shellcheck warnings"
    exit 1
else
    echo ""
    echo "OK: All files passed shellcheck"
fi

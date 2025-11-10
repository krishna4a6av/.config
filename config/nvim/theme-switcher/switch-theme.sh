#!/usr/bin/env bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_FILE="${SCRIPT_DIR}/current_theme.txt"

# Theme mappings: slug -> colorscheme command
declare -A THEMES=(
    ["Catppuccin"]="catppuccin"
    ["Autmn"]="OceanicNext"
    ["Everforest"]="everforest"
    ["Nightfox"]="nightfox"
    ["Gruvbox"]="gruvbox"
    ["Graphite"]="flexoki"
    ["Crimson"]="sakura"
    ["Kanagawa"]="kanagawa"
    ["Oxocarbon"]="oxocarbon"
    ["Rosepine"]="rose-pine-moon"
    ["Tokyo-night"]="tokyonight-night"
)


# Theme name from argument
THEME_NAME="${1:-}"

if [[ -z "$THEME_NAME" ]]; then
    echo "Usage: $(basename "$0") <theme-name>"
    echo ""
    echo "Available themes:"
    for theme in "${!THEMES[@]}"; do
        echo "  $theme"
    done | sort
    exit 1
fi

# Check if theme exists
if [[ -z "${THEMES[$THEME_NAME]:-}" ]]; then
    echo "Error: Theme '${THEME_NAME}' not found"
    echo ""
    echo "Available themes:"
    for theme in "${!THEMES[@]}"; do
        echo "  $theme"
    done | sort
    exit 1
fi

COLORSCHEME="${THEMES[$THEME_NAME]}"

# Save theme preference
echo "$COLORSCHEME" > "$THEME_FILE"
echo "✅ Theme switched to '${THEME_NAME}' (${COLORSCHEME})"
echo "   Saved to: ${THEME_FILE}"

# Try to reload in running Neovim instances
shopt -s nullglob
NVIM_SOCKETS=()

# Check common socket locations
if [[ -n ${XDG_RUNTIME_DIR:-} && -d ${XDG_RUNTIME_DIR:-} ]]; then
    NVIM_SOCKETS+=("${XDG_RUNTIME_DIR}"/nvim.*)
fi
NVIM_SOCKETS+=(/run/user/*/nvim.*)
NVIM_SOCKETS+=(/tmp/nvim-server*.pipe)

shopt -u nullglob

# Remove duplicates and non-existent sockets
VALID_SOCKETS=()
for socket in "${NVIM_SOCKETS[@]}"; do
    if [[ -S "$socket" ]]; then
        VALID_SOCKETS+=("$socket")
    fi
done

if ((${#VALID_SOCKETS[@]} > 0)); then
    echo ""
    echo "Applying theme to ${#VALID_SOCKETS[@]} running Neovim instance(s)..."
    for socket in "${VALID_SOCKETS[@]}"; do
        if nvim --server "$socket" --remote-expr "execute('colorscheme ${COLORSCHEME}')" &>/dev/null; then
            echo "  ✓ Applied to: $socket"
        else
            echo "  ✗ Failed to apply to: $socket"
        fi
    done
    echo "✅ Done applying theme"
else
    echo ""
    echo "ℹ️  No running Neovim instances found"
    echo "   Make sure Neovim is started with --listen option"
    echo "   Example: nvim --listen /tmp/nvim-server.pipe"
fi

#!/usr/bin/env bash

# GTK theme switcher, maps generic names to GTK themes and applies them system-wide
set -e

# Theme mapping: generic_name -> GTK_theme_name
declare -A THEME_MAP=(
    ["dracula"]="Colloid-Dark-Dracula"
    ["autmn"]="Colloid-Dark-Autmn"
    ["gruvbox"]="Colloid-Dark-Gruvbox"
    ["catppuccin"]="Colloid-Dark-Catppuccin"
    ["kanagawa"]="Colloid-Dark-Kanagawa"
    ["tokyo-night"]="Tokyonight-Dark"
    ["everforest"]="Colloid-Dark-Everforest"
    ["rosepine"]="Colloid-Dark-Rosepine"
    ["graphite"]="Colloid-Dark-Graphite"
    ["oxocarbon"]="Colloid-Dark-Oxocarbon"
    ["crimson"]="Colloid-Dark-Crimson"
    ["flexoki"]="Colloid-Flexoki"
    ["slatemist"]="Colloid-Dark-Slatemist"

    # Add your custom mappings here
    # ["my-theme"]="Actual-GTK-Theme-Name"
)

# Theme directories to search
THEME_DIRS=(
    "/usr/share/themes"
    "$HOME/.themes"
    "$HOME/.local/share/themes"
)

show_usage() {
    echo "Usage: $(basename "$0") <theme-name>"
    echo ""
    echo "Generic theme names available:"
    echo "-------------------------------"
    for key in "${!THEME_MAP[@]}"; do
        printf "  %-20s -> %s\n" "$key" "${THEME_MAP[$key]}"
    done | sort
    echo ""
    echo "You can also use exact GTK theme names directly."
    echo ""
    echo "Current theme: $(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Available themes (from all locations):"
    for dir in "${THEME_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            ls -1 "$dir" 2>/dev/null
        fi
    done | sort -u | head -20
    echo "... (showing first 20 themes)"
}

find_theme() {
    local theme_name="$1"
    for dir in "${THEME_DIRS[@]}"; do
        if [[ -d "$dir/$theme_name" ]]; then
            echo "$dir/$theme_name"
            return 0
        fi
    done
    return 1
}

# Main logic
if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
fi

GENERIC_NAME="$1"
GENERIC_NAME_LOWER="${GENERIC_NAME,,}"  # Convert to lowercase

# Check if it's a mapped generic name
if [[ -n "${THEME_MAP[$GENERIC_NAME_LOWER]}" ]]; then
    THEME="${THEME_MAP[$GENERIC_NAME_LOWER]}"
    echo "🎨 Mapping '$GENERIC_NAME' -> '$THEME'"
else
    # Use the provided name as-is (maybe it's already a GTK theme name)
    THEME="$GENERIC_NAME"
    echo "🎨 Using theme name as-is: '$THEME'"
fi

# Validate theme exists in any of the theme directories
if ! THEME_PATH=$(find_theme "$THEME"); then
    echo "❌ Error: Theme '$THEME' not found in any theme directory!"
    echo ""
    echo "Searched in:"
    for dir in "${THEME_DIRS[@]}"; do
        echo "  - $dir"
    done
    echo ""
    echo "Available themes:"
    for dir in "${THEME_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            ls -1 "$dir" 2>/dev/null
        fi
    done | sort -u
    exit 1
fi

echo "✓ Found theme at: $THEME_PATH"

echo "🔧 Updating GSettings and Dconf..."
gsettings set org.gnome.desktop.interface gtk-theme "$THEME" || true
gsettings set org.gnome.desktop.interface color-scheme 'default'
dconf write /org/gnome/desktop/interface/gtk-theme "'$THEME'" || true

# Update GTK config files
GTK3_CONF="$HOME/.config/gtk-3.0/settings.ini"
GTK4_CONF="$HOME/.config/gtk-4.0/settings.ini"


echo ""
echo "✅ GTK theme successfully changed to: $THEME"
echo "   📁 Theme location: $THEME_PATH"
echo "   ⚙️  Updated: GSettings, Dconf, GTK3/4 configs"
echo "   🔄 Reloaded: Desktop portals"
echo ""
echo "Note: Some apps may need to be restarted to see the changes."

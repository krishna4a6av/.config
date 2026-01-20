#!/bin/bash
set -euo pipefail

# Main theme switcher file controls all the others.
# Right now this script is reading the theme names from a text file for ease of changing. Maybe i'll change it later.
THEME_LIST="$HOME/.config/colors/Themer/themes.txt"
WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
ROFI_NOTIF="$HOME/.config/rofi/notify.rasi"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THEME_SYMLINK="$CACHE_DIR/current_theme"

COLOR_SWITCHER="$HOME/.config/colors/Themer/Colors.sh"
NVIM_THEME_SWITCHER="$HOME/.config/nvim/theme-switcher/switch-theme.sh"
GTK_SWITCHER="$HOME/.config/colors/Themer/Setgtk.sh"
WALLPAPER_SWITCHER="$HOME/.config/colors/Themer/Wallpaper.sh"
MATUGEN_GENERATOR="$HOME/.config/colors/Themer/Matugen.sh"

# Load themes from file
if [[ ! -f "$THEME_LIST" ]]; then
    rofi -e "❌ Theme list not found: $THEME_LIST" -theme "$ROFI_NOTIF"
    exit 1
fi

mapfile -t THEMES < <(
    grep -Ev '^\s*(#|$)' "$THEME_LIST"
)

[[ "${#THEMES[@]}" -eq 0 ]] && {
    rofi -e "❌ No themes defined in $THEME_LIST" -theme "$ROFI_NOTIF"
    exit 1
}

# Build Rofi menu
MENU=""
for theme in "${THEMES[@]}"; do
    if [[ -d "$WALLPAPER_ROOT/$theme" ]]; then
        MENU+="$theme\n"
    else
        MENU+="$theme  (no wallpapers)\n"
    fi
done

OPTIONS=$(printf "%bMatugen (light)\nMatugen (dark)\n" "$MENU")

THEME=$(echo "$OPTIONS" | rofi -dmenu -p "Select theme")

[[ -z "$THEME" ]] && { echo "❌ No theme selected."; exit 1; }

# Case matugen themes are selected
if [[ "$THEME" =~ ^Matugen ]]; then

    if [[ "$THEME" == "Matugen (light)" ]]; then
        MODE="light"
    elif [[ "$THEME" == "Matugen (dark)" ]]; then
        MODE="dark"
    fi

    echo "🎨 Matugen mode activated → $MODE"
    rm -f "$THEME_SYMLINK"   # Using matugen, no theme folder needed
    "$WALLPAPER_SWITCHER" "all"
    "$MATUGEN_GENERATOR" "$MODE"
    exit 0
fi

ln -sfn "$WALLPAPER_ROOT/$THEME" "$THEME_SYMLINK"

"$COLOR_SWITCHER" "$THEME"
"$NVIM_THEME_SWITCHER" "$THEME"
"$GTK_SWITCHER" "$THEME"
"$WALLPAPER_SWITCHER" "$THEME"


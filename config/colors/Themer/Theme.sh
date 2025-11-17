#!/bin/bash

WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THEME_SYMLINK="$CACHE_DIR/current_theme"

COLOR_SWITCHER="$HOME/.config/colors/Themer/Colors.sh"
NVIM_THEME_SWITCHER="$HOME/.config/nvim/theme-switcher/switch-theme.sh"
GTK_SWITCHER="$HOME/.config/colors/Themer/Setgtk.sh"
WALLPAPER_SWITCHER="$HOME/.config/colors/Themer/Wallpaper.sh"
MATUGEN_GENERATOR="$HOME/.config/colors/Themer/Matugen.sh"

FOLDERS=$(find "$WALLPAPER_ROOT" -mindepth 1 -maxdepth 1 -type d ! -iname ".*" -exec basename {} \;)

OPTIONS=$(printf "%s\nMatugen (light)\nMatugen (dark)" "$FOLDERS")

THEME=$(echo "$OPTIONS" | rofi -dmenu -p "Select theme")

[[ -z "$THEME" ]] && { echo "❌ No theme selected."; exit 1; }

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


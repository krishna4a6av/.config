#!/bin/bash

WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THEME_SYMLINK="$CACHE_DIR/current_theme"
NVIM_THEME_SWITCHER="$HOME/.config/nvim/theme-switcher/switch-theme.sh"

# List theme folders (which are also names of the color themes)
FOLDERS=$(find "$WALLPAPER_ROOT" -mindepth 1 -maxdepth 1 -type d ! -iname ".*" -exec basename {} \;)
THEME=$(echo "$FOLDERS" | rofi -dmenu -p "Select theme")

[[ -z "$THEME" ]] && { echo "❌ No theme selected."; exit 1; }

# Save theme symlink
ln -sfn "$WALLPAPER_ROOT/$THEME" "$THEME_SYMLINK"

# Update colors + wallpaper
"$HOME/Scripts/Colors.sh" "$THEME"
"$NVIM_THEME_SWITCHER" "$THEME"
"$HOME/Scripts/Setgtk.sh" "$THEME"
"$HOME/Scripts/Wallpaper.sh" "$THEME"


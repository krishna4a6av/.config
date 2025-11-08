#!/bin/bash

WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THEME_SYMLINK="$CACHE_DIR/current_theme"

COLOR_SWITCHER="$HOME/.config/colors/Themer/Colors.sh"
NVIM_THEME_SWITCHER="$HOME/.config/nvim/theme-switcher/switch-theme.sh"
GTK_SWITCHER="$HOME/.config/colors/Themer/Setgtk.sh"
WALLPAPER_SWITCHER="$HOME/.config/colors/Themer/Wallpaper.sh"

# List theme folders (which are also names of the color themes)
FOLDERS=$(find "$WALLPAPER_ROOT" -mindepth 1 -maxdepth 1 -type d ! -iname ".*" -exec basename {} \;)
THEME=$(echo "$FOLDERS" | rofi -dmenu -p "Select theme")

[[ -z "$THEME" ]] && { echo "❌ No theme selected."; exit 1; }

# Save theme symlink
ln -sfn "$WALLPAPER_ROOT/$THEME" "$THEME_SYMLINK"

# scripts calling
"$COLOR_SWITCHER" "$THEME"
"$NVIM_THEME_SWITCHER" "$THEME"
"$GTK_SWITCHER" "$THEME"
"$WALLPAPER_SWITCHER" "$THEME"


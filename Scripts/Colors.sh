#!/usr/bin/env bash

# Usage: colors.sh <ThemeName>

THEME_DIR="$HOME/.config/colors/themes"
ROFI_DIR="$HOME/.config/colors/rofi"
HYPR_DIR="$HOME/.config/colors/hyprland"

THEME_LINK="$HOME/.config/colors/theme.css"
ROFI_LINK="$HOME/.config/colors/rofi_theme.rasi"
HYPR_LINK="$HOME/.config/colors/colors.conf"

THEME_NAME="$1"

if [[ -z "$THEME_NAME" ]]; then
    echo "Usage: colors.sh <ThemeName>"
    exit 1
fi

THEME_FILE="$THEME_DIR/${THEME_NAME}.css"
ROFI_FILE="$ROFI_DIR/${THEME_NAME}.rasi"
HYPR_FILE="$HYPR_DIR/${THEME_NAME}.conf"

# Check required files exist
if [[ ! -f "$THEME_FILE" ]]; then
    echo "❌ Theme CSS '$THEME_FILE' not found."
    exit 1
fi

if [[ ! -f "$ROFI_FILE" ]]; then
    echo "❌ Rofi theme '$ROFI_FILE' not found."
    exit 1
fi

if [[ ! -f "$HYPR_FILE" ]]; then
    echo "❌ Theme conf '$HYPR_FILE' not found."
    exit 1
fi

# Apply symlinks
ln -sf "$THEME_FILE" "$THEME_LINK"
ln -sf "$ROFI_FILE" "$ROFI_LINK"
ln -sf "$HYPR_FILE" "$HYPR_LINK"

# Reload components
pkill -SIGUSR2 waybar
pkill swaync && swaync & disown


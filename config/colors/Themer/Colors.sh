#!/usr/bin/env bash

# Usage: colors.sh <ThemeName>
# Replace the colors file for different applications
# managed by themes.sh
THEME_DIR="$HOME/.config/colors/themes"
ROFI_DIR="$HOME/.config/colors/rofi"
ROFI_NOTIF="$HOME/.config/rofi/notify.rasi"
HYPR_DIR="$HOME/.config/colors/hyprland"
KITTY_DIR="$HOME/.config/colors/kitty"

THEME_LINK="$HOME/.config/colors/theme.css"
ROFI_LINK="$HOME/.config/colors/rofi_theme.rasi"
HYPR_LINK="$HOME/.config/colors/colors.conf"
KITTY_LINK="$HOME/.config/colors/colors-kitty.conf"

THEME_NAME="$1"

if [[ -z "$THEME_NAME" ]]; then
    echo "Usage: colors.sh <ThemeName>"
    exit 1
fi

THEME_FILE="$THEME_DIR/${THEME_NAME}.css"
ROFI_FILE="$ROFI_DIR/${THEME_NAME}.rasi"
HYPR_FILE="$HYPR_DIR/${THEME_NAME}.conf"
KITTY_FILE="$KITTY_DIR/${THEME_NAME}.conf"
#matugen symlinks are handled in Matugen.sh

# Check required files exist
if [[ ! -f "$THEME_FILE" ]]; then
    rofi -e "❌ Theme CSS '$THEME_FILE' not found." -theme "$ROFI_NOTIF"
    exit 1
fi

if [[ ! -f "$ROFI_FILE" ]]; then
    rofi -e "❌ Rofi theme '$ROFI_FILE' not found." -theme "$ROFI_NOTIF"
    exit 1
fi

if [[ ! -f "$HYPR_FILE" ]]; then
    rofi -e "❌ Hyprland theme '$HYPR_FILE' not found." -theme "$ROFI_NOTIF"
    exit 1
fi

if [[ ! -f "$KITTY_FILE" ]]; then
    rofi -e "❌ Kitty theme '$KITTY_FILE' not found." -theme "$ROFI_NOTIF"
    exit 1
fi

# Apply symlinks
ln -sf "$THEME_FILE" "$THEME_LINK"
ln -sf "$ROFI_FILE" "$ROFI_LINK"
ln -sf "$HYPR_FILE" "$HYPR_LINK"
ln -sf "$KITTY_FILE" "$KITTY_LINK"

# Reload components
pkill waybar && waybar & disown
pkill swaync && swaync & disown

# Reload Kitty (will affect new windows only)
kill -SIGUSR1 $(pgrep kitty)


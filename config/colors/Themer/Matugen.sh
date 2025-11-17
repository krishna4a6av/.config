#!/usr/bin/env bash

MATUGEN_DIR="$HOME/.config/colors/matugen"
WALLPAPER_SYMLINK="$HOME/.cache/wall-cache/current_wallpaper"
SET_GTK="$HOME/.config/colors/Themer/setgtk.sh"

THEME_LINK="$HOME/.config/colors/theme.css"
ROFI_LINK="$HOME/.config/colors/rofi_theme.rasi"
HYPR_LINK="$HOME/.config/colors/colors.conf"
KITTY_LINK="$HOME/.config/colors/colors-kitty.conf"

MODE="${1:-auto}"

if [[ "$MODE" != "light" && "$MODE" != "dark" && "$MODE" != "auto" ]]; then
    echo "❌ Invalid mode: $MODE"
    echo "Usage: matugen.sh [light|dark|auto]"
    exit 1
fi

echo "🔆 Matugen Mode: $MODE"

if [[ ! -L "$WALLPAPER_SYMLINK" ]]; then
    echo "❌ No wallpaper symlink found at $WALLPAPER_SYMLINK"
    exit 1
fi

WALL="$(readlink -f "$WALLPAPER_SYMLINK")"

if [[ ! -f "$WALL" ]]; then
    echo "❌ Wallpaper does not exist: $WALL"
    exit 1
fi

echo "🎨 Running Matugen for wallpaper:"
echo "   $WALL"

if [[ "$MODE" == "auto" ]]; then
    matugen image "$WALL"
else
    matugen image --mode "$MODE" "$WALL"
fi

echo "🔗 Updating Matugen symlinks..."

ln -sf "$MATUGEN_DIR/theme.css"          "$THEME_LINK"
ln -sf "$MATUGEN_DIR/rofi_theme.rasi"    "$ROFI_LINK"
ln -sf "$MATUGEN_DIR/colors.conf"        "$HYPR_LINK"
ln -sf "$MATUGEN_DIR/colors-kitty.conf"  "$KITTY_LINK"

echo "✔ Symlinks updated."


echo "✅ Matugen theme applied successfully."


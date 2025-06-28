#!/bin/bash

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
mkdir -p "$CACHE_DIR"

SYMLINK="$CACHE_DIR/current_wallpaper"
THEME_SYMLINK="$CACHE_DIR/current_theme"
WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"

THEME="$1"


# ── Show current wallpaper path ──
if [[ "$THEME" == "current" ]]; then
  if [[ -L "$SYMLINK" && -e "$SYMLINK" ]]; then
    readlink -f "$SYMLINK"
    exit 0
  else
    echo "❌ No wallpaper symlink found."
    exit 1
  fi
fi

# ── Use saved theme if asked ──
if [[ "$THEME" == "current_theme" ]]; then
  if [[ -L "$THEME_SYMLINK" && -e "$THEME_SYMLINK" ]]; then
    THEME=$(basename "$(readlink -f "$THEME_SYMLINK")")
  else
    echo "❌ No theme symlink found."
    exit 1
  fi
fi

#No theme passed: select folder, ignores hidden folders
if [[ -z "$THEME" ]]; then
  FOLDERS=$(find "$WALLPAPER_ROOT" -mindepth 1 -maxdepth 1 -type d ! -iname ".*" -exec basename {} \;)
  THEME=$(echo "$FOLDERS" | rofi -dmenu -p "Select theme folder")
  if [[ -z "$THEME" ]]; then
    echo "❌ No folder selected."
    exit 1
  fi
fi

WALLPAPER_DIR="$WALLPAPER_ROOT/$THEME"

#Verify folder exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "❌ Theme folder not found: $WALLPAPER_DIR"
  exit 1
fi

#Save theme symlink so that we can acces current theme from /tmp/current_theme
ln -sfn "$WALLPAPER_DIR" "$THEME_SYMLINK"

# Find wallpapers(ignores hidden file)
WALLS=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \))

#Rofi thumbnail menu
ENTRIES=""
while IFS= read -r img; do
    name=$(basename "$img")
    ENTRIES+="$name\x00icon\x1f$img\n"
done <<< "$WALLS"

# Show thumbnails in rofi
SELECTED_NAME=$(echo -e "$ENTRIES" | rofi -dmenu -show-icons -p "Select wallpaper" -theme "$ROFI_THEME")

#Cancelled?
if [[ -z "$SELECTED_NAME" ]]; then
  echo "❌ No wallpaper selected."
  exit 1
fi

#Find full path
SELECTED=$(find "$WALLPAPER_DIR" -type f -name "$SELECTED_NAME" | head -n 1)

#Start swww-daemon if... well needed
if ! pgrep -x swww-daemon > /dev/null; then
  swww-daemon &
  sleep 0.5
fi

#Set wallpaper
swww img "$SELECTED" --transition-type any --transition-duration 1

#Update wallpaper symlink to acess the current wall in /tmp/current_wallpaper
ln -sf "$SELECTED" "$SYMLINK"

echo "✅ Wallpaper set: $SELECTED"
echo "🔗 Wallpaper symlink: $SYMLINK"
echo "🎨 Theme symlink: $THEME_SYMLINK → $THEME"


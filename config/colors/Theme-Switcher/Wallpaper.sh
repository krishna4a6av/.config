#!/usr/bin/env bash

# Creates a rofi menu selector for wallpapers.
set -euo pipefail

THEME="${1:-}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THUMB_DIR="$CACHE_DIR/thumbs"
SYMLINK="$CACHE_DIR/current_wallpaper"
THEME_SYMLINK="$CACHE_DIR/current_theme"

WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"

ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"
ROFI_NOTIF="$HOME/.config/rofi/notify.rasi"

mkdir -p "$THUMB_DIR"

print_usage() {
    cat <<EOF
Wallpaper Manager
-----------------
Usage:
  wallpapers.sh
  wallpapers.sh path
  wallpapers.sh <theme-name>
  wallpapers.sh all
  wallpapers.sh help
EOF
}

[[ "$THEME" == "help" ]] && { print_usage; exit 0; }


# Show current wallpaper path
if [[ "$THEME" == "path" ]]; then
    if [[ -L "$SYMLINK" ]]; then
        readlink -f "$SYMLINK"
    else
        rofi -e "❌ No wallpaper is currently set" -theme "$ROFI_NOTIF"
    fi
    exit 0
fi


# Resolve theme from cache
if [[ -z "$THEME" ]]; then
    if [[ -L "$THEME_SYMLINK" ]]; then
        THEME="$(basename "$(readlink -f "$THEME_SYMLINK")")"
    else
        THEME="all"
    fi
fi

make_thumb() {
    local img="$1" thumb="$2" base tmp
    base=$(basename "$img")

    if file --mime-type -b "$img" | grep -q '^video/'; then
        tmp="/tmp/${base%.*}.png"
        ffmpeg -y -i "$img" -frames:v 1 -q:v 2 "$tmp" &>/dev/null
        magick "$tmp" -strip -resize 400x600^ -gravity center -extent 400x600 "$thumb"
        rm -f "$tmp"
    else
        magick "$img"[0] -strip -resize 400x600^ -gravity center -extent 400x600 "$thumb"
    fi
}

thumb_name() {
    echo "$THUMB_DIR/$(printf "%s" "$1" | md5sum | cut -d' ' -f1).png"
}

collect_images() {
    local dir="$1"
    mapfile -t IMAGES < <(
        find "$dir" -type f \( \
            -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webm" \
        \)
    )
}


# Decide wallpaper source
if [[ "$THEME" == "all" ]]; then
    collect_images "$WALLPAPER_ROOT"
    PROMPT="Wallpaper (All)"
else
    WALLPAPER_DIR="$WALLPAPER_ROOT/$THEME"

    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        rofi -e "⚠️ Wallpaper folder missing

Expected:
$WALLPAPER_DIR

Create this folder to add wallpapers for theme '$THEME'." \
        -theme "$ROFI_NOTIF"
        exit 0
    fi

    collect_images "$WALLPAPER_DIR"

    if [[ "${#IMAGES[@]}" -eq 0 ]]; then
        notify-send "⚠️ No wallpapers found in:

$WALLPAPER_DIR

Showing all available wallpapers instead." 

        collect_images "$WALLPAPER_ROOT"
        PROMPT="Wallpaper (All)"
    else
        PROMPT="Wallpaper ($THEME)"
    fi
fi


# No wallpapers at all → hard error
if [[ "${#IMAGES[@]}" -eq 0 ]]; then
    rofi -e "❌ No wallpapers found anywhere.

Add images to:
$WALLPAPER_ROOT" \
    -theme "$ROFI_NOTIF"
    exit 1
fi


# Build Rofi menu
declare -A PATH_MAP
ENTRIES=""

for img in "${IMAGES[@]}"; do
    name="$(basename "$img")"
    thumb="$(thumb_name "$img")"

    [[ ! -f "$thumb" ]] && make_thumb "$img" "$thumb"

    PATH_MAP["$name"]="$img"
    ENTRIES+="${name}\x00icon\x1f${thumb}\n"
done

SELECTED_NAME=$(printf "%b" "$ENTRIES" | \
    LC_ALL=C rofi -dmenu -show-icons -p "$PROMPT" -theme "$ROFI_THEME") || exit 0

SELECTED="${PATH_MAP[$SELECTED_NAME]}"


# Apply wallpaper
swww-daemon --fork 2>/dev/null || true
swww img "$SELECTED" --transition-type any --transition-duration 1

ln -sf "$SELECTED" "$SYMLINK"
echo "✅ Wallpaper set: $SELECTED"


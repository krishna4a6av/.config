#!/usr/bin/env bash
set -euo pipefail

THEME="${1:-}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THUMB_DIR="$CACHE_DIR/thumbs"
SYMLINK="$CACHE_DIR/current_wallpaper"
THEME_SYMLINK="$CACHE_DIR/current_theme"

WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"


if [[ -z "$THEME" ]]; then
    if [[ ! -L "$THEME_SYMLINK" ]]; then
        THEME="all"
    fi
fi

print_usage() {
    cat <<EOF
Wallpaper Manager
-----------------
Usage:
  wallpapers.sh                  Pick wallpaper from current theme
  wallpapers.sh path             Print full path of current wallpaper
  wallpapers.sh <theme-name>     Pick wallpaper from the specific theme
  wallpapers.sh all              Pick wallpaper from all themes
  wallpapers.sh help             Show this help menu

Examples:
  wallpapers.sh path

-- You need to add wallpapers in ~/Pictures/Wallpapers/<theme-name>
EOF
}

# If user runs: wallpapers.sh help
if [[ "$THEME" == "help" ]]; then
    print_usage
    exit 0
fi


mkdir -p "$THUMB_DIR"

# Helper: Create thumbnail safely
make_thumb() {
    local img="$1"
    local thumb="$2"
    local base=$(basename "$img")
    local name="${base%.*}"

    if file --mime-type -b "$img" | grep -q '^video/'; then
        tmp="/tmp/${name}.png"
        ffmpeg -y -i "$img" -frames:v 1 -q:v 2 "$tmp" &>/dev/null
        magick "$tmp" -strip -resize 400x600^ -gravity center -extent 400x600 "$thumb"
        rm -f "$tmp"
    else
        magick "$img"[0] -strip -resize 400x600^ -gravity center -extent 400x600 "$thumb"
    fi
}

thumb_name() {
    local img="$1"
    local hash
    hash=$(printf "%s" "$img" | md5sum | cut -d' ' -f1)
    echo "$THUMB_DIR/${hash}.png"
}


# Mode: Show current wallpaper
if [[ "$THEME" == "path" ]]; then
    if [[ -L "$SYMLINK" ]]; then
        readlink -f "$SYMLINK"
    else
        echo "❌ No wallpaper symlink found."
    fi
    exit
fi


# Load previous theme if no theme given
if [[ -z "$THEME" ]]; then
    if [[ -L "$THEME_SYMLINK" ]]; then
        THEME=$(basename "$(readlink -f "$THEME_SYMLINK")")
    else
        echo "❌ No theme active. Select one manually."
        exit 1
    fi
fi


# MODE: ALL wallpapers across ALL themes
if [[ "$THEME" == "all" ]]; then
    mapfile -t ALL_IMAGES < <(
        find "$WALLPAPER_ROOT" \
            -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webm" \)
    )

    ENTRIES=""

    for img in "${ALL_IMAGES[@]}"; do
        base=$(basename "$img")
        name="${base%.*}"
        thumb=$(thumb_name "$img")

        [[ ! -f "$thumb" ]] && make_thumb "$img" "$thumb"

        ENTRIES+="${base}\x00icon\x1f${thumb}\n"
    done

    SELECTED_NAME=$(printf "%b" "$ENTRIES" | LC_ALL=C rofi -dmenu -show-icons -p "Select wallpaper" -theme "$ROFI_THEME") || exit 1

    SELECTED=$(printf "%s\n" "${ALL_IMAGES[@]}" | grep -F "/$SELECTED_NAME" | head -n 1)

    swww-daemon --fork 2>/dev/null || true
    swww img "$SELECTED" --transition-type any --transition-duration 1

    ln -sf "$SELECTED" "$SYMLINK"
    echo "✅ Wallpaper set: $SELECTED"
    echo "🎨 Matugen: regenerating theme from wallpaper..."
    "$HOME/.config/colors/Themer/Matugen.sh"
    exit
fi


# NORMAL THEME MODE
WALLPAPER_DIR="$WALLPAPER_ROOT/$THEME"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "❌ Theme folder not found: $WALLPAPER_DIR"
    exit 1
fi

mapfile -t THEME_IMAGES < <(
    find "$WALLPAPER_DIR" \
        -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webm" \)
)

ENTRIES=""

for img in "${THEME_IMAGES[@]}"; do
    base=$(basename "$img")
    name="${base%.*}"
    thumb=$(thumb_name "$img")

    [[ ! -f "$thumb" ]] && make_thumb "$img" "$thumb"

    ENTRIES+="${base}\x00icon\x1f${thumb}\n"
done

SELECTED_NAME=$(printf "%b" "$ENTRIES" | LC_ALL=C rofi -dmenu -show-icons -p "Wallpaper" -theme "$ROFI_THEME") || exit 1

SELECTED=$(printf "%s\n" "${THEME_IMAGES[@]}" | grep -F "/$SELECTED_NAME" | head -n 1)

swww-daemon --fork 2>/dev/null || true
swww img "$SELECTED" --transition-type any --transition-duration 1




ln -sf "$SELECTED" "$SYMLINK"
echo "✅ Wallpaper set: $SELECTED"



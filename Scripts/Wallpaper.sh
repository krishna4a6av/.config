#!/bin/bash

THEME="$1"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THUMB_DIR="$CACHE_DIR/thumbs"
SYMLINK="$CACHE_DIR/current_wallpaper"
THEME_SYMLINK="$CACHE_DIR/current_theme"
WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"
ROFI_CLIP="$HOME/.config/rofi/clipboard.rasi"

mkdir -p "$THUMB_DIR"

# ── Show current wallpaper path ──
if [[ "$THEME" == "current" ]]; then
  [[ -L "$SYMLINK" && -e "$SYMLINK" ]] && readlink -f "$SYMLINK" || echo "❌ No wallpaper symlink found."
  exit $?
fi

# ── Load theme from current_theme if none passed ──
if [[ -z "$THEME" ]]; then
  if [[ -L "$THEME_SYMLINK" && -e "$THEME_SYMLINK" ]]; then
    THEME=$(basename "$(readlink -f "$THEME_SYMLINK")")
  else
    echo "❌ No theme selected or active. Pass one manually."
    exit 1
  fi
fi

WALLPAPER_DIR="$WALLPAPER_ROOT/$THEME"
[[ ! -d "$WALLPAPER_DIR" ]] && { echo "❌ Theme folder not found: $WALLPAPER_DIR"; exit 1; }

# ── Check for missing thumbnails ──
theme_files=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webm" \))
missing_thumbs=()

while IFS= read -r img; do
  filename=$(basename "$img")
  name="${filename%.*}"
  thumb_path="$THUMB_DIR/${THEME}_${name}.thumb.png"
  [[ ! -f "$thumb_path" ]] && missing_thumbs+=("$img")
done <<< "$theme_files"

if [[ ${#missing_thumbs[@]} -gt 0 ]]; then
  echo "🔄 Caching ${#missing_thumbs[@]} missing thumbnails for $THEME..."
  echo -e "🔄 Caching thumbnails...\nPlease wait..." | rofi -dmenu -p "Processing" -theme "$ROFI_CLIP" &
  ROFI_PID=$!

  for img in "${missing_thumbs[@]}"; do
    filename=$(basename "$img")
    name="${filename%.*}"
    thumb_path="$THUMB_DIR/${THEME}_${name}.thumb.png"
    is_video=$(file --mime-type -b "$img" | grep -c '^video/')
    input_img="$img"

    if [[ "$is_video" -eq 1 ]]; then
      tmp_img="/tmp/${name}.png"
      ffmpeg -y -i "$img" -frames:v 1 -q:v 2 "$tmp_img" &>/dev/null
      input_img="$tmp_img"
    fi

    magick "$input_img"[0] -strip -resize 400x600^ -gravity center -extent 400x600 "$thumb_path"
    [[ "$is_video" -eq 1 ]] && rm -f "$tmp_img"
  done

  kill $ROFI_PID 2>/dev/null
fi

# ── Show Rofi selection ──
ENTRIES=""
while IFS= read -r img; do
  filename=$(basename "$img")
  name="${filename%.*}"
  thumb_path="$THUMB_DIR/${THEME}_${name}.thumb.png"
  [[ -f "$thumb_path" ]] && ENTRIES+="$filename\x00icon\x1f$thumb_path\n"
done <<< "$theme_files"

SELECTED_NAME=$(echo -e "$ENTRIES" | rofi -dmenu -show-icons -p "Select wallpaper" -theme "$ROFI_THEME")
[[ -z "$SELECTED_NAME" ]] && exit 1

SELECTED=$(find "$WALLPAPER_DIR" -type f -name "$SELECTED_NAME" | head -n 1)

pgrep -x swww-daemon >/dev/null || { swww-daemon & sleep 0.5; }
swww img "$SELECTED" --transition-type any --transition-duration 1

ln -sf "$SELECTED" "$SYMLINK"
echo "✅ Wallpaper set: $SELECTED"


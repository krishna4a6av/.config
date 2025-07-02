#!/bin/bash


CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wall-cache"
THUMB_DIR="$CACHE_DIR/thumbs"

SYMLINK="$CACHE_DIR/current_wallpaper"
THEME_SYMLINK="$CACHE_DIR/current_theme"
WALLPAPER_ROOT="$HOME/Pictures/Wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"
ROFI_CLIP="$HOME/.config/rofi/clipboard.rasi"
THEME="$1"
mkdir -p "$THUMB_DIR"


# ── Show current wallpaper path ──
if [[ "$THEME" == "current" ]]; then
  [[ -L "$SYMLINK" && -e "$SYMLINK" ]] && readlink -f "$SYMLINK" || echo "❌ No wallpaper symlink found."
  exit $?
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


# ── Select folder if theme is not passed ──
if [[ -z "$THEME" ]]; then
  FOLDERS=$(find "$WALLPAPER_ROOT" -mindepth 1 -maxdepth 1 -type d ! -iname ".*" -exec basename {} \;)
  THEME=$(echo "$FOLDERS" | rofi -dmenu -p "Select theme folder")
  [[ -z "$THEME" ]] && { echo "❌ No folder selected."; exit 1; }
fi

WALLPAPER_DIR="$WALLPAPER_ROOT/$THEME"


# ── Verify theme folder exists ──
[[ ! -d "$WALLPAPER_DIR" ]] && { echo "❌ Theme folder not found: $WALLPAPER_DIR"; exit 1; }


# ── Check for missing thumbnails and cache them ──
theme_files=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webm" \))
missing_thumbs=()


# Check which thumbnails are missing
while IFS= read -r img; do
  [[ -z "$img" ]] && continue
  filename=$(basename "$img")
  name="${filename%.*}"
  thumb_path="$THUMB_DIR/${THEME}_${name}.thumb.png"
  
  if [[ ! -f "$thumb_path" ]]; then
    missing_thumbs+=("$img")
  fi
done <<< "$theme_files"


# If there are missing thumbnails, cache them
if [[ ${#missing_thumbs[@]} -gt 0 ]]; then
  echo "🔄 Caching ${#missing_thumbs[@]} missing thumbnails for theme: $THEME"
  
  # Show caching message in main rofi 
  echo -e "🔄 Caching ${#missing_thumbs[@]} missing thumbnails for theme: $THEME\nPlease wait..." | rofi -dmenu -p "Processing" -theme $ROFI_CLIP &
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
    
    magick "$input_img"[0] -strip -resize 400x600^ -gravity center -extent 400x600 -quality 90 "$thumb_path"
    [[ "$is_video" -eq 1 ]] && rm -f "$tmp_img"
  done
  
  # Kill rofi progress window
  kill $ROFI_PID 2>/dev/null
  
  echo "✅ ${#missing_thumbs[@]} thumbnails cached for theme '$THEME'!"
fi


# ── Save theme symlink ──
ln -sfn "$WALLPAPER_DIR" "$THEME_SYMLINK"


# ── Create Rofi entries from cached thumbnails ──
ENTRIES=""
while IFS= read -r img; do
  [[ -z "$img" ]] && continue
  filename=$(basename "$img")
  name="${filename%.*}"
  thumb_path="$THUMB_DIR/${THEME}_${name}.thumb.png"
  
  # Thumbnail should already exist from caching
  [[ -f "$thumb_path" ]] && ENTRIES+="$filename\x00icon\x1f$thumb_path\n"
done < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webm" \))


# ── Show thumbnails in Rofi ──
SELECTED_NAME=$(echo -e "$ENTRIES" | rofi -dmenu -show-icons -p "Select wallpaper" -theme "$ROFI_THEME")
[[ -z "$SELECTED_NAME" ]] && { echo "❌ No wallpaper selected."; exit 1; }


# ── Find full path ──
SELECTED=$(find "$WALLPAPER_DIR" -type f -name "$SELECTED_NAME" | head -n 1)


pgrep -x swww-daemon > /dev/null || { swww-daemon & sleep 0.5; }

swww img "$SELECTED" --transition-type any --transition-duration 1
ln -sf "$SELECTED" "$SYMLINK"
echo "✅ Wallpaper set: $SELECTED"

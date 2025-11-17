#!/usr/bin/env bash
# --------------------------------------
# Waybar + SwayNC Layout Switcher (Rofi)
# --------------------------------------

set -euo pipefail

export LC_ALL=en_US.UTF-8

# --- Paths ---
WAYBAR_DIR="$HOME/.config/waybar"
SWAYNC_DIR="$HOME/.config/swaync"

WAYBAR_CONFIG_LINK="$WAYBAR_DIR/config.jsonc"
WAYBAR_STYLE_LINK="$WAYBAR_DIR/style.css"
SWAYNC_CONFIG_LINK="$SWAYNC_DIR/config.json"
SWAYNC_STYLE_LINK="$SWAYNC_DIR/style.css"

# --- Collect layouts from Waybar directory ---
layouts=()
for d in "$WAYBAR_DIR"/layout*; do
    [[ -d "$d" ]] && layouts+=("$(basename "$d")")
done

if [[ ${#layouts[@]} -eq 0 ]]; then
    echo "❌ No layouts found in $WAYBAR_DIR"
    exit 1
fi

# --- Select layout (argument or Rofi menu) ---
if [[ $# -eq 0 ]]; then
    if ! command -v rofi &>/dev/null; then
        echo "❌ Rofi not found."
        exit 1
    fi
    CHOSEN=$(printf "%s\n" "${layouts[@]}" | rofi -dmenu -p "Select layout:")
else
    CHOSEN="$1"
fi

# --- Exit if nothing selected ---
if [[ -z "${CHOSEN:-}" ]]; then
    echo "❌ No layout selected."
    exit 0
fi

WAYBAR_LAYOUT_PATH="$WAYBAR_DIR/$CHOSEN"
SWAYNC_LAYOUT_PATH="$SWAYNC_DIR/$CHOSEN"

# --- Verify layouts exist ---
if [[ ! -d "$WAYBAR_LAYOUT_PATH" ]]; then
    echo "❌ Waybar layout '$CHOSEN' not found."
    exit 1
fi

if [[ ! -d "$SWAYNC_LAYOUT_PATH" ]]; then
    echo "⚠️  No matching swaync layout for '$CHOSEN'. Skipping swaync update."
else
    # Update swaync symlinks
    rm -f "$SWAYNC_CONFIG_LINK" "$SWAYNC_STYLE_LINK"
    ln -s "$SWAYNC_LAYOUT_PATH/config.json" "$SWAYNC_CONFIG_LINK"
    ln -s "$SWAYNC_LAYOUT_PATH/style.css" "$SWAYNC_STYLE_LINK"
    echo "🔔 SwayNC layout switched to: $CHOSEN"

fi

# --- Update Waybar symlinks ---
rm -f "$WAYBAR_CONFIG_LINK" "$WAYBAR_STYLE_LINK"
ln -s "$WAYBAR_LAYOUT_PATH/config.jsonc" "$WAYBAR_CONFIG_LINK"
ln -s "$WAYBAR_LAYOUT_PATH/style.css" "$WAYBAR_STYLE_LINK"

echo "✅ Waybar layout switched to: $CHOSEN"

# Reload components
pkill waybar && waybar & disown
pkill swaync && swaync & disown

#!/usr/bin/env bash
# ----------------------------
# GTK theme switcher for Hyprland
# ----------------------------

THEME="$1"

if [[ -z "$THEME" ]]; then
    echo "Usage: setgtk <theme-name>"
    echo "Example: setgtk Kanagawa-Dark"
    echo ""
    echo "Current theme: $(gsettings get org.gnome.desktop.interface gtk-theme)"
    echo ""
    echo "Available themes:"
    (ls -1 /usr/share/themes/ 2>/dev/null; ls -1 ~/.themes/ 2>/dev/null) | sort -u
    exit 1
fi

# Check if theme exists
if [[ ! -d "/usr/share/themes/$THEME" ]] && [[ ! -d "$HOME/.themes/$THEME" ]]; then
    echo "❌ Error: Theme '$THEME' not found!"
    echo "Check available themes with: setgtk"
    exit 1
fi

# Apply theme using gsettings (this is the key command that works)
gsettings set org.gnome.desktop.interface gtk-theme "$THEME"

# Also update config files for persistence (apps started later will use these)
GTK3_CONF="$HOME/.config/gtk-3.0/settings.ini"
GTK4_CONF="$HOME/.config/gtk-4.0/settings.ini"

# Ensure directories exist
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# Function to update setting in config file
update_setting() {
    local file="$1"
    local key="$2"
    local value="$3"
    
    if [[ ! -f "$file" ]]; then
        echo "[Settings]" > "$file"
        echo "${key}=${value}" >> "$file"
    elif grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    elif grep -q "^\[Settings\]" "$file"; then
        sed -i "/^\[Settings\]/a ${key}=${value}" "$file"
    else
        sed -i "1i[Settings]\n${key}=${value}" "$file"
    fi
}

# Update both GTK3 and GTK4 configs
update_setting "$GTK3_CONF" "gtk-theme-name" "$THEME"
update_setting "$GTK4_CONF" "gtk-theme-name" "$THEME"

# Optional: Uncomment to also set icon and cursor themes
# ICON_THEME="Papirus-Dark"
# CURSOR_THEME="Bibata-Modern-Ice"
# gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
# gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
# update_setting "$GTK3_CONF" "gtk-icon-theme-name" "$ICON_THEME"
# update_setting "$GTK4_CONF" "gtk-icon-theme-name" "$ICON_THEME"

echo "✅ GTK theme set to: $THEME"
echo "   Theme applied immediately via gsettings"

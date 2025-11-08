#!/usr/bin/env bash
# ---------------------------------------------------------
# Dotfiles setup script 
# Usable for updates as well!
# ---------------------------------------------------------
# - Assumes repo is cloned and user has required software installed.
# - Checks for GNU Stow and exits if not found (no auto-install).
# - Uses `stow -t ~/.config <packages...>` for dotfile mentainence.
# - A `stow-local-ignore` file listing packages to skip can be edited as per use.
# - Backs up existing ~/.config/<package> to ~/.config/<package>_bak (if not symlink).
# - Symlinks gtk themes into ~/.themes.
# ---------------------------------------------------------

set -euo pipefail

# Colors for output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\033[36m"
RESET="\e[0m"

# ---------------------------------------------------------
echo -e "${YELLOW} ⚠️  This is a simple script to place the config file and theme files for packages and ease of mentainence.${RESET}"
echo -e "${YELLOW} It is assumed all required pcakages are already installed and does not install anything, they can installed through the package manager as per need.${RESET}"
echo -e "${YELLOW} It will backup any existing ~/.config/<package> directories (if found) as xyz_bak${RESET}"
echo -e "${YELLOW}and replace them with symlinks from this dotfiles repo.${RESET}"
echo -e "If you want to exclude specific packages from being stowed, add them to: .stow-local-ignore"
echo

read -rp "Do you want to continue? [y/N]: " consent
case "$consent" in
  [Yy]* ) echo -e "${GREEN}Proceeding with setup...${RESET}\n" ;;
  * ) echo -e "${RED}Setup aborted by user.${RESET}"; exit 0 ;;
esac

# --- Check for GNU Stow ---
if ! command -v stow &>/dev/null; then
  echo -e "${RED}✖ GNU Stow is not installed.${RESET}"
  echo "Please install it and re-run this script (e.g. 'sudo pacman -S stow' or 'sudo apt install stow')."
  exit 1
fi


DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$DOTFILES_DIR/themes"
CONFIG_DIR="$DOTFILES_DIR/config"
TARGET_THEMES="$HOME/.themes"
TARGET_CONFIG="$HOME/.config"
STOW_IGNORE_FILE="$CONFIG_DIR/stow-local-ignore"




# --- Load ignore list (if present) ---
declare -A IGNORE_MAP=()
if [[ -f "$STOW_IGNORE_FILE" ]]; then
  echo -e "${GREEN}→ Found stow-local-ignore; packages listed there will be skipped.${RESET}"
  while IFS= read -r line || [[ -n "$line" ]]; do
    # strip comments and whitespace
    pkg="${line%%#*}"
    pkg="$(echo -n "$pkg" | xargs)"   # trim
    if [[ -n "$pkg" ]]; then
      IGNORE_MAP["$pkg"]=1
    fi
  done < "$STOW_IGNORE_FILE"
fi

# --- Prepare themes symlinks ---
echo -e "${GREEN}→ Setting up themes in $TARGET_THEMES...${RESET}"
mkdir -p "$TARGET_THEMES"

if [[ -d "$THEMES_DIR" ]]; then
  for theme in "$THEMES_DIR"/*; do
    [[ -d "$theme" ]] || continue
    name=$(basename "$theme")
    target="$TARGET_THEMES/$name"

    if [[ -L "$target" ]]; then
      echo "  Removing old symlink: $name"
      rm -f "$target"
    elif [[ -e "$target" ]]; then
      echo "  Backing up existing theme: $name -> ${name}_bak"
      mv -- "$target" "${target}_bak"
    fi

    ln -s "$theme" "$target"
    echo "  Linked theme: $name"
  done
else
  echo "  No themes/ directory found in the repo; skipping themes."
fi

# --- Prepare stow packages list (subdirectories inside config/) ---
echo -e "\n${GREEN}→ Preparing stow packages from $CONFIG_DIR...${RESET}"
if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "  No config/ directory found in the repo; nothing to stow."
  echo -e "${GREEN}✅ Done.${RESET}"
  exit 0
fi

mapfile -t PACKAGES < <(find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

# Filter out ignored packages and build list for stow
PACKAGES_TO_STOW=()
for pkg in "${PACKAGES[@]}"; do
  if [[ -n "${IGNORE_MAP[$pkg]:-}" ]]; then
    echo "  Skipping (ignored): $pkg"
    continue
  fi
  PACKAGES_TO_STOW+=("$pkg")
done

if [[ ${#PACKAGES_TO_STOW[@]} -eq 0 ]]; then
  echo "  No packages to stow (all skipped or none present)."
else
  echo -e "\n${YELLOW}→ Backing up existing ~/.config/<package> (non-symlink) before stowing...${RESET}"
  for pkg in "${PACKAGES_TO_STOW[@]}"; do
    target="$TARGET_CONFIG/$pkg"

    if [[ -L "$target" ]]; then
      echo "  Removing old symlink: $pkg"
      rm -f "$target"
    elif [[ -e "$target" ]]; then
      bak="${target}_bak"
      # If bak already exists, append timestamp to avoid overwrite
      if [[ -e "$bak" || -L "$bak" ]]; then
        ts=$(date +%Y%m%dT%H%M%S)
        bak="${target}_bak_$ts"
      fi
      echo "  Backing up existing config: $pkg -> $(basename "$bak")"
      mv -- "$target" "$bak"
    fi
  done

  # --- Run stow from inside config/ using explicit package list ---
  echo -e "\n${GREEN}→ Running GNU Stow for packages: ${PACKAGES_TO_STOW[*]}${RESET}"
  pushd "$CONFIG_DIR" >/dev/null
  # use -v to show actions, remove if too noisy
  stow -t "$TARGET_CONFIG" .
  popd >/dev/null

  echo -e "\n${GREEN}✅ Stow complete.${RESET}"
  echo -e "${YELLOW}Backups (if any) are in ~/.config and named <package>_bak or <package>_bak_<timestamp>.${RESET}"
fi

echo -e "\n${GREEN}All done — your dotfiles have been applied.${RESET}"
echo -e "${YELLOW}Note: To change which packages are stowed, edit ${STOW_IGNORE_FILE} (one package name per line) and re-run this script.${RESET}"


# Ask user if they want to clone wallpapers
read -rp "Do you want to clone the wallpapers repository as well(around 2gigs)? (Y/n): " clone_wp
if [[ "$clone_wp" =~ ^[Yy]$ ]]; then
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    if [[ -d "$WALLPAPER_DIR" ]]; then
        echo -e "${YELLOW}Wallpapers directory already exists. Backing it up...${RESET}"
        mv "$WALLPAPER_DIR" "${WALLPAPER_DIR}_bak"
    fi
    echo -e "${CYAN}→ Cloning wallpaper repo...${RESET}"
    git clone https://github.com/krishna4a6av/Wallpapers.git "$WALLPAPER_DIR"
    echo -e "${GREEN}✅ Wallpapers cloned to $WALLPAPER_DIR${RESET}"
else
    echo -e "${YELLOW}Skipped wallpaper cloning.${RESET}"
    echo -e "Wallpaper needs to be added in ~/Pictures/Wallpapers/ dir for the wallpaper script"
    echo -e "You can either add the wallpapers there with folder with same name as themes or change path in wallpaper script"
    echo -e "My wallpaper repo is here:https://github.com/krishna4a6av/Wallpapers.git  "
fi

echo -e "\n${CYAN} --------------- Hope you enjoy the dots! --------------- ${RESET}"


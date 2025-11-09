#!/usr/bin/env bash
# ---------------------------------------------------------
# Dotfiles Setup Script
# Usable for updates as well!
# ---------------------------------------------------------
# - Assumes the repo is cloned and user has required software installed.
# - Checks for GNU Stow and exits if not found (no auto-install).
# - Uses `stow -t ~/.config .` for dotfile maintenance.
# - Packages to skip can be listed in `config/stow-local-ignore`.
# - Backs up existing ~/.config/<package> to ~/.config/<package>_bak (if not symlink).
# - Symlinks GTK themes into ~/.themes.
# - Symlinks ~/Scripts and makes scripts executable.
# ---------------------------------------------------------

set -euo pipefail

# ---------------------------------------------------------
# Colors for output
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

# ---------------------------------------------------------
# Introduction and warning
echo -e "${YELLOW}⚠️ This script places config and theme files for easy and faster maintenance. Using symlinks.${RESET}"
echo -e "${YELLOW}   It assumes all required packages are already installed. And does not install anything.${RESET}"
echo -e "${YELLOW}   Existing ~/.config/<package> directories will be backed up (e.g. <package>_bak).${RESET}"
echo -e "${YELLOW}   If you want to exclude specific packages, list them in:${RESET} config/stow-local-ignore"
echo

read -rp "Do you want to continue? [y/N]: " consent
case "$consent" in
  [Yy]* ) echo -e "${GREEN}Proceeding with setup...${RESET}\n" ;;
  * ) echo -e "${RED}Setup aborted by user.${RESET}"; exit 0 ;;
esac

# ---------------------------------------------------------
# Check for GNU Stow
if ! command -v stow &>/dev/null; then
  echo -e "${RED}✖ GNU Stow is not installed.${RESET}"
  echo "Please install it and re-run this script (e.g. 'sudo pacman -S stow' or 'sudo apt install stow')."
  exit 1
fi

# ---------------------------------------------------------
# Directory setup
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"
THEMES_DIR="$DOTFILES_DIR/themes"
TARGET_CONFIG="$HOME/.config"
TARGET_THEMES="$HOME/.themes"
SCRIPTS_DIR="$HOME/Scripts"
STOW_IGNORE_FILE="$CONFIG_DIR/stow-local-ignore"

# ---------------------------------------------------------
# Load stow-local-ignore if present
declare -A IGNORE_MAP=()
if [[ -f "$STOW_IGNORE_FILE" ]]; then
  echo -e "${GREEN}→ Found stow-local-ignore; packages listed there will be skipped.${RESET}"
  while IFS= read -r line || [[ -n "$line" ]]; do
    pkg="${line%%#*}"   # remove comments
    pkg="$(echo -n "$pkg" | xargs)"   # trim whitespace
    [[ -n "$pkg" ]] && IGNORE_MAP["$pkg"]=1
  done < "$STOW_IGNORE_FILE"
fi

# ---------------------------------------------------------
# Symlink GTK themes
echo -e "\n${CYAN}→ Setting up themes in $TARGET_THEMES...${RESET}"
mkdir -p "$TARGET_THEMES"

if [[ -d "$THEMES_DIR" ]]; then
  for theme in "$THEMES_DIR"/*; do
    [[ -d "$theme" ]] || continue
    name=$(basename "$theme")
    target="$TARGET_THEMES/$name"

    if [[ -L "$target" ]]; then
      rm -f "$target"
      echo "  Removed old symlink: $name"
    elif [[ -e "$target" ]]; then
      mv -- "$target" "${target}_bak"
      echo "  Backed up existing theme: $name → ${name}_bak"
    fi

    ln -s "$theme" "$target"
    echo "  Linked theme: $name"
  done
else
  echo "  No themes/ directory found; skipping theme setup."
fi

# ---------------------------------------------------------
# Prepare and run stow
echo -e "\n${CYAN}→ Preparing stow packages from $CONFIG_DIR...${RESET}"
if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "  No config/ directory found; nothing to stow."
  echo -e "${GREEN}✅ Done.${RESET}"
  exit 0
fi

mapfile -t PACKAGES < <(find "$CONFIG_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

PACKAGES_TO_STOW=()
for pkg in "${PACKAGES[@]}"; do
  if [[ -n "${IGNORE_MAP[$pkg]:-}" ]]; then
    echo "  Skipping (ignored): $pkg"
  else
    PACKAGES_TO_STOW+=("$pkg")
  fi
done

if [[ ${#PACKAGES_TO_STOW[@]} -eq 0 ]]; then
  echo "  No packages to stow (all skipped or none present)."
else
  echo -e "\n${YELLOW}→ Backing up existing ~/.config/<package> (non-symlink) before stowing...${RESET}"
  for pkg in "${PACKAGES_TO_STOW[@]}"; do
    target="$TARGET_CONFIG/$pkg"
    if [[ -L "$target" ]]; then
      rm -f "$target"
      echo "  Removed old symlink: $pkg"
    elif [[ -e "$target" ]]; then
      bak="${target}_bak"
      [[ -e "$bak" || -L "$bak" ]] && bak="${target}_bak_$(date +%Y%m%dT%H%M%S)"
      mv -- "$target" "$bak"
      echo "  Backed up: $pkg → $(basename "$bak")"
    fi
  done

  echo -e "\n${GREEN}→ Running GNU Stow for packages...${RESET}"
  pushd "$CONFIG_DIR" >/dev/null
  stow -t "$TARGET_CONFIG" .
  popd >/dev/null

  echo -e "\n${GREEN}✅ Stow complete.${RESET}"
  echo -e "${YELLOW}Backups (if any) are in ~/.config as <package>_bak or <package>_bak_<timestamp>.${RESET}"
fi

# ---------------------------------------------------------
# Scripts folder
if [[ -d "$DOTFILES_DIR/Scripts" ]]; then
  echo -e "\n${CYAN}→ Setting up Scripts folder...${RESET}"
  if [[ -e "$SCRIPTS_DIR" && ! -L "$SCRIPTS_DIR" ]]; then
    mv "$SCRIPTS_DIR" "${SCRIPTS_DIR}_bak"
    echo -e "${YELLOW}Backed up existing ~/Scripts → ~/Scripts_bak${RESET}"
  fi
  ln -sf "$DOTFILES_DIR/Scripts" "$SCRIPTS_DIR"
  chmod +x "$SCRIPTS_DIR"/* 2>/dev/null
  echo -e "${GREEN}✅ Linked Scripts → ~/Scripts and made all scripts executable.${RESET}"
else
  echo -e "${YELLOW}No Scripts folder found; skipping.${RESET}"
fi

# ---------------------------------------------------------
# Make themer scripts executable
if [[ -d "$DOTFILES_DIR/themer" ]]; then
  echo -e "\n${CYAN}→ Making themer scripts executable...${RESET}"
  chmod +x "$DOTFILES_DIR/themer"/* 2>/dev/null
  echo -e "${GREEN}✅ All scripts in themer/ are now executable.${RESET}"
fi

# ---------------------------------------------------------
# Wallpapers option
echo
read -rp "Do you want to clone the wallpapers repository as well (around 2 GB)? [y/N]: " clone_wp
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
  echo -e "Wallpapers should be placed in ~/Pictures/Wallpapers/, or update the wallpaper script accordingly."
  echo -e "Repo (optional): ${CYAN}https://github.com/krishna4a6av/Wallpapers.git${RESET}"
fi

# ---------------------------------------------------------
echo -e "\n${GREEN}🎉 All done — your dotfiles have been applied successfully.${RESET}"
echo -e "${YELLOW}To change which packages are stowed, edit:${RESET} ${CYAN}$STOW_IGNORE_FILE${RESET}"
echo -e "\n${CYAN}--------------- Hope you enjoy the dots! ---------------${RESET}"


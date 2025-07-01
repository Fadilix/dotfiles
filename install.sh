#!/bin/bash

# Exit on any error
set -e

# colors to make the cli cool a little bit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RESET='\033[0m'

# Configuration folders to backup and install
folders=(
  "cava"
  "hypr"
  "kitty"
  "nvim"
  "rofi"
  "swaync"
  "waybar"
)

# Packages to install via yay
packages_to_install=(
  "cava"
  "kitty"
  "neovim"
  "rofi"
  "swaync"
  "waybar"
)

# Error handling function
error_exit() {
  echo -e "${RED}Error: $1${RESET}" >&2
  exit 1
}

backup() {
  echo -e "${GREEN}Starting backup of configuration folders...${RESET}"
  for folder in "${folders[@]}"; do
    # check if the folder exists
    if [ -d "$HOME/.config/$folder" ]; then
      # create backup directory if it doesn't exist
      mkdir -p "$HOME/backup"
      # copy the folder to the backup directory
      cp -r "$HOME/.config/$folder" "$HOME/backup/" || error_exit "Failed to copy $HOME/.config/$folder"
      echo -e "${GREEN}Backed up $folder to $HOME/backup/$folder${RESET}"
    else
      echo -e "${YELLOW}Folder $folder does not exist, skipping.${RESET}"
    fi
  done
}

copy_folders() {
  echo -e "${GREEN}Starting installation of configuration folders...${RESET}"
  for folder in "${folders[@]}"; do
    # check if the folder exists in the repository
    if [ -d "$PWD/$folder" ]; then
      # create target directory if it doesn't exist
      mkdir -p "$HOME/.config/$folder"
      # copy the folder to the target directory
      cp -r "$PWD/$folder/." "$HOME/.config/$folder/" || error_exit "Failed to copy $PWD/$folder to $HOME/.config/$folder"
      echo -e "${GREEN}Installed $folder to $HOME/.config/$folder${RESET}"
    else
      echo -e "${YELLOW}Folder $folder does not exist in the repository, skipping.${RESET}"
    fi
  done
}

install_packages() {
  echo -e "${GREEN}Starting installation of packages...${RESET}"

  # Check if yay is installed
  if ! command -v yay &>/dev/null; then
    echo -e "${RED}Error: yay is not installed. Please install yay first.${RESET}"
    return 1
  fi

  for package in "${packages_to_install[@]}"; do
    # Check if package is already installed via pacman/yay
    if yay -Qq "$package" &>/dev/null; then
      echo -e "${YELLOW}$package is already installed, skipping.${RESET}"
    else
      echo -e "${GREEN}Installing $package...${RESET}"
      if yay -S --noconfirm "$package"; then
        echo -e "${GREEN}$package installed successfully.${RESET}"
      else
        echo -e "${RED}Failed to install $package.${RESET}"
      fi
    fi
  done
}

main() {
  echo -e "${BLUE}Starting the installation script...${RESET}"
  echo -e "${BLUE}This script will backup your existing configs and install new ones.${RESET}"

  # Ask for confirmation
  read -p "Do you want to continue? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${RESET}"
    exit 0
  fi

  # Backup existing configuration folders
  backup

  # Copy new configuration folders
  copy_folders

  # Install packages
  install_packages

  ~/.config/hypr/scripts/Refresh.sh

  echo -e "${GREEN}Installation completed successfully!${RESET}"
}

main


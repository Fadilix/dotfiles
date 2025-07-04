#!/bin/bash

set -e

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Status symbols
CHECK="✓"
CROSS="✗"
ARROW=">"
INFO="i"

# Config directories to process
folders=(
  "cava"
  "hypr"
  "kitty"
  "nvim"
  "rofi"
  "swaync"
  "waybar"
  "tmux"
)

# AUR packages
packages_to_install=(
  "cava"
  "kitty"
  "neovim"
  "rofi"
  "swaync"
  "waybar"
  "fastfetch"
  "zoxide"
  "fzf"
  "cmatrix"
  "tmux"
)

error_exit() {
  echo -e "\n${RED}${CROSS} Error: $1${RESET}" >&2
  exit 1
}

# Progress bar with percentage
show_progress() {
  local current=$1
  local total=$2
  local percentage=$((current * 100 / total))
  local dots=$((current * 20 / total))

  printf "\r${CYAN}Progress: ["
  for ((i = 0; i < dots; i++)); do printf "#"; done
  for ((i = dots; i < 20; i++)); do printf "."; done
  printf "] ${WHITE}%d%% ${DIM}(%d/%d)${RESET}" $percentage $current $total
}

print_header() {
  local title="$1"
  echo -e "\n${BOLD}${BLUE}===========================================${RESET}"
  echo -e "${BOLD}${WHITE}  $title${RESET}"
  echo -e "${BOLD}${BLUE}===========================================${RESET}"
}

print_success() {
  echo -e "${GREEN}${CHECK} $1${RESET}"
}

print_warning() {
  echo -e "${YELLOW}! $1${RESET}"
}

print_info() {
  echo -e "${CYAN}${ARROW} $1${RESET}"
}

backup() {
  print_header "Backing Up Configuration"

  local total=${#folders[@]}
  local current=0

  for folder in "${folders[@]}"; do
    current=$((current + 1))
    show_progress $current $total

    if [ -d "$HOME/.config/$folder" ]; then
      mkdir -p "$HOME/backup"
      cp -r "$HOME/.config/$folder" "$HOME/backup/" || error_exit "Failed to backup $folder"
      echo -e "\n${GREEN}${CHECK} Backed up: $folder${RESET}"
    else
      echo -e "\n${YELLOW}! Folder $folder not found, skipping${RESET}"
    fi
    sleep 0.1
  done

  echo -e "\n"
  print_info "Backing up .zshrc..."
  if [ -f "$HOME/.zshrc" ]; then
    mkdir -p "$HOME/backup"
    cp "$HOME/.zshrc" "$HOME/backup/" || error_exit "Failed to backup .zshrc"
    print_success "Backed up .zshrc"
  else
    print_warning ".zshrc not found, skipping"
  fi
}

copy_folders() {
  print_header "Installing Configurations"

  local total=${#folders[@]}
  local current=0

  for folder in "${folders[@]}"; do
    current=$((current + 1))
    show_progress $current $total

    if [ -d "$PWD/$folder" ]; then
      mkdir -p "$HOME/.config/$folder"
      cp -r "$PWD/$folder/." "$HOME/.config/$folder/" || error_exit "Failed to install $folder"
      echo -e "\n${GREEN}${CHECK} Installed: $folder${RESET}"
    else
      echo -e "\n${YELLOW}! Source folder $folder not found, skipping${RESET}"
    fi
    sleep 0.1
  done

  # Handle .zshrc installation
  print_info "Installing .zshrc..."
  if [ -f "$PWD/.zshrc" ]; then
    # Remove existing .zshrc if it exists
    [ -f "$HOME/.zshrc" ] && rm "$HOME/.zshrc"

    # Copy the zshrc from dotfiles to user's home directory
    cp "$PWD/.zshrc" "$HOME/.zshrc" || error_exit "Failed to install .zshrc"
    print_success "Installed .zshrc"

    # Source the new .zshrc
    print_info "Sourcing .zshrc..."
    source "$HOME/.zshrc" || print_warning "Failed to source .zshrc (this is normal in some cases)"
  else
    print_warning ".zshrc not found in dotfiles, skipping"
  fi

  echo
}

install_packages() {
  print_header "Installing Packages"

  if ! command -v yay &>/dev/null; then
    echo -e "${RED}${CROSS} yay not found. Please install yay first.${RESET}"
    return 1
  fi

  local total=${#packages_to_install[@]}
  local current=0
  local installed=0
  local skipped=0

  for package in "${packages_to_install[@]}"; do
    current=$((current + 1))
    show_progress $current $total

    if yay -Qq "$package" &>/dev/null; then
      echo -e "\n${YELLOW}! $package already installed${RESET}"
      skipped=$((skipped + 1))
    else
      echo -e "\n${CYAN}${ARROW} Installing $package...${RESET}"
      if yay -S --noconfirm "$package"; then
        print_success "$package installed"
        installed=$((installed + 1))
      else
        echo -e "${RED}${CROSS} Failed to install $package${RESET}"
      fi
    fi
    sleep 0.1
  done

  echo -e "\n${CYAN}${INFO} Summary: ${GREEN}$installed installed${RESET}, ${YELLOW}$skipped skipped${RESET}"
}

main() {
  clear

  echo -e "${BOLD}${PURPLE}"
  echo "==========================================="
  echo "    Fadilix Hyprland Configuration Installer"
  echo "          https://github.com/Fadilix"
  echo "==========================================="
  echo -e "${RESET}"
  echo -e "${DIM}This will backup existing configs and install new ones${RESET}\n"

  echo -e "${BOLD}${WHITE}Configuration folders:${RESET}"
  for folder in "${folders[@]}"; do
    echo -e "  ${CYAN}${ARROW}${RESET} $folder"
  done

  echo -e "\n${BOLD}${WHITE}Packages to install (${#packages_to_install[@]} total):${RESET}"
  for package in "${packages_to_install[@]}"; do
    echo -e "  ${CYAN}${ARROW}${RESET} $package"
  done

  echo -e "\n${BOLD}${YELLOW}! Warning: This will backup and replace your configs!${RESET}"
  echo -e "${WHITE}Continue? ${DIM}(y/N):${RESET} "
  read -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${RESET}"
    exit 0
  fi

  echo -e "\n${GREEN}${CHECK} Starting installation...${RESET}"

  backup
  copy_folders
  install_packages

  print_header "Finalizing Setup"
  print_info "Running refresh script..."
  ~/.config/hypr/scripts/Refresh.sh

  echo -e "\n${BOLD}${GREEN}"
  echo "==========================================="
  echo "     Installation Complete!"
  echo "==========================================="
  echo -e "${RESET}"
  echo -e "${GREEN}${CHECK} All done! Please close the terminal!${RESET}\n"
}

main

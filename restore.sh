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

# Config directories to restore
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

restore_configs() {
  print_header "Restoring Configuration Files"

  local total=${#folders[@]}
  local current=0
  local restored=0
  local skipped=0

  for folder in "${folders[@]}"; do
    current=$((current + 1))
    show_progress $current $total

    if [ -d "$HOME/backup/$folder" ]; then
      cp -r "$HOME/backup/$folder" "$HOME/.config/" || error_exit "Failed to restore $folder"
      echo -e "\n${GREEN}${CHECK} Restored: $folder${RESET}"
      restored=$((restored + 1))
    else
      echo -e "\n${YELLOW}! Backup for $folder not found, skipping${RESET}"
      skipped=$((skipped + 1))
    fi
    sleep 0.1
  done

  echo -e "\n"
  print_info "Restoring .zshrc..."
  if [ -f "$HOME/backup/.zshrc" ]; then
    cp "$HOME/backup/.zshrc" "$HOME/" || error_exit "Failed to restore .zshrc"
    print_success "Restored .zshrc"
    restored=$((restored + 1))
  else
    print_warning ".zshrc backup not found, skipping"
    skipped=$((skipped + 1))
  fi

  echo -e "\n${CYAN}${INFO} Summary: ${GREEN}$restored restored${RESET}, ${YELLOW}$skipped skipped${RESET}"
}

main() {
  clear

  echo -e "${BOLD}${PURPLE}"
  echo "==========================================="
  echo "    Fadilix Hyprland Configuration Restore"
  echo "          https://github.com/Fadilix"
  echo "==========================================="
  echo -e "${RESET}"
  echo -e "${DIM}This will restore your backed up configurations${RESET}\n"

  # Check if backup directory exists
  if [ ! -d "$HOME/backup" ]; then
    echo -e "${RED}${CROSS} No backup directory found at $HOME/backup${RESET}"
    echo -e "${DIM}Run install.sh first to create backups${RESET}"
    exit 1
  fi

  echo -e "${BOLD}${WHITE}Configuration folders to restore:${RESET}"
  for folder in "${folders[@]}"; do
    if [ -d "$HOME/backup/$folder" ]; then
      echo -e "  ${GREEN}${CHECK}${RESET} $folder"
    else
      echo -e "  ${DIM}${CROSS} $folder (backup not found)${RESET}"
    fi
  done

  echo -e "\n${BOLD}${YELLOW}! Warning: This will overwrite your current configs!${RESET}"
  echo -e "${WHITE}Continue? ${DIM}(y/N):${RESET} "
  read -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restore cancelled${RESET}"
    exit 0
  fi

  echo -e "\n${GREEN}${CHECK} Starting restore...${RESET}"

  restore_configs

  echo -e "\n${BOLD}${GREEN}"
  echo "==========================================="
  echo "     Restore Complete!"
  echo "==========================================="
  echo -e "${RESET}"
  echo -e "${GREEN}${CHECK} All done! Please restart your session${RESET}\n"
}

main


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

# Config directories to fetch
folders=(
  "cava"
  "hypr"
  "kitty"
  "nvim"
  "rofi"
  "swaync"
  "waybar"
  "tmux"
  "yazi",
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

fetch_configs() {
  print_header "Fetching Latest Configurations"

  local total=${#folders[@]}
  local current=0
  local fetched=0
  local skipped=0

  for folder in "${folders[@]}"; do
    current=$((current + 1))
    show_progress $current $total

    if [ -d "$HOME/.config/$folder" ]; then
      # Remove existing folder in repo if it exists
      if [ -d "$PWD/$folder" ]; then
        rm -rf "$PWD/$folder" || error_exit "Failed to remove old $folder"
      fi

      # Copy latest config from ~/.config
      cp -r "$HOME/.config/$folder" "$PWD/" || error_exit "Failed to fetch $folder"
      cp "$HOME/.zshrc" "$PWD/"
      echo -e "\n${GREEN}${CHECK} Fetched: $folder${RESET}"
      fetched=$((fetched + 1))
    else
      echo -e "\n${YELLOW}! Config $folder not found in ~/.config, skipping${RESET}"
      skipped=$((skipped + 1))
    fi
    sleep 0.1
  done

  echo -e "\n${CYAN}${INFO} Summary: ${GREEN}$fetched fetched${RESET}, ${YELLOW}$skipped skipped${RESET}"
}

main() {
  clear

  echo -e "${BOLD}${PURPLE}"
  echo "==========================================="
  echo "    Fadilix Configuration Fetcher"
  echo "          https://github.com/Fadilix"
  echo "==========================================="
  echo -e "${RESET}"
  echo -e "${DIM}This will fetch your latest configs from ~/.config${RESET}\n"

  echo -e "${BOLD}${WHITE}Configuration folders to fetch:${RESET}"
  for folder in "${folders[@]}"; do
    if [ -d "$HOME/.config/$folder" ]; then
      echo -e "  ${GREEN}${CHECK}${RESET} $folder"
    else
      echo -e "  ${DIM}${CROSS} $folder (not found in ~/.config)${RESET}"
    fi
  done

  echo -e "\n${BOLD}${YELLOW}! Warning: This will overwrite existing configs in this repo!${RESET}"
  echo -e "${WHITE}Continue? ${DIM}(y/N):${RESET} "
  read -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Fetch cancelled${RESET}"
    exit 0
  fi

  echo -e "\n${GREEN}${CHECK} Starting fetch...${RESET}"

  fetch_configs

  echo -e "\n${BOLD}${GREEN}"
  echo "==========================================="
  echo "     Fetch Complete!"
  echo "==========================================="
  echo -e "${RESET}"
  echo -e "${GREEN}${CHECK} All done! Repository updated with latest configs${RESET}\n"
}

main

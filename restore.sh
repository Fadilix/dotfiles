#!/bin/bash

# this script is to reverse the @install.sh to backup the backup files and folders
# Exit on any error
set -e
# colors to make the cli cool a little bit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RESET='\033[0m'

folders=(
    "cava"
    "hypr"
    "kitty"
    "nvim"
    "rofi"
    "swaync"
)

main () {
    echo -e "${GREEN}Starting backup of configuration folders...${RESET}"
    for folder in "${folders[@]}"; do
        # check if the folder exists in the backup directory
        if [ -d "$HOME/backup/$folder" ]; then
            # copy the folder from the backup directory to the target directory
            cp -r "$HOME/backup/$folder" "$HOME/.config/" || { echo -e "${RED}Failed to restore $folder${RESET}"; exit 1; }
            echo -e "${GREEN}Restored $folder from $HOME/backup/$folder${RESET}"
        else
            echo -e "${YELLOW}Backup for $folder does not exist, skipping.${RESET}"
        fi
    done
}

main
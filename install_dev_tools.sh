#!/bin/bash

# Bash script to install essential development tools on Arch Linux

# Check if running as root
if [[ $EUID -eq 0 ]]; then
  echo "This script should not be run as root. Please run as a regular user with sudo privileges."
  exit 1
fi

# List of official Arch Linux repository packages
PACMAN_PKGS=(
  base-devel
  meson
  ninja
  pahole
  git
  mercurial
  python
  nodejs
  go
  jdk-openjdk
  lua
  luajit
  typescript
  pyenv
  python-pip
  python-build
  python-installer
  python-setuptools
  python-wheel
  node-gyp
  npm
  vim
  neovim
  tree-sitter
  tree-sitter-c
  tree-sitter-lua
  tree-sitter-markdown
  tree-sitter-query
  tree-sitter-vim
  tree-sitter-vimdoc
  texinfo
  perl
  perl-error
  perl-timedate
  perl-mailtools
  reflector
)

# List of AUR packages
AUR_PKGS=(
  yay-bin
  visual-studio-code-bin
  zen-browser-bin
)

echo "Updating system package database..."
sudo pacman -Syu --noconfirm || {
  echo "Failed to update package database"
  exit 1
}

echo "Installing official repository packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || {
  echo "Failed to install some packages"
  exit 1
}

# Check if yay is installed for AUR packages
if ! command -v yay &>/dev/null; then
  echo "yay AUR helper is not installed. Installing yay..."
  sudo pacman -S --needed --noconfirm git base-devel || {
    echo "Failed to install dependencies for yay"
    exit 1
  }
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  cd /tmp/yay-bin
  makepkg -si --noconfirm || {
    echo "Failed to install yay"
    exit 1
  }
  cd -
fi

echo "Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}" || {
  echo "Failed to install some AUR packages"
  exit 1
}

echo "All essential development tools installed successfully!"

#!/bin/bash
# setup-tlp.sh — Quick script to install and initialize TLP for battery optimization

set -e

echo ">>> Installing TLP..."
yay -S --noconfirm tlp

echo ">>> Starting and enabling TLP..."
sudo tlp start
sudo systemctl enable tlp.service

echo ">>> Masking conflicting services..."
sudo systemctl mask systemd-rfkill.socket
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask power-profiles-daemon.service

echo ">>> Restarting TLP to apply changes..."
sudo systemctl restart tlp

echo ">>> Done!"
echo "You can check battery status with:"
echo "  sudo tlp-stat -s"

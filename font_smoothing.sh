#!/usr/bin/env bash
set -euo pipefail

# 1. Install quality fonts
sudo pacman -Sy --noconfirm \
  noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra \
  ttf-dejavu ttf-liberation ttf-roboto \
  ttf-jetbrains-mono ttf-fira-code

# 2. Enable fontconfig tweaks
cd /etc/fonts/conf.d
sudo ln -sf ../conf.avail/10-sub-pixel-rgb.conf .
sudo ln -sf ../conf.avail/10-hinting-slight.conf .
sudo ln -sf ../conf.avail/11-lcdfilter-default.conf .
sudo ln -sf ../conf.avail/70-no-bitmaps.conf .

# 3. Create global local.conf for rendering settings
sudo tee /etc/fonts/local.conf <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign"><bool>true</bool></edit>
    <edit name="hinting" mode="assign"><bool>true</bool></edit>
    <edit name="rgba" mode="assign"><const>rgb</const></edit>
    <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
    <edit name="lcdfilter" mode="assign"><const>lcddefault</const></edit>
  </match>
</fontconfig>
EOF

# 4. Optional: set Xft settings in ~/.Xresources
tee -a ~/.Xresources <<'EOF'

! Xft font smoothing
Xft.dpi:        96
Xft.antialias:  true
Xft.hinting:    true
Xft.hintstyle:  hintslight
Xft.rgba:       rgb
Xft.lcdfilter:  lcddefault
EOF

# Load Xft settings immediately
xrdb -merge ~/.Xresources

# 5. Rebuild font cache
sudo fc-cache -f

echo "✅ Font smoothing setup completed."
echo "Please log out and back in (or restart X/Wayland) to fully apply."

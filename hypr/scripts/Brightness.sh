#!/bin/bash
# Script to manage the backlight of the computer

iDIR="$HOME/.config/swaync/icons"
notification_timeout=1000

# Get brightness
get_backlight() {
  echo $(brightnessctl -m | cut -d, -f4)
}

# Get icons
get_icon() {
  current=$(get_backlight | sed 's/%//')
  if [ "$current" -le "20" ]; then
    icon="$iDIR/brightness-20.png"
  elif [ "$current" -le "40" ]; then
    icon="$iDIR/brightness-40.png"
  elif [ "$current" -le "60" ]; then
    icon="$iDIR/brightness-60.png"
  elif [ "$current" -le "80" ]; then
    icon="$iDIR/brightness-80.png"
  else
    icon="$iDIR/brightness-100.png"
  fi
}

# Change brightness. No desktop notification: the latto island shows its own
# brightness indicator.
change_backlight() {
  if brightnessctl set "$1" -n; then
    qs ipc -p "$HOME/.config/quickshell/latto" call hud brightness >/dev/null 2>&1 || true
  fi
}

# Execute accordingly
case "$1" in
"--get")
  get_backlight
  ;;
"--inc")
  change_backlight "+3%"
  ;;
"--dec")
  change_backlight "3%-"
  ;;
*)
  get_backlight
  ;;
esac

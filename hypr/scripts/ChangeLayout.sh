#!/usr/bin/env bash
# Toggle the active Hyprland layout. Keybinds live in lua/bindings.lua and are left alone here.

set -euo pipefail

notif="$HOME/.config/swaync/images/bell.png"
layout=$(hyprctl getoption general:layout -j | jq -r '.str')

case "$layout" in
  master)
    hyprctl eval 'hl.config({ general = { layout = "dwindle" } })'
    notify-send -e -u low -i "$notif" "Dwindle Layout"
    ;;
  dwindle)
    hyprctl eval 'hl.config({ general = { layout = "master" } })'
    notify-send -e -u low -i "$notif" "Master Layout"
    ;;
esac

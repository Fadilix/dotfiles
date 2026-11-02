#!/usr/bin/env bash
# Toggle the active Hyprland layout and its layout-specific keybindings.

set -euo pipefail

notif="$HOME/.config/swaync/images/bell.png"
layout=$(hyprctl getoption general:layout -j | jq -r '.str')

case "$layout" in
  master)
    hyprctl eval 'hl.config({ general = { layout = "dwindle" } }); hl.unbind("SUPER + J"); hl.unbind("SUPER + K"); hl.bind("SUPER + J", hl.dsp.layout("cyclenext")); hl.bind("SUPER + K", hl.dsp.layout("cycleprev")); hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'
    notify-send -e -u low -i "$notif" "Dwindle Layout"
    ;;
  dwindle)
    hyprctl eval 'hl.config({ general = { layout = "master" } }); hl.unbind("SUPER + J"); hl.unbind("SUPER + K"); hl.unbind("SUPER + O"); hl.bind("SUPER + J", hl.dsp.layout("cyclenext")); hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))'
    notify-send -e -u low -i "$notif" "Master Layout"
    ;;
esac

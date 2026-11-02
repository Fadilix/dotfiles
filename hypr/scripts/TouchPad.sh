#!/usr/bin/env bash
# Toggle the configured touchpad using Hyprland's Lua device API.

set -euo pipefail

device="asue1209:00-04f3:319f-touchpad"
notif="$HOME/.config/swaync/images/bell.png"
status_file="${XDG_RUNTIME_DIR:?}/touchpad.status"

if [[ -f "$status_file" ]] && [[ "$(<"$status_file")" == true ]]; then
  enabled=false
  message="Disabling touchpad"
else
  enabled=true
  message="Enabling touchpad"
fi

hyprctl eval "hl.device({ name = \"$device\", enabled = $enabled })"
printf '%s' "$enabled" > "$status_file"
notify-send -u low -i "$notif" "$message"

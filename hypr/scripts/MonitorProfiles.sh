#!/usr/bin/env bash
# Choose a native Lua monitor profile and reload Hyprland.

set -euo pipefail

config_dir="$HOME/.config/hypr"
profiles_dir="$config_dir/lua/monitor_profiles"
active_file="$config_dir/lua/active_monitor_profile.lua"
rofi_theme="$HOME/.config/rofi/stellar-Monitors.rasi"

if pidof rofi >/dev/null 2>&1; then pkill rofi; fi

mapfile -t profiles < <(find "$profiles_dir" -maxdepth 1 -type f -name '*.lua' -printf '%f\n' | sed 's/\.lua$//' | sort -V)
[[ ${#profiles[@]} -gt 0 ]] || { notify-send "Monitors" "No Lua profiles found"; exit 1; }

chosen=$(printf '%s\n' "${profiles[@]}" | rofi -i -dmenu -config "$rofi_theme" -mesg "Choose a monitor profile")
[[ -n "$chosen" ]] || exit 0

source_file="$profiles_dir/$chosen.lua"
luac -p "$source_file"
backup_file=$(mktemp)
had_active=false
if [[ -f "$active_file" ]]; then cp "$active_file" "$backup_file"; had_active=true; fi
cp "$source_file" "$active_file"
hyprctl reload >/dev/null || true
errors=$(hyprctl configerrors)
if [[ -n "$errors" ]]; then
  if $had_active; then cp "$backup_file" "$active_file"; else rm -f "$active_file"; fi
  notify-send "Monitors" "Profile failed to load; restored the previous Lua monitor settings"
  hyprctl reload >/dev/null || true
  rm -f "$backup_file"
  exit 1
fi
rm -f "$backup_file"

notify-send -u low "Monitors" "Loaded $chosen"

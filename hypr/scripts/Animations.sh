#!/usr/bin/env bash
# Choose a native Lua animation preset and reload Hyprland.

set -euo pipefail

config_dir="$HOME/.config/hypr"
presets_dir="$config_dir/lua/animation_presets"
active_file="$config_dir/lua/active_animations.lua"
rofi_theme="$HOME/.config/rofi/stellar-Animations.rasi"

if pidof rofi >/dev/null 2>&1; then pkill rofi; fi

mapfile -t presets < <(find "$presets_dir" -maxdepth 1 -type f -name '*.lua' -printf '%f\n' | sed 's/\.lua$//' | sort -V)
[[ ${#presets[@]} -gt 0 ]] || { notify-send "Animations" "No Lua presets found"; exit 1; }

chosen=$(printf '%s\n' "${presets[@]}" | rofi -i -dmenu -config "$rofi_theme" -mesg "Choose an animation preset")
[[ -n "$chosen" ]] || exit 0

source_file="$presets_dir/$chosen.lua"
luac -p "$source_file"
backup_file=$(mktemp)
had_active=false
if [[ -f "$active_file" ]]; then cp "$active_file" "$backup_file"; had_active=true; fi
cp "$source_file" "$active_file"
hyprctl reload >/dev/null || true
errors=$(hyprctl configerrors)
if [[ -n "$errors" ]]; then
  if $had_active; then cp "$backup_file" "$active_file"; else rm -f "$active_file"; fi
  notify-send "Animations" "Preset failed to load; restored the previous Lua animation settings"
  hyprctl reload >/dev/null || true
  rm -f "$backup_file"
  exit 1
fi
rm -f "$backup_file"

notify-send -u low "Animations" "Loaded $chosen"

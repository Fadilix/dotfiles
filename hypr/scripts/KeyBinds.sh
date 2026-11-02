#!/bin/bash
# /* ---- 💫 https://github.com/Fadilix 💫 ---- */  ##
# searchable enabled keybinds using rofi

# kill yad to not interfere with this binds
pkill yad || true

# check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Lua module containing all active Hyprland keybinds
keybinds_lua="$HOME/.config/hypr/lua/bindings.lua"
rofi_theme="$HOME/.config/rofi/stellar-keybinds.rasi"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

# combine the contents of the keybinds files and filter for keybinds
keybinds=$(grep -E '^hl\.bind\(' "$keybinds_lua")

# check for any keybinds to display
if [[ -z "$keybinds" ]]; then
    echo "no keybinds found."
    exit 1
fi

# use rofi to display the keybinds with the modified content
echo "$keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"

#!/bin/bash
# /* ---- 💫 https://github.com/Fadilix 💫 ---- */  ##
# Scripts for refreshing ags waybar, rofi, swaync, wallust

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
  if [ -e "$1" ]; then
    return 0 # File exists
  else
    return 1 # File does not exist
  fi
}

# Kill already running processes
_ps=(waybar rofi ags)   # swaync removed: notifications are handled by latto
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

# quit ags
ags -q

sleep 0.3
# Relaunch waybar
waybar &

# swaync disabled: latto (~/projects/android/latto) is the notification daemon.
# To go back: systemctl --user unmask swaync.service, then uncomment below.
# sleep 0.5
# swaync >/dev/null 2>&1 &

# relaunch ags
ags &

# Relaunching rainbow borders if the script exists
# sleep 1
# if file_exists "${UserScripts}/RainbowBorders.sh"; then
#     ${UserScripts}/RainbowBorders.sh &
# fi Disabled rainbow borders

exit 0


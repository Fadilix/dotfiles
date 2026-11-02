#!/bin/bash
# /* ---- 💫 https://github.com/Fadilix 💫 ---- */  ##
# Airplane Mode. Turning on or off all wifi using rfkill.

notif="$HOME/.config/swaync/images/bell.png"

# Check if any wireless device is blocked
wifi_blocked=$(rfkill list wifi | grep -o "Soft blocked: yes")

if [ -n "$wifi_blocked" ]; then
  if rfkill unblock wifi; then
    qs ipc -p "$HOME/.config/quickshell/latto" call hud airplane off >/dev/null 2>&1 \
      || notify-send -u low -i "$notif" -r 99 'Airplane mode: OFF'
  fi
else
  if rfkill block wifi; then
    qs ipc -p "$HOME/.config/quickshell/latto" call hud airplane on >/dev/null 2>&1 \
      || notify-send -u low -i "$notif" -r 99 'Airplane mode: ON'
  fi
fi

#!/bin/bash
# /* ---- 💫 https://github.com/Fadilix 💫 ---- */  ##
# Keyhints. Opens the Quickshell cheat sheet, which reads the live Hyprland binds.
# Labels are the descriptions in ~/.config/hypr/lua/bindings.lua

exec qs -p "$HOME/.config/quickshell" ipc call keybinds toggle

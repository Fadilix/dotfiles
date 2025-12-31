#!/usr/bin/env bash

# TEMP FILE TO STORE STATE
TOGGLE_FILE="/tmp/touchpad_disabled"

if [ -f "$TOGGLE_FILE" ]; then
  # Enable touchpad
  hyprctl keyword input:sensitivity 0
  rm "$TOGGLE_FILE"
else
  # Disable touchpad
  hyprctl keyword input:sensitivity -2000
  touch "$TOGGLE_FILE"
fi

#!/usr/bin/env bash

TP_DEV="/sys/class/input/event9/device/enabled"
TOGGLE_FILE="/tmp/touchpad_disabled"

if [ -f "$TOGGLE_FILE" ]; then
  echo 1 >$TP_DEV
  rm "$TOGGLE_FILE"
else
  echo 0 >$TP_DEV
  touch "$TOGGLE_FILE"
fi

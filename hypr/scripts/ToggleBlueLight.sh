#!/bin/bash

isBlueLightActive=$(ps -a | grep -c "hyprsunset")

if [ "$isBlueLightActive" -gt 0 ]; then
  notify-send -r 99 "Blue light off"
  pkill hyprsunset
else
  notify-send -r 99 "Blue light on"
  hyprsunset --temperature 2500
fi

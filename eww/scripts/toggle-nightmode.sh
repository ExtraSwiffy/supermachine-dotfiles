#!/bin/bash

STATE="$HOME/.config/eww/state/nightmode"

mkdir -p "$HOME/.config/eww/state"

if [ -f "$STATE" ]; then
  xrandr --output DisplayPort-2 --gamma 1:1:1
  xrandr --output HDMI-A-0 --gamma 1:1:1
  rm -f "$STATE"
else
  xrandr --output DisplayPort-2 --gamma 1.0:0.92:0.78
  xrandr --output HDMI-A-0 --gamma 1.0:0.92:0.78
  touch "$STATE"
fi
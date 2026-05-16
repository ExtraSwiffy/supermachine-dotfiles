#!/bin/bash
STATE="$HOME/.cache/eww-gamemode"

if [ -f "$STATE" ]; then
  rm "$STATE"
else
  touch "$STATE"
fi
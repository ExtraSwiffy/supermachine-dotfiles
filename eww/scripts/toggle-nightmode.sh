#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.config/eww/state/nightmode"

mkdir -p "$HOME/.config/eww/state"

outputs="$(xrandr --query 2>/dev/null | awk '/ connected/ {print $1}')"

[ -n "$outputs" ] || exit 0

if [ -f "$STATE" ]; then
  while read -r output; do
    [ -n "$output" ] && xrandr --output "$output" --gamma 1:1:1
  done <<< "$outputs"
  rm -f "$STATE"
else
  while read -r output; do
    [ -n "$output" ] && xrandr --output "$output" --gamma 1.0:0.92:0.78
  done <<< "$outputs"
  touch "$STATE"
fi

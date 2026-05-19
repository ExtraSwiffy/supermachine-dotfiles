#!/usr/bin/env bash
set -euo pipefail

state_dir="$HOME/.config/eww/state"
off_file="$state_dir/smart-tiling-off"

mkdir -p "$state_dir"

if [ -f "$off_file" ]; then
  rm -f "$off_file"
  eww update SMART_TILING_STATE=on >/dev/null 2>&1 || true
  notify-send "Semi Tiling" "Enabled" 2>/dev/null || true
else
  touch "$off_file"
  eww update SMART_TILING_STATE=off >/dev/null 2>&1 || true
  notify-send "Semi Tiling" "Disabled" 2>/dev/null || true
fi


#!/usr/bin/env bash
set -euo pipefail

state_dir="$HOME/.config/eww/state"
state_file="$state_dir/glow-off"

mkdir -p "$state_dir"

if [ -f "$state_file" ]; then
  rm -f "$state_file"
  eww update GLOW_STATE=on >/dev/null 2>&1 || true
  notify-send "Panel Glow" "Glow enabled." 2>/dev/null || true
else
  : > "$state_file"
  eww update GLOW_STATE=off >/dev/null 2>&1 || true
  notify-send "Panel Glow" "Glow disabled." 2>/dev/null || true
fi

#!/usr/bin/env bash
set -euo pipefail

cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
setter="$cfg/scripts/set-sidebar-logo.sh"

choice="$(
  printf '%s\n' \
    "Arch" \
    "SuperMachine" \
    "Linux" \
    "Terminal" \
    "Code" \
    "Star" \
    "Lightning" \
    "Custom Text" |
    rofi -dmenu -i -p "Sidebar Logo" 2>/dev/null || true
)"

[ -n "$choice" ] || exit 0

if [ "$choice" = "Custom Text" ]; then
  logo="$(rofi -dmenu -p "Logo text/icon" 2>/dev/null || true)"
  [ -n "$logo" ] || exit 0
  "$setter" Custom "$logo"
else
  "$setter" "$choice"
fi

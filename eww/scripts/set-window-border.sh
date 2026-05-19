#!/usr/bin/env bash
set -euo pipefail

state_dir="$HOME/.config/eww/state"
off_file="$state_dir/window-border-off"
width_file="$state_dir/window-border-width"
mode="${1:-toggle}"

mkdir -p "$state_dir"

case "$mode" in
  thinner)
    width="$(cat "$width_file" 2>/dev/null || echo 2)"
    [[ "$width" =~ ^[0-9]+$ ]] || width=2
    width=$((width - 1))
    [ "$width" -lt 0 ] && width=0
    printf '%s\n' "$width" > "$width_file"
    [ "$width" -eq 0 ] && touch "$off_file" || rm -f "$off_file"
    ;;
  thicker)
    width="$(cat "$width_file" 2>/dev/null || echo 2)"
    [[ "$width" =~ ^[0-9]+$ ]] || width=2
    width=$((width + 1))
    [ "$width" -gt 8 ] && width=8
    printf '%s\n' "$width" > "$width_file"
    [ "$width" -eq 0 ] && touch "$off_file" || rm -f "$off_file"
    ;;
  on)
    rm -f "$off_file"
    [ -f "$width_file" ] || printf '%s\n' 2 > "$width_file"
    ;;
  off)
    touch "$off_file"
    ;;
  toggle|*)
    if [ -f "$off_file" ]; then
      rm -f "$off_file"
    else
      touch "$off_file"
    fi
    ;;
esac

state="on"
[ -f "$off_file" ] && state="off"
width="$(cat "$width_file" 2>/dev/null || echo 2)"
[[ "$width" =~ ^[0-9]+$ ]] || width=2

eww update WINDOW_BORDER_STATE="$state" WINDOW_BORDER_WIDTH="$width" >/dev/null 2>&1 || true
"$HOME/.config/eww/scripts/sync-openbox-theme.sh" >/dev/null 2>&1 || true

#!/usr/bin/env bash
set -euo pipefail

state_dir="$HOME/.config/eww/state"
gap_file="$state_dir/window-gap"
direction="${1:-up}"

mkdir -p "$state_dir"

gap="$(cat "$gap_file" 2>/dev/null || echo 5)"
[[ "$gap" =~ ^[0-9]+$ ]] || gap=5

case "$direction" in
  down) gap=$((gap - 1)) ;;
  up|*) gap=$((gap + 1)) ;;
esac

[ "$gap" -lt 0 ] && gap=0
[ "$gap" -gt 40 ] && gap=40

printf '%s\n' "$gap" > "$gap_file"
eww update WINDOW_GAP="$gap" >/dev/null 2>&1 || true
"$HOME/.config/openbox/smart-place.sh" --once >/dev/null 2>&1 || true

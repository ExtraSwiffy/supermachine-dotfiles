#!/usr/bin/env bash
set -euo pipefail

direction="${1:-up}"
cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
state_dir="$cfg/state"
state_file="$state_dir/sidebar-width"

mkdir -p "$state_dir"

current="$(cat "$state_file" 2>/dev/null || echo 90)"
case "$current" in
  ''|*[!0-9]*) current=90 ;;
esac

case "$direction" in
  down) next=$((current - 5)) ;;
  up) next=$((current + 5)) ;;
  *) next="$direction" ;;
esac

case "$next" in
  ''|*[!0-9]*) next=90 ;;
esac

[ "$next" -lt 85 ] && next=85
[ "$next" -gt 130 ] && next=130

printf '%s\n' "$next" > "$state_file"
"$cfg/scripts/panel-layout.sh" >/dev/null 2>&1 || true

eww -c "$cfg" update SIDEBAR_WIDTH="$next" >/dev/null 2>&1 || true
eww -c "$cfg" reload >/dev/null 2>&1 || true

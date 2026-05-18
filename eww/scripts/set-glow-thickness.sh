#!/usr/bin/env bash
set -euo pipefail

direction="${1:-up}"
scss="$HOME/.config/eww/eww.scss"
state_dir="$HOME/.config/eww/state"
state_file="$state_dir/glow-off"
name="settings-glow-thickness"

current="$(
  awk -F': ' -v key="\$${name}" '$1 == key {gsub(/px;|;/, "", $2); print int($2); exit}' "$scss" 2>/dev/null
)"

case "$current" in
  ''|*[!0-9]*) current=5 ;;
esac

case "$direction" in
  down) next=$((current - 1)) ;;
  up|*) next=$((current + 1)) ;;
esac

[ "$next" -lt 1 ] && next=1
[ "$next" -gt 12 ] && next=12

if grep -qF "\$${name}:" "$scss"; then
  sed -i -E "s|^[$]${name}:.*;|\$${name}: ${next}px;|" "$scss"
else
  sed -i "1i \$${name}: ${next}px;" "$scss"
fi

"$HOME/.config/eww/scripts/panel-layout.sh"

mkdir -p "$state_dir"
rm -f "$state_file"
eww update GLOW_STATE=on GLOW_THICKNESS="$next" >/dev/null 2>&1 || true

if eww reload >/dev/null 2>&1; then
  notify-send "Panel Glow" "Glow thickness: ${next}px" 2>/dev/null || true
else
  notify-send "Panel Glow" "Could not reload Eww. Check eww.scss." 2>/dev/null || true
  exit 1
fi

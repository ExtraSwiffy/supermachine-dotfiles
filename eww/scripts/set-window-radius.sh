#!/usr/bin/env bash
set -euo pipefail

conf="$HOME/.config/picom/picom.conf"
direction="${1:-up}"

[ -f "$conf" ] || exit 0

radius="$(awk -F'= ' '/corner-radius/ {gsub(/;| /, "", $2); print $2; exit}' "$conf")"
[[ "$radius" =~ ^[0-9]+$ ]] || radius=0

case "$direction" in
  down) radius=$((radius - 2)) ;;
  up|*) radius=$((radius + 2)) ;;
esac

[ "$radius" -lt 0 ] && radius=0
[ "$radius" -gt 28 ] && radius=28

tmp="$(mktemp)"
awk -v radius="$radius" '
  /^[[:space:]]*corner-radius[[:space:]]*=/ {
    print "corner-radius = " radius ";"
    done = 1
    next
  }
  { print }
  END {
    if (!done) print "corner-radius = " radius ";"
  }
' "$conf" > "$tmp"
mv "$tmp" "$conf"

eww update WINDOW_RADIUS="$radius" >/dev/null 2>&1 || true

pgrep -x picom | xargs -r kill >/dev/null 2>&1 || true
setsid -f picom --config "$conf" >/tmp/supermachine-picom.log 2>&1


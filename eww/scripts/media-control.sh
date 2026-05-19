#!/usr/bin/env bash
set -euo pipefail

action="${1:-play-pause}"
value="${2:-}"

command -v playerctl >/dev/null 2>&1 || exit 0

player="$("$HOME/.config/eww/scripts/media-info.sh" player 2>/dev/null || true)"
[ -n "$player" ] || exit 0

case "$action" in
  play-pause|next|previous|stop)
    playerctl -p "$player" "$action" >/dev/null 2>&1 || true
    ;;
  volume)
    case "$value" in
      ''|*[!0-9]*) exit 0 ;;
    esac
    [ "$value" -lt 0 ] && value=0
    [ "$value" -gt 100 ] && value=100
    playerctl -p "$player" volume "$(awk -v v="$value" 'BEGIN {printf "%.2f", v / 100}')" >/dev/null 2>&1 || true
    ;;
esac

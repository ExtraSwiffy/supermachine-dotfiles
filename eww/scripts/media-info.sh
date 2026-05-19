#!/usr/bin/env bash
set -euo pipefail

field="${1:-title}"

command -v playerctl >/dev/null 2>&1 || {
  case "$field" in
    active) echo "no" ;;
    volume) echo 0 ;;
    icon) echo "󰝚" ;;
    title) echo "No media playing" ;;
    subtitle) echo "Spotify or YouTube" ;;
    status) echo "Stopped" ;;
    *) echo "" ;;
  esac
  exit 0
}

choose_player() {
  local players player status title
  players="$(playerctl -l 2>/dev/null || true)"
  [ -n "$players" ] || return 1

  for player in spotify spotifyd; do
    if grep -qx "$player" <<< "$players"; then
      title="$(playerctl -p "$player" metadata --format '{{title}}' 2>/dev/null || true)"
      [ -n "$title" ] && {
        printf '%s\n' "$player"
        return 0
      }
    fi
  done

  while read -r player; do
    [ -n "$player" ] || continue
    status="$(playerctl -p "$player" status 2>/dev/null || true)"
    title="$(playerctl -p "$player" metadata --format '{{title}}' 2>/dev/null || true)"
    if [ "$status" = "Playing" ] && [ -n "$title" ]; then
      printf '%s\n' "$player"
      return 0
    fi
  done <<< "$players"

  while read -r player; do
    [ -n "$player" ] || continue
    title="$(playerctl -p "$player" metadata --format '{{title}}' 2>/dev/null || true)"
    if [ -n "$title" ]; then
      printf '%s\n' "$player"
      return 0
    fi
  done <<< "$players"

  return 1
}

player="$(choose_player || true)"

if [ -z "$player" ]; then
  case "$field" in
    active) echo "no" ;;
    volume) echo 0 ;;
    icon) echo "󰝚" ;;
    title) echo "No media playing" ;;
    subtitle) echo "Spotify or YouTube" ;;
    status) echo "Stopped" ;;
    *) echo "" ;;
  esac
  exit 0
fi

title="$(playerctl -p "$player" metadata --format '{{title}}' 2>/dev/null || true)"
artist="$(playerctl -p "$player" metadata --format '{{artist}}' 2>/dev/null || true)"
url="$(playerctl -p "$player" metadata --format '{{xesam:url}}' 2>/dev/null || true)"
status="$(playerctl -p "$player" status 2>/dev/null || echo Stopped)"
volume="$(playerctl -p "$player" volume 2>/dev/null | awk '{printf "%d", ($1 * 100) + 0.5}' || echo 0)"

shorten() {
  local text="$1"
  local limit="$2"
  if [ "${#text}" -gt "$limit" ]; then
    printf '%s\n' "${text:0:$((limit - 1))}…"
  else
    printf '%s\n' "$text"
  fi
}

case "$field" in
  active)
    echo "yes"
    ;;
  player)
    echo "$player"
    ;;
  icon)
    if grep -qi 'spotify' <<< "$player"; then
      echo "󰓇"
    elif grep -qi 'youtube\\|youtu\\.be' <<< "$url $title"; then
      echo "󰗃"
    else
      echo "󰎆"
    fi
    ;;
  title)
    shorten "${title:-No media title}" 30
    ;;
  subtitle)
    if [ -n "$artist" ]; then
      shorten "$artist" 30
    elif grep -qi 'youtube\\|youtu\\.be' <<< "$url $title"; then
      echo "YouTube"
    else
      echo "$player"
    fi
    ;;
  status)
    echo "$status"
    ;;
  volume)
    echo "${volume:-0}"
    ;;
  *) echo "" ;;
esac

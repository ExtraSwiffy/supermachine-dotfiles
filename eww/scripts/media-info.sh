#!/usr/bin/env bash
set -euo pipefail

field="${1:-title}"
cache_dir="$HOME/.cache/supermachine-eww-media"
cache_ttl=3

default_value() {
  case "$field" in
    active) echo "no" ;;
    volume) echo 0 ;;
    icon) echo "󰝚" ;;
    title) echo "No media playing" ;;
    subtitle) echo "Spotify or YouTube" ;;
    status) echo "Stopped" ;;
    *) echo "" ;;
  esac
}

read_cache() {
  local file="$cache_dir/$field"
  [ -f "$file" ] || return 1
  cat "$file"
}

cache_is_fresh() {
  local stamp now
  [ -f "$cache_dir/stamp" ] || return 1
  stamp="$(stat -c %Y "$cache_dir/stamp" 2>/dev/null || echo 0)"
  now="$(date +%s)"
  [ $((now - stamp)) -lt "$cache_ttl" ]
}

command -v playerctl >/dev/null 2>&1 || {
  default_value
  exit 0
}

if cache_is_fresh && read_cache; then
  exit 0
fi

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
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

write_cache() {
  mkdir -p "$cache_dir"
  printf '%s\n' "${1:-no}" > "$tmp_dir/active"
  printf '%s\n' "${2:-󰝚}" > "$tmp_dir/icon"
  printf '%s\n' "${3:-No media playing}" > "$tmp_dir/title"
  printf '%s\n' "${4:-Spotify or YouTube}" > "$tmp_dir/subtitle"
  printf '%s\n' "${5:-Stopped}" > "$tmp_dir/status"
  printf '%s\n' "${6:-0}" > "$tmp_dir/volume"
  date +%s > "$tmp_dir/stamp"
  for name in active icon title subtitle status volume stamp; do
    mv "$tmp_dir/$name" "$cache_dir/$name"
  done
}

if [ -z "$player" ]; then
  write_cache "no" "󰝚" "No media playing" "Spotify or YouTube" "Stopped" "0"
  read_cache || default_value
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

if grep -qi 'spotify' <<< "$player"; then
  icon="󰓇"
elif grep -qi 'youtube\\|youtu\\.be' <<< "$url $title"; then
  icon="󰗃"
else
  icon="󰎆"
fi

if [ -n "$artist" ]; then
  subtitle="$(shorten "$artist" 30)"
elif grep -qi 'youtube\\|youtu\\.be' <<< "$url $title"; then
  subtitle="YouTube"
else
  subtitle="$player"
fi

write_cache \
  "yes" \
  "$icon" \
  "$(shorten "${title:-No media title}" 30)" \
  "$subtitle" \
  "$status" \
  "${volume:-0}"

read_cache || default_value

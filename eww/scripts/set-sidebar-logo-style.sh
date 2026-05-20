#!/usr/bin/env bash
set -euo pipefail

field="${1:-size}"
direction="${2:-up}"
cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
state_dir="$cfg/state"
guide_stamp="$state_dir/sidebar-logo-guide-stamp"

mkdir -p "$state_dir"

case "$field" in
  size)
    state_file="$state_dir/sidebar-logo-size"
    default=54
    min=34
    max=78
    step=2
    ;;
  x)
    state_file="$state_dir/sidebar-logo-x"
    default=-20
    min=-45
    max=25
    step=2
    ;;
  y)
    state_file="$state_dir/sidebar-logo-y"
    default=0
    min=-35
    max=35
    step=2
    ;;
  reset)
    "$0" size 54
    "$0" x -20
    "$0" y 0
    exit 0
    ;;
  *) exit 1 ;;
esac

current="$(cat "$state_file" 2>/dev/null || echo "$default")"
case "$current" in
  -*) ;;
  ''|*[!0-9]*) current="$default" ;;
esac

case "$direction" in
  down) next=$((current - step)) ;;
  up) next=$((current + step)) ;;
  *) next="$direction" ;;
esac

case "$next" in
  -*) ;;
  ''|*[!0-9]*) next="$default" ;;
esac

[ "$next" -lt "$min" ] && next="$min"
[ "$next" -gt "$max" ] && next="$max"

printf '%s\n' "$next" > "$state_file"

case "$field" in
  size) eww -c "$cfg" update SIDEBAR_LOGO_SIZE="$next" >/dev/null 2>&1 || true ;;
  x) eww -c "$cfg" update SIDEBAR_LOGO_X="$next" >/dev/null 2>&1 || true ;;
  y) eww -c "$cfg" update SIDEBAR_LOGO_Y="$next" >/dev/null 2>&1 || true ;;
esac

date +%s%N > "$guide_stamp"
stamp="$(cat "$guide_stamp")"
eww -c "$cfg" open logoalignmentguide >/dev/null 2>&1 || true
(
  sleep 1.1
  if [ "$(cat "$guide_stamp" 2>/dev/null || true)" = "$stamp" ]; then
    eww -c "$cfg" close logoalignmentguide >/dev/null 2>&1 || true
  fi
) &

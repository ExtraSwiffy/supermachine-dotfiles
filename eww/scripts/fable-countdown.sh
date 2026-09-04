#!/usr/bin/env bash
set -euo pipefail

action="${1:-days}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/supermachine"
theme_state="$state_dir/active-theme"
window="fablecountdown"
target_date="2027-02-18"
target_epoch="$(date -d "$target_date 00:00:00" +%s)"
now_epoch="$(date +%s)"
seconds_left=$((target_epoch - now_epoch))
today_epoch="$(TZ=UTC date -d "$(date +%F)" +%s)"
target_day_epoch="$(TZ=UTC date -d "$target_date" +%s)"
calendar_days_left=$(((target_day_epoch - today_epoch) / 86400))

days_left() {
  if [ "$calendar_days_left" -le 0 ]; then
    printf '0\n'
  else
    # Compare UTC-normalized calendar dates so daylight-saving transitions do
    # not make the number change an hour before or after local midnight.
    printf '%s\n' "$calendar_days_left"
  fi
}

main_monitor_has_app() {
  local current geometry monitor_x monitor_y monitor_w monitor_h
  current="$(xprop -root _NET_CURRENT_DESKTOP 2>/dev/null | awk -F' = ' 'NF > 1 {print $2; exit}')"
  geometry="$(xrandr --query 2>/dev/null | awk '
    / connected primary / {
      for (i = 1; i <= NF; i++)
        if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) { print $i; exit }
    }
  ')"
  [ -n "$current" ] && [[ "$geometry" =~ ^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$ ]] || return 1
  monitor_w="${BASH_REMATCH[1]}"
  monitor_h="${BASH_REMATCH[2]}"
  monitor_x="${BASH_REMATCH[3]}"
  monitor_y="${BASH_REMATCH[4]}"

  wmctrl -lGx 2>/dev/null | awk \
    -v desktop="$current" -v mx="$monitor_x" -v my="$monitor_y" \
    -v mw="$monitor_w" -v mh="$monitor_h" '
      $2 == desktop && $7 !~ /^(eww\.Eww|polybar\.Polybar)$/ {
        x=$3; y=$4; w=$5; h=$6
        if (w > 1 && h > 1 && x < mx+mw && x+w > mx && y < my+mh && y+h > my)
          found=1
      }
      END { exit(found ? 0 : 1) }
    '
}

sync_window() {
  local active_theme attempt
  active_theme="$(cat "$theme_state" 2>/dev/null || echo default)"

  if [ "$active_theme" != "fable" ] || main_monitor_has_app; then
    if eww ping >/dev/null 2>&1; then
      eww close "$window" >/dev/null 2>&1 || true
    fi
    return 0
  fi

  if ! eww ping >/dev/null 2>&1; then
    systemctl --user start supermachine-eww.service >/dev/null 2>&1 || \
      setsid -f eww daemon >/dev/null 2>&1
  fi

  for attempt in {1..20}; do
    if eww ping >/dev/null 2>&1; then
      if ! eww active-windows 2>/dev/null | grep -q "^${window}:"; then
        eww open "$window" >/dev/null 2>&1
      fi
      return 0
    fi
    sleep 0.1
  done
  return 1
}

watch_window() {
  local desired actual
  while true; do
    if [ "$(cat "$theme_state" 2>/dev/null || echo default)" = "fable" ] && ! main_monitor_has_app; then
      desired="visible"
    else
      desired="hidden"
    fi
    if eww active-windows 2>/dev/null | grep -q "^${window}:"; then
      actual="visible"
    else
      actual="hidden"
    fi
    [ "$desired" = "$actual" ] || sync_window || true
    sleep 0.5
  done
}

case "$action" in
  days) days_left ;;
  label)
    if [ "$seconds_left" -le 0 ]; then
      printf 'EARLY ACCESS IS LIVE\n'
    else
      printf 'UNTIL EARLY ACCESS\n'
    fi
    ;;
  sync) sync_window ;;
  has-app) main_monitor_has_app ;;
  watch) watch_window ;;
  *) printf 'Usage: %s {days|label|sync|has-app|watch}\n' "$0" >&2; exit 2 ;;
esac

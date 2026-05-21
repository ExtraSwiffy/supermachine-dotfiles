#!/usr/bin/env bash
set -euo pipefail

mode="${1:-count}"
state_dir="$HOME/.config/eww/state"
count_file="$state_dir/package-update-count"
status_file="$state_dir/supermachine-update-status"
stamp_file="$state_dir/package-update-count-stamp"
lock_file="/tmp/supermachine-package-updates.lock"
cache_ttl=1800

mkdir -p "$state_dir"

count_updates() {
  local now stamp
  now="$(date +%s)"

  if [ "${1:-cached}" = "cached" ] && [ -f "$count_file" ] && [ -f "$stamp_file" ]; then
    stamp="$(cat "$stamp_file" 2>/dev/null || echo 0)"
    if [ $((now - stamp)) -lt "$cache_ttl" ]; then
      cat "$count_file"
      return 0
    fi
  fi

  exec 9>"$lock_file"
  if ! flock -n 9; then
    cat "$count_file" 2>/dev/null || printf '0\n'
    return 0
  fi

  if ! command -v checkupdates >/dev/null 2>&1; then
    printf '0\n'
    printf '0\n' > "$count_file"
    printf '%s\n' "$now" > "$stamp_file"
    return 0
  fi

  set +e
  output="$(timeout 8s checkupdates 2>/dev/null)"
  set -e
  count="$(printf '%s\n' "$output" | awk 'NF {count++} END {print count+0}')"
  printf '%s\n' "$count" > "$count_file"
  printf '%s\n' "$now" > "$stamp_file"
  printf '%s\n' "$count"
}

case "$mode" in
  count)
    count="$(count_updates)"
    printf '%s\n' "$count"
    ;;
  open)
    count="$(count_updates fresh)"
    if [ "$count" -eq 0 ]; then
      printf '%s\n' "System packages are up to date" > "$status_file"
      eww update PACMAN_UPDATE_COUNT=0 SUPERMACHINE_UPDATE_STATUS="System packages are up to date" >/dev/null 2>&1 || true
      notify-send "SuperMachine Updates" "System packages are up to date." 2>/dev/null || true
      exit 0
    fi

    printf '%s\n' "$count package updates available" > "$status_file"
    eww update PACMAN_UPDATE_COUNT="$count" SUPERMACHINE_UPDATE_STATUS="$count package updates available" >/dev/null 2>&1 || true
    setsid -f alacritty -e bash -lc '
      echo "SuperMachine package updates"
      echo
      checkupdates 2>/dev/null || true
      echo
      read -rp "Run sudo pacman -Syu now? [y/N] " answer
      case "$answer" in
        y|Y|yes|YES)
          sudo pacman -Syu
          ;;
      esac
      echo
      read -rp "Press Enter to close..."
    ' >/dev/null 2>&1
    ;;
  *)
    exit 1
    ;;
esac

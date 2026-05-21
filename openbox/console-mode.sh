#!/usr/bin/env bash
set -euo pipefail

state="$HOME/.cache/supermachine-console-mode"
power_state="$HOME/.cache/supermachine-console-mode-power-profile"
log="$HOME/.cache/supermachine-console-mode.log"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "SuperMachine Console Mode" "$1" >/dev/null 2>&1 || true
  else
    printf 'SuperMachine Console Mode: %s\n' "$1" >&2
  fi
}

has_console_deps() {
  command -v gamescope >/dev/null 2>&1 && command -v steam >/dev/null 2>&1
}

save_power_profile() {
  if command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl get > "$power_state" 2>/dev/null || printf '%s\n' balanced > "$power_state"
    powerprofilesctl set performance >/dev/null 2>&1 || true
  fi
}

restore_power_profile() {
  if command -v powerprofilesctl >/dev/null 2>&1; then
    if [ -s "$power_state" ]; then
      powerprofilesctl set "$(cat "$power_state")" >/dev/null 2>&1 || powerprofilesctl set balanced >/dev/null 2>&1 || true
    else
      powerprofilesctl set balanced >/dev/null 2>&1 || true
    fi
  fi
  rm -f "$power_state"
}

primary_output() {
  xrandr --query 2>/dev/null |
    awk '/ connected primary/ {print $1; found=1; exit} / connected/ && !fallback {fallback=$1} END {if (!found && fallback) print fallback}'
}

primary_mode() {
  local output="$1"

  xrandr --query 2>/dev/null |
    awk -v output="$output" '
      $1 == output {in_output=1; next}
      in_output && /^[^[:space:]]/ {exit}
      in_output && /\*/ {
        mode = $1
        refresh = $2
        gsub(/\*|\+/, "", refresh)
        split(mode, parts, "x")
        print parts[1], parts[2], refresh
        exit
      }
    '
}

configure_console_display() {
  local output mode width height refresh command_parts connected

  output="$(primary_output)"
  [ -n "$output" ] || return 0

  read -r width height refresh < <(primary_mode "$output")
  [ -n "${width:-}" ] && [ -n "${height:-}" ] || return 0

  command_parts=(xrandr --output "$output" --primary --mode "${width}x${height}" --pos 0x0)
  if [ -n "${refresh:-}" ]; then
    command_parts+=(--rate "$refresh")
  fi

  while read -r connected; do
    [ "$connected" = "$output" ] && continue
    command_parts+=(--output "$connected" --off)
  done < <(xrandr --query 2>/dev/null | awk '/ connected/ {print $1}')

  "${command_parts[@]}" >/dev/null 2>&1 || true
}

console_resolution() {
  local output width height refresh

  output="$(primary_output)"
  if [ -n "$output" ]; then
    read -r width height refresh < <(primary_mode "$output")
  fi

  if [ -z "${width:-}" ] || [ -z "${height:-}" ]; then
    read -r width height < <(xdpyinfo 2>/dev/null | awk '/dimensions:/ {split($2, p, "x"); print p[1], p[2]; exit}')
  fi

  printf '%s %s %s\n' "${width:-1920}" "${height:-1080}" "${refresh:-60}"
}

enter_console_mode() {
  if ! has_console_deps; then
    notify "Install gamescope and steam first. Fresh SuperMachine installs include them in pkglist.txt."
    exit 1
  fi

  touch "$state"
  notify "Desktop will close. Run startx again to launch Steam Console Mode."
  eww kill >/dev/null 2>&1 || true
  pkill -x picom >/dev/null 2>&1 || true
  sleep 0.8
  openbox --exit >/dev/null 2>&1 || true
}

return_to_desktop() {
  rm -f "$state"
  restore_power_profile
  timeout 6 steam -shutdown >/dev/null 2>&1 || true
  pkill -x steamwebhelper >/dev/null 2>&1 || true
  pkill -x steam >/dev/null 2>&1 || true
  notify "Console Mode disabled. Startx will open the SuperMachine desktop."
}

run_console_session() {
  local width height refresh

  if ! has_console_deps; then
    rm -f "$state"
    notify "gamescope or steam is missing. Starting desktop instead."
    exec openbox-session
  fi

  save_power_profile
  xset -dpms s off s noblank >/dev/null 2>&1 || true
  export PATH="$HOME/.local/bin:$PATH"
  export XDG_CURRENT_DESKTOP=gamescope
  export STEAMOS=1
  configure_console_display
  read -r width height refresh < <(console_resolution)

  {
    printf 'Starting SuperMachine Console Mode at %s\n' "$(date)"
    printf 'Resolution: %sx%s @ %s\n' "$width" "$height" "$refresh"
    gamescope -e -f -b --force-windows-fullscreen --hide-cursor-delay 1 --adaptive-sync --immediate-flips -W "$width" -H "$height" -w "$width" -h "$height" -r "$refresh" -- steam -steamdeck -steamos3 -steampal -gamepadui
    printf 'Console Mode exited at %s\n' "$(date)"
  } >> "$log" 2>&1 || true

  timeout 6 steam -shutdown >/dev/null 2>&1 || true
  pkill -x steamwebhelper >/dev/null 2>&1 || true
  pkill -x steam >/dev/null 2>&1 || true

  if [ -f "$state" ]; then
    sleep 2
    exec "$0" session
  fi

  restore_power_profile
  exec openbox-session
}

case "${1:-status}" in
  enter)
    enter_console_mode
    ;;
  return|desktop)
    return_to_desktop
    ;;
  session)
    run_console_session
    ;;
  should-start)
    [ -f "$state" ]
    ;;
  status)
    [ -f "$state" ] && printf '%s\n' console || printf '%s\n' desktop
    ;;
  *)
    printf 'Usage: %s [enter|return|session|should-start|status]\n' "$0" >&2
    exit 2
    ;;
esac

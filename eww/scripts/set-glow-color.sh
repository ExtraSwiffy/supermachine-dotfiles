#!/usr/bin/env bash
set -euo pipefail

slot="${1:-preset}"
mode="${2:-cycle}"
scss="$HOME/.config/eww/eww.scss"
state_dir="$HOME/.config/eww/state"
state_file="$state_dir/glow-off"

palette=(
  "rgba(55, 210, 255, 0.54)"
  "rgba(136, 192, 208, 0.95)"
  "rgba(163, 104, 255, 0.72)"
  "rgba(255, 91, 180, 0.54)"
  "rgba(235, 245, 255, 0.66)"
  "rgba(98, 72, 180, 0.72)"
  "rgba(0, 0, 0, 0.34)"
  "rgba(255, 255, 255, 0.12)"
)

set_var() {
  local name="$1"
  local value="$2"

  if grep -qF "\$${name}:" "$scss"; then
    sed -i -E "s|^[$]${name}:.*;|\$${name}: ${value};|" "$scss"
  else
    sed -i "1i \$${name}: ${value};" "$scss"
  fi
}

get_var() {
  local name="$1"
  awk -F': ' -v key="\$${name}" '$1 == key {sub(/;$/, "", $2); print $2; exit}' "$scss"
}

next_color() {
  local current="$1"
  local i

  for i in "${!palette[@]}"; do
    if [ "${palette[$i]}" = "$current" ]; then
      printf '%s\n' "${palette[$(((i + 1) % ${#palette[@]}))]}"
      return
    fi
  done

  printf '%s\n' "${palette[0]}"
}

reload_eww() {
  mkdir -p "$state_dir"
  rm -f "$state_file"
  eww update GLOW_STATE=on >/dev/null 2>&1 || true

  if eww reload >/dev/null 2>&1; then
    notify-send "Panel Glow" "Updated settings glow." 2>/dev/null || true
  else
    notify-send "Panel Glow" "Could not reload Eww. Check eww.scss." 2>/dev/null || true
    exit 1
  fi
}

apply_preset() {
  case "$1" in
    default)
      set_var settings-glow-cyan "rgba(55, 210, 255, 0.54)"
      set_var settings-glow-blue "rgba(136, 192, 208, 0.95)"
      set_var settings-glow-purple "rgba(163, 104, 255, 0.72)"
      set_var settings-glow-pink "rgba(255, 91, 180, 0.54)"
      ;;
    ice)
      set_var settings-glow-cyan "rgba(136, 192, 208, 0.42)"
      set_var settings-glow-blue "rgba(202, 232, 240, 0.72)"
      set_var settings-glow-purple "rgba(150, 170, 210, 0.42)"
      set_var settings-glow-pink "rgba(255, 255, 255, 0.16)"
      ;;
    neon)
      set_var settings-glow-cyan "rgba(55, 210, 255, 0.62)"
      set_var settings-glow-blue "rgba(78, 166, 255, 0.72)"
      set_var settings-glow-purple "rgba(170, 90, 255, 0.76)"
      set_var settings-glow-pink "rgba(255, 91, 180, 0.6)"
      ;;
    *) exit 0 ;;
  esac
}

case "$slot" in
  1) var="settings-glow-cyan" ;;
  2) var="settings-glow-blue" ;;
  3) var="settings-glow-purple" ;;
  4) var="settings-glow-pink" ;;
  preset)
    apply_preset "$mode"
    reload_eww
    exit 0
    ;;
  *) exit 1 ;;
esac

case "$mode" in
  cycle)
    current="$(get_var "$var")"
    set_var "$var" "$(next_color "$current")"
    ;;
  rgba*)
    set_var "$var" "$mode"
    ;;
  *)
    exit 0
    ;;
esac

reload_eww

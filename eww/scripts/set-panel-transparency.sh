#!/usr/bin/env bash
set -euo pipefail

direction="${1:-up}"
cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
scss="$cfg/eww.scss"
state_dir="$cfg/state"
state_file="$state_dir/panel-transparency"

mkdir -p "$state_dir"

current="$(cat "$state_file" 2>/dev/null || echo 86)"
case "$current" in
  ''|*[!0-9]*) current=86 ;;
esac

case "$direction" in
  down) next=$((current - 5)) ;;
  up) next=$((current + 5)) ;;
  *) next="$direction" ;;
esac

case "$next" in
  ''|*[!0-9]*) next=86 ;;
esac

[ "$next" -lt 40 ] && next=40
[ "$next" -gt 96 ] && next=96

alpha() {
  awk -v n="$1" 'BEGIN { printf "%.3g", n / 100 }'
}

scaled_alpha() {
  awk -v n="$1" -v scale="$2" -v max="$3" 'BEGIN {
    value = (n / 100) * scale
    if (value > max) value = max
    printf "%.3g", value
  }'
}

set_var() {
  local name="$1"
  local value="$2"

  if grep -qF "\$${name}:" "$scss"; then
    sed -i -E "s|^[$]${name}:.*;|\$${name}: ${value};|" "$scss"
  else
    sed -i "1i \$${name}: ${value};" "$scss"
  fi
}

panel_alpha="$(alpha "$next")"
detail_alpha="$(awk -v a="$panel_alpha" 'BEGIN { v = a + 0.04; if (v > 0.98) v = 0.98; printf "%.3g", v }')"
picker_alpha="$(awk -v a="$panel_alpha" 'BEGIN { v = a + 0.06; if (v > 0.99) v = 0.99; printf "%.3g", v }')"
welcome_alpha="$(awk -v a="$panel_alpha" 'BEGIN { v = a + 0.08; if (v > 0.99) v = 0.99; printf "%.3g", v }')"
sidebar_alpha="$(scaled_alpha "$next" 0.45 0.55)"
section_alpha="$(scaled_alpha "$next" 0.052 0.07)"

set_var sidebar-bg "rgba(15, 15, 15, ${sidebar_alpha})"
set_var settings-panel-bg "rgba(12, 14, 16, ${panel_alpha})"
set_var settings-detail-bg "rgba(12, 14, 16, ${detail_alpha})"
set_var settings-picker-bg "rgba(12, 14, 16, ${picker_alpha})"
set_var settings-section-bg "rgba(255, 255, 255, ${section_alpha})"
set_var welcome-bg "rgba(12, 14, 16, ${welcome_alpha})"

printf '%s\n' "$next" > "$state_file"
eww -c "$cfg" update PANEL_TRANSPARENCY="$next" >/dev/null 2>&1 || true
eww -c "$cfg" reload >/dev/null 2>&1 || true

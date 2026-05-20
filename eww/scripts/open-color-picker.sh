#!/usr/bin/env bash
set -euo pipefail

slot="${1:-1}"
depth="${2:-detail}"
cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
state_dir="$cfg/state"

mkdir -p "$state_dir"

case "$depth" in
  detail|advanced) ;;
  *) depth="detail" ;;
esac

printf '%s\n' "$depth" > "$state_dir/color-picker-depth"

eww -c "$cfg" update GLOW_SLOT="$slot" >/dev/null 2>&1 || true

if [ "$depth" = "detail" ]; then
  eww -c "$cfg" close panelcustomization >/dev/null 2>&1 || true
fi

eww -c "$cfg" close glowcolorpicker >/dev/null 2>&1 || true
"$cfg/scripts/panel-layout.sh" >/dev/null 2>&1 || true
eww -c "$cfg" open glowcolorpicker

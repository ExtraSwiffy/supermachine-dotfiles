#!/usr/bin/env bash
set -euo pipefail

target="${1:-}"
cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"

case "$target" in
  bluetoothsettings|displaysettings|networksettings|audiosettings|powersettings|appearancesettings|keybindsettings|systeminfopanel) ;;
  *) exit 1 ;;
esac

active="$(eww -c "$cfg" active-windows 2>/dev/null || true)"

for window in \
  bluetoothsettings \
  displaysettings \
  networksettings \
  audiosettings \
  powersettings \
  appearancesettings \
  keybindsettings \
  systeminfopanel \
  panelcustomization \
  glowcolorpicker \
  sidebarlogopicker; do
  [ "$window" = "$target" ] && continue

  if grep -q "^${window}:" <<< "$active"; then
    eww -c "$cfg" close "$window" >/dev/null 2>&1 || true
  fi
done

eww -c "$cfg" open --toggle "$target"

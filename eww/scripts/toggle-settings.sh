#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/.config/eww"
lock_file="/tmp/supermachine-settings-toggle.lock"
fullscreen_override="/tmp/supermachine-fullscreen-sidebar-override"

exec 9>"$lock_file"
flock -n 9 || exit 0

close_settings() {
  local active
  active="$(eww -c "$cfg" active-windows 2>/dev/null || true)"

  for window in \
    settingsborder \
    logoalignmentguide \
    systemsettings \
    bluetoothsettings \
    displaysettings \
    networksettings \
    audiosettings \
    powersettings \
    appearancesettings \
    panelcustomization \
    glowcolorpicker \
    sidebarlogopicker \
    keybindsettings \
    systeminfopanel; do
    if grep -q "^${window}:" <<< "$active"; then
      eww -c "$cfg" close "$window" >/dev/null 2>&1 || true
    fi
  done
}

active_windows="$(eww -c "$cfg" active-windows 2>/dev/null || true)"

if grep -q '^systemsettings:' <<< "$active_windows"; then
  close_settings
  rm -f "$fullscreen_override"
else
  close_settings
  "$cfg/scripts/panel-layout.sh"
  "$cfg/scripts/update-verse.sh"
  touch "$fullscreen_override"
  eww -c "$cfg" open sidebar >/dev/null 2>&1 || true
  eww -c "$cfg" open settingsborder
  eww -c "$cfg" open systemsettings
fi

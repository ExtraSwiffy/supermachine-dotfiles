#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/.config/eww"
lock_dir="/tmp/supermachine-settings-toggle.lockdir"
fullscreen_override="/tmp/supermachine-fullscreen-sidebar-override"
game_state="$HOME/.cache/eww-gamemode"

mkdir "$lock_dir" 2>/dev/null || exit 0
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

if ! eww -c "$cfg" active-windows >/dev/null 2>&1; then
  eww -c "$cfg" daemon >/dev/null 2>&1 || true
  sleep 0.2
fi

close_settings() {
  eww -c "$cfg" close \
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
    systeminfopanel \
    consoleconfirm \
    controlcenter >/dev/null 2>&1 || true
}

active_windows="$(eww -c "$cfg" active-windows 2>/dev/null || true)"

if grep -Eq '^(settingsborder|systemsettings|bluetoothsettings|displaysettings|networksettings|audiosettings|powersettings|appearancesettings|panelcustomization|glowcolorpicker|sidebarlogopicker|keybindsettings|systeminfopanel|controlcenter):' <<< "$active_windows"; then
  close_settings
  rm -f "$fullscreen_override"
  if [ -f "$game_state" ]; then
    eww -c "$cfg" close sidebar >/dev/null 2>&1 || true
    sleep 0.05
    eww -c "$cfg" kill >/dev/null 2>&1 || true
  fi
else
  close_settings
  "$cfg/scripts/panel-layout.sh"
  "$cfg/scripts/update-verse.sh"
  touch "$fullscreen_override"
  eww -c "$cfg" open sidebar >/dev/null 2>&1 || true
  eww -c "$cfg" open settingsborder
  eww -c "$cfg" open systemsettings
fi

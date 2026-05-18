#!/bin/bash
set -euo pipefail

cfg="$HOME/.config/eww"

close_settings() {
  for window in \
    settingsborder \
    systemsettings \
    bluetoothsettings \
    displaysettings \
    networksettings \
    audiosettings \
    powersettings \
    appearancesettings \
    panelcustomization \
    glowcolorpicker \
    keybindsettings \
    systeminfopanel; do
    if eww -c "$cfg" active-windows | grep -q "^${window}:"; then
      eww -c "$cfg" close "$window" >/dev/null 2>&1 || true
    fi
  done
}

if eww -c "$cfg" active-windows | grep -q '^systemsettings:'; then
  close_settings
else
  close_settings
  "$cfg/scripts/panel-layout.sh"
  "$cfg/scripts/update-verse.sh"
  eww -c "$cfg" open settingsborder
  eww -c "$cfg" open systemsettings
fi

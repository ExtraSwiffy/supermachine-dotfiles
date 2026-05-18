#!/bin/bash
set -euo pipefail

cfg="$HOME/.config/eww"

close_settings() {
  eww -c "$cfg" close \
    settingsborder \
    systemsettings \
    bluetoothsettings \
    displaysettings \
    networksettings \
    audiosettings \
    powersettings \
    appearancesettings \
    systeminfopanel >/dev/null 2>&1 || true
}

if eww -c "$cfg" active-windows | grep -q '^systemsettings:'; then
  close_settings
else
  "$cfg/scripts/update-verse.sh"
  eww -c "$cfg" open settingsborder
  eww -c "$cfg" open systemsettings
fi

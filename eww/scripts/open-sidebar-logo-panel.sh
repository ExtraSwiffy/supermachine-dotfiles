#!/usr/bin/env bash
set -euo pipefail

cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"

eww -c "$cfg" close panelcustomization >/dev/null 2>&1 || true
eww -c "$cfg" close glowcolorpicker >/dev/null 2>&1 || true

"$cfg/scripts/panel-layout.sh" >/dev/null 2>&1 || true
eww -c "$cfg" open --toggle sidebarlogopicker

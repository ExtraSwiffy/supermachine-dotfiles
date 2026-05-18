#!/usr/bin/env bash
set -euo pipefail

cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
active="$(eww -c "$cfg" active-windows 2>/dev/null || true)"

if grep -q '^glowcolorpicker:' <<< "$active"; then
  eww -c "$cfg" close glowcolorpicker >/dev/null 2>&1 || true
fi

eww -c "$cfg" open --toggle panelcustomization

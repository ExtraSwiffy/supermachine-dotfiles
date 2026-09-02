#!/usr/bin/env bash
set -u

settings_file="${XDG_CONFIG_HOME:-$HOME/.config}/supermachine/settings.conf"
[ -r "$settings_file" ] && source "$settings_file"

primary="${SUPERMACHINE_PRIMARY_MONITOR:-HDMI-A-0}"
secondary="${SUPERMACHINE_SECONDARY_MONITOR:-HDMI-A-1-1}"
secondary_rotation="${SUPERMACHINE_SECONDARY_ROTATION:-left}"
secondary_width="${SUPERMACHINE_SECONDARY_WIDTH:-1080}"

is_connected() {
  xrandr --query 2>/dev/null |
    awk -v output="$1" '$1 == output && $2 == "connected" {found=1} END {exit !found}'
}

# Edge case: the primary monitor is on the RX 7800 XT while the portrait
# monitor is connected to the Ryzen 8700G iGPU. Xorg gives provider outputs a
# suffixed name, so handle this exact pair without affecting other layouts.
if is_connected "$primary" && is_connected "$secondary"; then
  if xrandr \
    --output "$secondary" --auto --rotate "$secondary_rotation" --pos 0x0 \
    --output "$primary" --primary --auto --rotate normal --pos "${secondary_width}x0"; then
    exit 0
  fi

  # Safe fallback if the cross-GPU layout cannot be applied.
  xrandr --output "$secondary" --off \
    --output "$primary" --primary --auto --rotate normal --pos 0x0
  exit 1
fi

# Portable fallback for a laptop, VM, replacement GPU, or one-monitor boot.
xrandr --auto

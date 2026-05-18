#!/usr/bin/env bash
set -euo pipefail

eww update KEY_CAPTURE_STATUS="Waiting" KEY_CAPTURED_COMBO="Press a key combo"

if ! command -v xev >/dev/null 2>&1; then
  eww update KEY_CAPTURE_STATUS="Missing xev" KEY_CAPTURED_COMBO="Install xorg-xev"
  notify-send "Key Capture" "Install xorg-xev to capture key combos." 2>/dev/null || true
  exit 0
fi

combo="$(
  timeout 8s xev -root -event keyboard 2>/dev/null |
    awk '
      /KeyPress event/ { pressed = 1; next }
      pressed && /state 0x/ {
        if (match($0, /state (0x[0-9a-fA-F]+), keycode [0-9]+ \(keysym 0x[0-9a-fA-F]+, ([^)]+)\)/, m)) {
          state = strtonum(m[1])
          key = m[2]
          if (key ~ /^(Shift|Control|Alt|Super|Meta|Hyper|ISO|Caps|Num|Mode)_/) {
            pressed = 0
            next
          }
          combo = ""
          if (and(state, 64)) combo = combo "Super + "
          if (and(state, 4)) combo = combo "Ctrl + "
          if (and(state, 8)) combo = combo "Alt + "
          if (and(state, 1)) combo = combo "Shift + "
          gsub(/^XF86/, "", key)
          gsub(/_/, " ", key)
          print combo key
          exit
        }
      }
    '
)"

if [ -z "$combo" ]; then
  eww update KEY_CAPTURE_STATUS="Timed out" KEY_CAPTURED_COMBO="No combo captured"
  notify-send "Key Capture" "No key combo was captured." 2>/dev/null || true
  exit 0
fi

eww update KEY_CAPTURE_STATUS="Ready" KEY_CAPTURED_COMBO="$combo"
notify-send "Key Capture" "$combo" 2>/dev/null || true

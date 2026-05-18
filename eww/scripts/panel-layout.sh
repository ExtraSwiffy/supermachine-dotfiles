#!/usr/bin/env bash
set -euo pipefail

cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
yuck="$cfg/eww.yuck"
scss="$cfg/eww.scss"

[ -f "$yuck" ] || exit 0

glow="$(
  awk -F': ' '/\$settings-glow-thickness/ {gsub(/px;|;/, "", $2); print int($2); exit}' "$scss" 2>/dev/null || true
)"

case "$glow" in
  ''|*[!0-9]*) glow=5 ;;
esac

screen_width="${EWW_SCREEN_WIDTH:-$(
  xrandr --query 2>/dev/null |
    awk '
      / connected/ && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
        split(substr($0, RSTART, RLENGTH), dims, "x")
        print dims[1]
        exit
      }
    '
)}"

case "$screen_width" in
  ''|*[!0-9]*) screen_width=1920 ;;
esac

sidebar_w=90
first_w=285
detail_default=430
picker_default=300

border_x="$sidebar_w"
first_x=$((border_x + glow))
detail_x=$((first_x + first_w))
available=$((screen_width - detail_x))

if [ "$available" -ge 1160 ]; then
  detail_w="$detail_default"
  advanced_w="$detail_default"
  picker_w="$picker_default"
elif [ "$available" -ge 980 ]; then
  detail_w=380
  advanced_w=360
  picker_w=240
elif [ "$available" -ge 820 ]; then
  detail_w=330
  advanced_w=300
  picker_w=220
else
  detail_w=300
  advanced_w=280
  picker_w=220
fi

advanced_x=$((detail_x + detail_w))
picker_x=$((advanced_x + advanced_w))

tmp="$(mktemp)"
awk \
  -v border_x="$border_x" \
  -v first_x="$first_x" \
  -v detail_x="$detail_x" \
  -v advanced_x="$advanced_x" \
  -v picker_x="$picker_x" \
  -v glow="$glow" \
  -v first_w="$first_w" \
  -v detail_w="$detail_w" \
  -v advanced_w="$advanced_w" \
  -v picker_w="$picker_w" '
  /^\(defwindow / {
    win = $2
    gsub(/[()]/, "", win)
  }
  /^[[:space:]]*:x "[0-9]+px"/ {
    if (win == "settingsborder") {
      sub(/:x "[0-9]+px"/, ":x \"" border_x "px\"")
    } else if (win == "systemsettings") {
      sub(/:x "[0-9]+px"/, ":x \"" first_x "px\"")
    } else if (win == "panelcustomization") {
      sub(/:x "[0-9]+px"/, ":x \"" advanced_x "px\"")
    } else if (win == "glowcolorpicker") {
      sub(/:x "[0-9]+px"/, ":x \"" picker_x "px\"")
    } else if (win ~ /^(bluetoothsettings|displaysettings|networksettings|audiosettings|powersettings|appearancesettings|keybindsettings|systeminfopanel)$/) {
      sub(/:x "[0-9]+px"/, ":x \"" detail_x "px\"")
    }
  }
  /^[[:space:]]*:width "[0-9]+px"/ {
    if (win == "settingsborder") {
      sub(/:width "[0-9]+px"/, ":width \"" glow "px\"")
    } else if (win == "systemsettings") {
      sub(/:width "[0-9]+px"/, ":width \"" first_w "px\"")
    } else if (win == "panelcustomization") {
      sub(/:width "[0-9]+px"/, ":width \"" advanced_w "px\"")
    } else if (win == "glowcolorpicker") {
      sub(/:width "[0-9]+px"/, ":width \"" picker_w "px\"")
    } else if (win ~ /^(bluetoothsettings|displaysettings|networksettings|audiosettings|powersettings|appearancesettings|keybindsettings|systeminfopanel)$/) {
      sub(/:width "[0-9]+px"/, ":width \"" detail_w "px\"")
    }
  }
  { print }
' "$yuck" > "$tmp"

mv "$tmp" "$yuck"

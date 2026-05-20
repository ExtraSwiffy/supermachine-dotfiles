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

read -r screen_width screen_height < <(
  if [ -n "${EWW_SCREEN_WIDTH:-}" ]; then
    printf '%s %s\n' "$EWW_SCREEN_WIDTH" "${EWW_SCREEN_HEIGHT:-1080}"
  else
    xrandr --query 2>/dev/null |
      awk '
        / connected/ && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
          geom = substr($0, RSTART, RLENGTH)
          split(geom, parts, /[x+]/)
          w = parts[1]
          h = parts[2]
          if ($0 ~ / primary /) {
            print w, h
            found = 1
            exit
          }
          if (w > best_w) {
            best_w = w
            best_h = h
          }
        }
        END {
          if (!found && best_w) print best_w, best_h
        }
      '
  fi
)

case "$screen_width" in
  ''|*[!0-9]*) screen_width=1920 ;;
esac

case "$screen_height" in
  ''|*[!0-9]*) screen_height=1080 ;;
esac

sidebar_w="$(cat "$cfg/state/sidebar-width" 2>/dev/null || echo 90)"
case "$sidebar_w" in
  ''|*[!0-9]*) sidebar_w=90 ;;
esac
[ "$sidebar_w" -lt 85 ] && sidebar_w=85
[ "$sidebar_w" -gt 130 ] && sidebar_w=130

first_w=285
detail_w=430
advanced_w=430
picker_w=300

border_x="$sidebar_w"
first_x=$((border_x + glow))
detail_x=$((first_x + first_w))

if [ "$screen_width" -lt 1180 ]; then
  first_w=260
  detail_w=280
  advanced_w=240
  picker_w=200
elif [ "$screen_width" -lt 1360 ]; then
  first_w=275
  detail_w=350
  advanced_w=320
  picker_w=240
elif [ "$screen_width" -lt 1500 ]; then
  detail_w=390
  advanced_w=360
  picker_w=260
fi

detail_x=$((first_x + first_w))
advanced_x=$((detail_x + detail_w))
picker_depth="$(cat "$cfg/state/color-picker-depth" 2>/dev/null || echo advanced)"

case "$picker_depth" in
  detail) picker_x="$advanced_x" ;;
  *) picker_x=$((advanced_x + advanced_w + 48)) ;;
esac

if [ $((picker_x + picker_w)) -gt "$screen_width" ]; then
  picker_x=$((screen_width - picker_w))
  [ "$picker_x" -lt "$advanced_x" ] && picker_x="$advanced_x"
fi

scroll_h=$((screen_height - 160))
[ "$scroll_h" -lt 320 ] && scroll_h=320

tmp="$(mktemp)"
awk \
  -v border_x="$border_x" \
  -v first_x="$first_x" \
  -v detail_x="$detail_x" \
  -v advanced_x="$advanced_x" \
  -v picker_x="$picker_x" \
  -v glow="$glow" \
  -v sidebar_w="$sidebar_w" \
  -v first_w="$first_w" \
  -v detail_w="$detail_w" \
  -v advanced_w="$advanced_w" \
  -v picker_w="$picker_w" \
  -v scroll_h="$scroll_h" '
  /^\(defwindow / {
    win = $2
    gsub(/[()]/, "", win)
  }
  /^[[:space:]]*:x "[0-9]+px"/ {
    if (win == "settingsborder") {
      sub(/:x "[0-9]+px"/, ":x \"" border_x "px\"")
    } else if (win == "systemsettings") {
      sub(/:x "[0-9]+px"/, ":x \"" first_x "px\"")
    } else if (win == "panelcustomization" || win == "sidebarlogopicker") {
      sub(/:x "[0-9]+px"/, ":x \"" advanced_x "px\"")
    } else if (win == "glowcolorpicker") {
      sub(/:x "[0-9]+px"/, ":x \"" picker_x "px\"")
    } else if (win ~ /^(bluetoothsettings|displaysettings|networksettings|audiosettings|powersettings|appearancesettings|keybindsettings|systeminfopanel)$/) {
      sub(/:x "[0-9]+px"/, ":x \"" detail_x "px\"")
    }
  }
  /^[[:space:]]*:width "[0-9]+px"/ {
    if (win == "sidebar" || win == "logoalignmentguide") {
      sub(/:width "[0-9]+px"/, ":width \"" sidebar_w "px\"")
    } else if (win == "settingsborder") {
      sub(/:width "[0-9]+px"/, ":width \"" glow "px\"")
    } else if (win == "systemsettings") {
      sub(/:width "[0-9]+px"/, ":width \"" first_w "px\"")
    } else if (win == "panelcustomization") {
      sub(/:width "[0-9]+px"/, ":width \"" advanced_w "px\"")
    } else if (win == "sidebarlogopicker") {
      sub(/:width "[0-9]+px"/, ":width \"" picker_w "px\"")
    } else if (win == "glowcolorpicker") {
      sub(/:width "[0-9]+px"/, ":width \"" picker_w "px\"")
    } else if (win ~ /^(bluetoothsettings|displaysettings|networksettings|audiosettings|powersettings|appearancesettings|keybindsettings|systeminfopanel)$/) {
      sub(/:width "[0-9]+px"/, ":width \"" detail_w "px\"")
    }
  }
  { print }
' "$yuck" > "$tmp"

if cmp -s "$tmp" "$yuck"; then
  rm -f "$tmp"
else
  mv "$tmp" "$yuck"
fi

tmp="$(mktemp)"
awk -v scroll_h="$scroll_h" -v sidebar_w="$sidebar_w" '
  /^\.sidebar / {
    block = "sidebar"
  }
  /^\.launcher / {
    block = "launcher"
  }
  /^\.clock / {
    block = "clock"
  }
  /^\.ampm / {
    block = "ampm"
  }
  /^\.sidebar-actions / {
    block = "sidebar-actions"
  }
  block == "sidebar" && /^[[:space:]]*min-width:/ {
    sub(/min-width: [0-9]+px;/, "min-width: " sidebar_w "px;")
  }
  block == "launcher" && /^[[:space:]]*min-width:/ {
    sub(/min-width: [0-9]+px;/, "min-width: " sidebar_w "px;")
  }
  block == "clock" && /^[[:space:]]*min-width:/ {
    sub(/min-width: [0-9]+px;/, "min-width: " sidebar_w "px;")
  }
  block == "ampm" && /^[[:space:]]*min-width:/ {
    sub(/min-width: [0-9]+px;/, "min-width: " sidebar_w "px;")
  }
  block == "sidebar-actions" && /^[[:space:]]*min-width:/ {
    sub(/min-width: [0-9]+px;/, "min-width: " (sidebar_w - 8) "px;")
  }
  /^\.(settings-preset-scroll|settings-picker-scroll|settings-detail-scroll) / {
    in_scroll = 1
  }
  in_scroll && /^[[:space:]]*min-height:/ {
    sub(/min-height: [0-9]+px;/, "min-height: " scroll_h "px;")
    in_scroll = 0
  }
  /^\}/ {
    in_scroll = 0
    block = ""
  }
  { print }
' "$scss" > "$tmp"

if cmp -s "$tmp" "$scss"; then
  rm -f "$tmp"
else
  mv "$tmp" "$scss"
fi

#!/usr/bin/env bash
set -euo pipefail

scss="${1:-$HOME/.config/eww/eww.scss}"
themerc="${2:-$HOME/.themes/SuperMachine/openbox-3/themerc}"
state_dir="$HOME/.config/eww/state"
game_state="$HOME/.cache/eww-gamemode"

[ -f "$scss" ] || exit 0
[ -f "$themerc" ] || exit 0

rgba_to_hex() {
  printf '%s\n' "$1" |
    awk '
      match($0, /rgba?\(([0-9]+),[[:space:]]*([0-9]+),[[:space:]]*([0-9]+)/, c) {
        printf "#%02X%02X%02X\n", c[1], c[2], c[3]
        found = 1
      }
      END { if (!found) exit 1 }
    '
}

scss_var() {
  awk -F': ' -v key="\$${1}" '$1 == key {sub(/;$/, "", $2); print $2; exit}' "$scss"
}

set_theme_value() {
  local key="$1"
  local value="$2"
  local tmp

  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    index($0, key ":") == 1 {
      if (!done) {
        print key ": " value
        done = 1
      }
      next
    }
    { print }
    END {
      if (!done) print key ": " value
    }
  ' "$themerc" > "$tmp"
  mv "$tmp" "$themerc"
}

accent="$(rgba_to_hex "$(scss_var panel-accent)")" || exit 0
border="$(rgba_to_hex "$(scss_var window-border-accent)")" || border="$accent"
header="$(rgba_to_hex "$(scss_var panel-header)")" || printf '%s\n' "#F2F2F2"
subtext="$(rgba_to_hex "$(scss_var panel-subtext)")" || printf '%s\n' "#8C8C8C"
border_width="$(cat "$state_dir/window-border-width" 2>/dev/null || echo 2)"
[[ "$border_width" =~ ^[0-9]+$ ]] || border_width=2
[ "$border_width" -lt 0 ] && border_width=0
[ "$border_width" -gt 8 ] && border_width=8

set_theme_value "menu.title.text.color" "$accent"
set_theme_value "menu.items.text.color" "$header"
set_theme_value "menu.items.active.text.color" "$accent"
set_theme_value "menu.items.disabled.text.color" "$subtext"
if [ -f "$game_state" ] || [ -f "$state_dir/window-border-off" ]; then
  set_theme_value "border.width" "0"
  set_theme_value "padding.height" "0"
  set_theme_value "padding.width" "0"
  set_theme_value "window.active.border.color" "#111111"
else
  set_theme_value "border.width" "$border_width"
  set_theme_value "padding.height" "0"
  set_theme_value "padding.width" "0"
  set_theme_value "window.active.border.color" "$border"
fi
set_theme_value "window.active.title.separator.color" "$accent"
set_theme_value "window.active.button.*.image.color" "$accent"
set_theme_value "window.active.button.hover.image.color" "#FFFFFF"
set_theme_value "window.active.button.pressed.bg.color" "$accent"
set_theme_value "window.active.button.pressed.image.color" "#0F0F0F"
set_theme_value "osd.border.color" "$accent"
set_theme_value "osd.active.label.text.color" "$accent"
set_theme_value "osd.hilight.bg.color" "$accent"

openbox --reconfigure >/dev/null 2>&1 || true

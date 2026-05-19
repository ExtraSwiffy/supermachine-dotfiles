#!/usr/bin/env bash
set -euo pipefail

slot="${1:-preset}"
mode="${2:-cycle}"
scss="$HOME/.config/eww/eww.scss"
state_dir="$HOME/.config/eww/state"
state_file="$state_dir/glow-off"
preset_file="$state_dir/glow-preset"

palette=(
  "rgba(55, 210, 255, 0.54)"
  "rgba(136, 192, 208, 0.95)"
  "rgba(163, 104, 255, 0.72)"
  "rgba(255, 91, 180, 0.54)"
  "rgba(235, 245, 255, 0.66)"
  "rgba(98, 72, 180, 0.72)"
  "rgba(255, 127, 54, 0.62)"
  "rgba(255, 62, 62, 0.58)"
  "rgba(255, 214, 77, 0.5)"
  "rgba(72, 255, 158, 0.52)"
  "rgba(46, 255, 230, 0.54)"
  "rgba(92, 144, 255, 0.62)"
  "rgba(255, 58, 140, 0.58)"
  "rgba(0, 0, 0, 0.34)"
  "rgba(255, 255, 255, 0.12)"
)

color_value() {
  case "$1" in
    cyan) printf '%s\n' "rgba(55, 210, 255, 0.54)" ;;
    ice) printf '%s\n' "rgba(136, 192, 208, 0.95)" ;;
    purple) printf '%s\n' "rgba(163, 104, 255, 0.72)" ;;
    pink) printf '%s\n' "rgba(255, 91, 180, 0.54)" ;;
    white) printf '%s\n' "rgba(235, 245, 255, 0.66)" ;;
    violet) printf '%s\n' "rgba(98, 72, 180, 0.72)" ;;
    orange) printf '%s\n' "rgba(255, 127, 54, 0.62)" ;;
    red) printf '%s\n' "rgba(255, 62, 62, 0.58)" ;;
    gold) printf '%s\n' "rgba(255, 214, 77, 0.5)" ;;
    green) printf '%s\n' "rgba(72, 255, 158, 0.52)" ;;
    teal) printf '%s\n' "rgba(46, 255, 230, 0.54)" ;;
    cobalt) printf '%s\n' "rgba(92, 144, 255, 0.62)" ;;
    magenta) printf '%s\n' "rgba(255, 58, 140, 0.58)" ;;
    pastel-cyan) printf '%s\n' "rgba(156, 232, 244, 0.68)" ;;
    pastel-blue) printf '%s\n' "rgba(170, 202, 255, 0.7)" ;;
    pastel-lavender) printf '%s\n' "rgba(205, 180, 255, 0.72)" ;;
    pastel-pink) printf '%s\n' "rgba(255, 174, 214, 0.68)" ;;
    pastel-peach) printf '%s\n' "rgba(255, 194, 153, 0.68)" ;;
    pastel-mint) printf '%s\n' "rgba(166, 245, 205, 0.68)" ;;
    bright-lime) printf '%s\n' "rgba(164, 255, 42, 0.7)" ;;
    bright-yellow) printf '%s\n' "rgba(255, 239, 64, 0.68)" ;;
    bright-aqua) printf '%s\n' "rgba(0, 255, 240, 0.68)" ;;
    bright-blue) printf '%s\n' "rgba(45, 126, 255, 0.72)" ;;
    bright-purple) printf '%s\n' "rgba(185, 72, 255, 0.72)" ;;
    bright-rose) printf '%s\n' "rgba(255, 42, 112, 0.68)" ;;
    black) printf '%s\n' "rgba(0, 0, 0, 0.34)" ;;
    clear) printf '%s\n' "rgba(255, 255, 255, 0.12)" ;;
    rgba*) printf '%s\n' "$1" ;;
    *) return 1 ;;
  esac
}

set_var() {
  local name="$1"
  local value="$2"

  if grep -qF "\$${name}:" "$scss"; then
    sed -i -E "s|^[$]${name}:.*;|\$${name}: ${value};|" "$scss"
  else
    sed -i "1i \$${name}: ${value};" "$scss"
  fi
}

set_panel_theme() {
  local accent="$1"
  local header="$2"
  local subtext="$3"

  set_var panel-accent "$accent"
  set_var panel-header "$header"
  set_var panel-subtext "$subtext"
  set_var panel-accent-muted "${accent%, *}, 0.07)"
  set_var panel-accent-soft "${accent%, *}, 0.18)"
  set_var panel-accent-hover "${accent%, *}, 0.24)"
  set_var panel-accent-dot "${accent%, *}, 0.28)"
}

set_glow_theme() {
  local c1="$1"
  local c2="$2"
  local c3="$3"
  local c4="$4"
  local edge="${5:-$1}"

  set_var settings-glow-cyan "$c1"
  set_var settings-glow-blue "$c2"
  set_var settings-glow-purple "$c3"
  set_var settings-glow-pink "$c4"
  set_var settings-glow-edge "$edge"
}

get_var() {
  local name="$1"
  awk -F': ' -v key="\$${name}" '$1 == key {sub(/;$/, "", $2); print $2; exit}' "$scss"
}

next_color() {
  local current="$1"
  local i

  for i in "${!palette[@]}"; do
    if [ "${palette[$i]}" = "$current" ]; then
      printf '%s\n' "${palette[$(((i + 1) % ${#palette[@]}))]}"
      return
    fi
  done

  printf '%s\n' "${palette[0]}"
}

reload_eww() {
  mkdir -p "$state_dir"
  rm -f "$state_file"
  eww update GLOW_STATE=on GLOW_PRESET="$(cat "$preset_file" 2>/dev/null || echo CUSTOM)" >/dev/null 2>&1 || true
  "$HOME/.config/eww/scripts/sync-openbox-theme.sh" >/dev/null 2>&1 || true

  if eww reload >/dev/null 2>&1; then
    notify-send "Panel Glow" "Updated settings glow." 2>/dev/null || true
  else
    notify-send "Panel Glow" "Could not reload Eww. Check eww.scss." 2>/dev/null || true
    exit 1
  fi
}

apply_preset() {
  case "$1" in
    default)
      preset_name="Default"
      set_glow_theme "rgba(55, 210, 255, 0.54)" "rgba(136, 192, 208, 0.95)" "rgba(163, 104, 255, 0.72)" "rgba(255, 91, 180, 0.54)" "rgba(55, 210, 255, 0.36)"
      set_panel_theme "rgba(136, 192, 208, 0.95)" "rgba(242, 242, 242, 1)" "rgba(140, 140, 140, 1)"
      ;;
    ice)
      preset_name="Ice"
      set_glow_theme "rgba(136, 192, 208, 0.42)" "rgba(202, 232, 240, 0.72)" "rgba(150, 170, 210, 0.42)" "rgba(255, 255, 255, 0.16)" "rgba(136, 192, 208, 0.24)"
      set_panel_theme "rgba(202, 232, 240, 0.92)" "rgba(235, 245, 255, 1)" "rgba(165, 183, 190, 1)"
      ;;
    neon)
      preset_name="Neon"
      set_glow_theme "rgba(55, 210, 255, 0.62)" "rgba(78, 166, 255, 0.72)" "rgba(170, 90, 255, 0.76)" "rgba(255, 91, 180, 0.6)" "rgba(55, 210, 255, 0.34)"
      set_panel_theme "rgba(55, 210, 255, 0.9)" "rgba(245, 248, 255, 1)" "rgba(166, 179, 195, 1)"
      ;;
    sunset)
      preset_name="Sunset"
      set_glow_theme "rgba(255, 127, 54, 0.62)" "rgba(255, 214, 77, 0.5)" "rgba(255, 62, 62, 0.58)" "rgba(255, 91, 180, 0.54)" "rgba(255, 127, 54, 0.28)"
      set_panel_theme "rgba(255, 127, 54, 0.9)" "rgba(255, 238, 220, 1)" "rgba(178, 143, 126, 1)"
      ;;
    matrix)
      preset_name="Matrix"
      set_glow_theme "rgba(72, 255, 158, 0.52)" "rgba(46, 255, 230, 0.54)" "rgba(72, 255, 158, 0.42)" "rgba(0, 0, 0, 0.34)" "rgba(72, 255, 158, 0.24)"
      set_panel_theme "rgba(72, 255, 158, 0.86)" "rgba(225, 255, 238, 1)" "rgba(126, 175, 145, 1)"
      ;;
    vapor)
      preset_name="Vapor"
      set_glow_theme "rgba(92, 144, 255, 0.62)" "rgba(163, 104, 255, 0.72)" "rgba(255, 58, 140, 0.58)" "rgba(46, 255, 230, 0.54)" "rgba(92, 144, 255, 0.28)"
      set_panel_theme "rgba(255, 58, 140, 0.82)" "rgba(250, 238, 255, 1)" "rgba(180, 150, 188, 1)"
      ;;
    aurora)
      preset_name="Aurora"
      set_glow_theme "rgba(72, 255, 158, 0.5)" "rgba(46, 255, 230, 0.52)" "rgba(92, 144, 255, 0.58)" "rgba(163, 104, 255, 0.58)" "rgba(72, 255, 158, 0.22)"
      set_panel_theme "rgba(46, 255, 230, 0.82)" "rgba(236, 255, 250, 1)" "rgba(135, 185, 176, 1)"
      ;;
    ember)
      preset_name="Ember"
      set_glow_theme "rgba(255, 127, 54, 0.58)" "rgba(255, 214, 77, 0.42)" "rgba(255, 62, 62, 0.52)" "rgba(255, 91, 180, 0.38)" "rgba(255, 127, 54, 0.22)"
      set_panel_theme "rgba(255, 127, 54, 0.84)" "rgba(255, 240, 226, 1)" "rgba(182, 146, 128, 1)"
      ;;
    ocean)
      preset_name="Ocean"
      set_glow_theme "rgba(55, 210, 255, 0.48)" "rgba(46, 255, 230, 0.46)" "rgba(92, 144, 255, 0.56)" "rgba(136, 192, 208, 0.64)" "rgba(55, 210, 255, 0.24)"
      set_panel_theme "rgba(55, 210, 255, 0.82)" "rgba(235, 250, 255, 1)" "rgba(134, 174, 186, 1)"
      ;;
    pastel-dream)
      preset_name="Pastel Dream"
      set_glow_theme "rgba(156, 232, 244, 0.68)" "rgba(170, 202, 255, 0.7)" "rgba(205, 180, 255, 0.72)" "rgba(255, 174, 214, 0.68)" "rgba(156, 232, 244, 0.28)"
      set_panel_theme "rgba(156, 232, 244, 0.9)" "rgba(245, 250, 255, 1)" "rgba(166, 176, 190, 1)"
      ;;
    pastel-sakura)
      preset_name="Pastel Sakura"
      set_glow_theme "rgba(255, 174, 214, 0.68)" "rgba(255, 194, 153, 0.68)" "rgba(205, 180, 255, 0.72)" "rgba(255, 174, 214, 0.68)" "rgba(255, 174, 214, 0.24)"
      set_panel_theme "rgba(255, 174, 214, 0.86)" "rgba(255, 244, 250, 1)" "rgba(190, 158, 176, 1)"
      ;;
    pastel-mint)
      preset_name="Pastel Mint"
      set_glow_theme "rgba(166, 245, 205, 0.68)" "rgba(156, 232, 244, 0.68)" "rgba(170, 202, 255, 0.7)" "rgba(235, 245, 255, 0.66)" "rgba(166, 245, 205, 0.24)"
      set_panel_theme "rgba(166, 245, 205, 0.86)" "rgba(238, 255, 247, 1)" "rgba(146, 184, 166, 1)"
      ;;
    pastel-cotton)
      preset_name="Pastel Cotton"
      set_glow_theme "rgba(156, 232, 244, 0.58)" "rgba(235, 245, 255, 0.56)" "rgba(255, 174, 214, 0.58)" "rgba(205, 180, 255, 0.58)" "rgba(156, 232, 244, 0.2)"
      set_panel_theme "rgba(156, 232, 244, 0.82)" "rgba(248, 252, 255, 1)" "rgba(166, 176, 190, 1)"
      ;;
    pastel-sherbet)
      preset_name="Pastel Sherbet"
      set_glow_theme "rgba(255, 194, 153, 0.62)" "rgba(255, 174, 214, 0.62)" "rgba(255, 239, 64, 0.32)" "rgba(166, 245, 205, 0.54)" "rgba(255, 194, 153, 0.22)"
      set_panel_theme "rgba(255, 194, 153, 0.82)" "rgba(255, 246, 238, 1)" "rgba(190, 164, 146, 1)"
      ;;
    pastel-orchid)
      preset_name="Pastel Orchid"
      set_glow_theme "rgba(205, 180, 255, 0.64)" "rgba(255, 174, 214, 0.6)" "rgba(170, 202, 255, 0.58)" "rgba(235, 245, 255, 0.5)" "rgba(205, 180, 255, 0.22)"
      set_panel_theme "rgba(205, 180, 255, 0.84)" "rgba(250, 246, 255, 1)" "rgba(170, 155, 190, 1)"
      ;;
    bright-candy)
      preset_name="Bright Candy"
      set_glow_theme "rgba(255, 42, 112, 0.68)" "rgba(255, 239, 64, 0.68)" "rgba(0, 255, 240, 0.68)" "rgba(185, 72, 255, 0.72)" "rgba(255, 42, 112, 0.3)"
      set_panel_theme "rgba(255, 42, 112, 0.9)" "rgba(255, 245, 250, 1)" "rgba(194, 148, 170, 1)"
      ;;
    bright-plasma)
      preset_name="Bright Plasma"
      set_glow_theme "rgba(0, 255, 240, 0.68)" "rgba(45, 126, 255, 0.72)" "rgba(185, 72, 255, 0.72)" "rgba(255, 42, 112, 0.68)" "rgba(0, 255, 240, 0.3)"
      set_panel_theme "rgba(0, 255, 240, 0.86)" "rgba(238, 255, 254, 1)" "rgba(132, 190, 190, 1)"
      ;;
    bright-arcade)
      preset_name="Bright Arcade"
      set_glow_theme "rgba(164, 255, 42, 0.7)" "rgba(0, 255, 240, 0.68)" "rgba(255, 239, 64, 0.68)" "rgba(255, 42, 112, 0.68)" "rgba(164, 255, 42, 0.28)"
      set_panel_theme "rgba(164, 255, 42, 0.82)" "rgba(246, 255, 235, 1)" "rgba(158, 190, 135, 1)"
      ;;
    bright-hyper)
      preset_name="Bright Hyper"
      set_glow_theme "rgba(0, 255, 240, 0.7)" "rgba(164, 255, 42, 0.68)" "rgba(255, 239, 64, 0.62)" "rgba(255, 42, 112, 0.64)" "rgba(0, 255, 240, 0.28)"
      set_panel_theme "rgba(0, 255, 240, 0.86)" "rgba(238, 255, 254, 1)" "rgba(132, 190, 190, 1)"
      ;;
    bright-rgb)
      preset_name="Bright RGB"
      set_glow_theme "rgba(255, 42, 112, 0.66)" "rgba(164, 255, 42, 0.66)" "rgba(45, 126, 255, 0.7)" "rgba(255, 239, 64, 0.58)" "rgba(255, 42, 112, 0.24)"
      set_panel_theme "rgba(164, 255, 42, 0.8)" "rgba(246, 255, 235, 1)" "rgba(158, 190, 135, 1)"
      ;;
    bright-spark)
      preset_name="Bright Spark"
      set_glow_theme "rgba(255, 239, 64, 0.7)" "rgba(255, 127, 54, 0.58)" "rgba(185, 72, 255, 0.68)" "rgba(0, 255, 240, 0.58)" "rgba(255, 239, 64, 0.24)"
      set_panel_theme "rgba(255, 239, 64, 0.8)" "rgba(255, 252, 220, 1)" "rgba(188, 180, 120, 1)"
      ;;
    static-cyan)
      preset_name="Static Cyan"
      set_glow_theme "rgba(55, 210, 255, 0.54)" "rgba(55, 210, 255, 0.54)" "rgba(55, 210, 255, 0.54)" "rgba(55, 210, 255, 0.54)" "rgba(55, 210, 255, 0.24)"
      set_panel_theme "rgba(55, 210, 255, 0.86)" "rgba(235, 250, 255, 1)" "rgba(132, 170, 182, 1)"
      ;;
    static-purple)
      preset_name="Static Purple"
      set_glow_theme "rgba(163, 104, 255, 0.72)" "rgba(163, 104, 255, 0.72)" "rgba(163, 104, 255, 0.72)" "rgba(163, 104, 255, 0.72)" "rgba(163, 104, 255, 0.26)"
      set_panel_theme "rgba(163, 104, 255, 0.82)" "rgba(244, 238, 255, 1)" "rgba(160, 145, 184, 1)"
      ;;
    static-pink)
      preset_name="Static Pink"
      set_glow_theme "rgba(255, 91, 180, 0.54)" "rgba(255, 91, 180, 0.54)" "rgba(255, 91, 180, 0.54)" "rgba(255, 91, 180, 0.54)" "rgba(255, 91, 180, 0.22)"
      set_panel_theme "rgba(255, 91, 180, 0.82)" "rgba(255, 238, 248, 1)" "rgba(184, 145, 168, 1)"
      ;;
    static-orange)
      preset_name="Static Orange"
      set_glow_theme "rgba(255, 127, 54, 0.62)" "rgba(255, 127, 54, 0.62)" "rgba(255, 127, 54, 0.62)" "rgba(255, 127, 54, 0.62)" "rgba(255, 127, 54, 0.24)"
      set_panel_theme "rgba(255, 127, 54, 0.88)" "rgba(255, 238, 220, 1)" "rgba(180, 145, 126, 1)"
      ;;
    static-red)
      preset_name="Static Red"
      set_glow_theme "rgba(255, 62, 62, 0.58)" "rgba(255, 62, 62, 0.58)" "rgba(255, 62, 62, 0.58)" "rgba(255, 62, 62, 0.58)" "rgba(255, 62, 62, 0.22)"
      set_panel_theme "rgba(255, 62, 62, 0.82)" "rgba(255, 235, 235, 1)" "rgba(184, 140, 140, 1)"
      ;;
    static-gold)
      preset_name="Static Gold"
      set_glow_theme "rgba(255, 214, 77, 0.5)" "rgba(255, 214, 77, 0.5)" "rgba(255, 214, 77, 0.5)" "rgba(255, 214, 77, 0.5)" "rgba(255, 214, 77, 0.2)"
      set_panel_theme "rgba(255, 214, 77, 0.78)" "rgba(255, 247, 220, 1)" "rgba(180, 165, 120, 1)"
      ;;
    static-teal)
      preset_name="Static Teal"
      set_glow_theme "rgba(46, 255, 230, 0.54)" "rgba(46, 255, 230, 0.54)" "rgba(46, 255, 230, 0.54)" "rgba(46, 255, 230, 0.54)" "rgba(46, 255, 230, 0.22)"
      set_panel_theme "rgba(46, 255, 230, 0.82)" "rgba(235, 255, 252, 1)" "rgba(130, 184, 178, 1)"
      ;;
    static-cobalt)
      preset_name="Static Cobalt"
      set_glow_theme "rgba(92, 144, 255, 0.62)" "rgba(92, 144, 255, 0.62)" "rgba(92, 144, 255, 0.62)" "rgba(92, 144, 255, 0.62)" "rgba(92, 144, 255, 0.24)"
      set_panel_theme "rgba(92, 144, 255, 0.82)" "rgba(235, 242, 255, 1)" "rgba(140, 158, 190, 1)"
      ;;
    static-clear)
      preset_name="Static Clear"
      set_glow_theme "rgba(255, 255, 255, 0.12)" "rgba(255, 255, 255, 0.12)" "rgba(255, 255, 255, 0.12)" "rgba(255, 255, 255, 0.12)" "rgba(255, 255, 255, 0.08)"
      set_panel_theme "rgba(180, 180, 180, 0.72)" "rgba(242, 242, 242, 1)" "rgba(150, 150, 150, 1)"
      ;;
    pastel-static-cyan)
      preset_name="Pastel Cyan"
      set_glow_theme "rgba(156, 232, 244, 0.68)" "rgba(156, 232, 244, 0.68)" "rgba(156, 232, 244, 0.68)" "rgba(156, 232, 244, 0.68)" "rgba(156, 232, 244, 0.24)"
      set_panel_theme "rgba(156, 232, 244, 0.86)" "rgba(245, 252, 255, 1)" "rgba(146, 178, 186, 1)"
      ;;
    pastel-static-peach)
      preset_name="Pastel Peach"
      set_glow_theme "rgba(255, 194, 153, 0.68)" "rgba(255, 194, 153, 0.68)" "rgba(255, 194, 153, 0.68)" "rgba(255, 194, 153, 0.68)" "rgba(255, 194, 153, 0.24)"
      set_panel_theme "rgba(255, 194, 153, 0.86)" "rgba(255, 246, 238, 1)" "rgba(190, 164, 146, 1)"
      ;;
    pastel-static-sky)
      preset_name="Pastel Sky"
      set_glow_theme "rgba(170, 202, 255, 0.7)" "rgba(170, 202, 255, 0.7)" "rgba(170, 202, 255, 0.7)" "rgba(170, 202, 255, 0.7)" "rgba(170, 202, 255, 0.24)"
      set_panel_theme "rgba(170, 202, 255, 0.86)" "rgba(246, 250, 255, 1)" "rgba(155, 170, 190, 1)"
      ;;
    pastel-static-lavender)
      preset_name="Pastel Lavender"
      set_glow_theme "rgba(205, 180, 255, 0.72)" "rgba(205, 180, 255, 0.72)" "rgba(205, 180, 255, 0.72)" "rgba(205, 180, 255, 0.72)" "rgba(205, 180, 255, 0.24)"
      set_panel_theme "rgba(205, 180, 255, 0.86)" "rgba(250, 246, 255, 1)" "rgba(170, 155, 190, 1)"
      ;;
    pastel-static-mint)
      preset_name="Pastel Mint Static"
      set_glow_theme "rgba(166, 245, 205, 0.68)" "rgba(166, 245, 205, 0.68)" "rgba(166, 245, 205, 0.68)" "rgba(166, 245, 205, 0.68)" "rgba(166, 245, 205, 0.24)"
      set_panel_theme "rgba(166, 245, 205, 0.86)" "rgba(238, 255, 247, 1)" "rgba(146, 184, 166, 1)"
      ;;
    pastel-static-rose)
      preset_name="Pastel Rose"
      set_glow_theme "rgba(255, 174, 214, 0.68)" "rgba(255, 174, 214, 0.68)" "rgba(255, 174, 214, 0.68)" "rgba(255, 174, 214, 0.68)" "rgba(255, 174, 214, 0.24)"
      set_panel_theme "rgba(255, 174, 214, 0.86)" "rgba(255, 244, 250, 1)" "rgba(190, 158, 176, 1)"
      ;;
    bright-static-lime)
      preset_name="Bright Lime"
      set_glow_theme "rgba(164, 255, 42, 0.7)" "rgba(164, 255, 42, 0.7)" "rgba(164, 255, 42, 0.7)" "rgba(164, 255, 42, 0.7)" "rgba(164, 255, 42, 0.24)"
      set_panel_theme "rgba(164, 255, 42, 0.82)" "rgba(246, 255, 235, 1)" "rgba(158, 190, 135, 1)"
      ;;
    bright-static-aqua)
      preset_name="Bright Aqua"
      set_glow_theme "rgba(0, 255, 240, 0.68)" "rgba(0, 255, 240, 0.68)" "rgba(0, 255, 240, 0.68)" "rgba(0, 255, 240, 0.68)" "rgba(0, 255, 240, 0.24)"
      set_panel_theme "rgba(0, 255, 240, 0.86)" "rgba(238, 255, 254, 1)" "rgba(132, 190, 190, 1)"
      ;;
    bright-static-rose)
      preset_name="Bright Rose"
      set_glow_theme "rgba(255, 42, 112, 0.68)" "rgba(255, 42, 112, 0.68)" "rgba(255, 42, 112, 0.68)" "rgba(255, 42, 112, 0.68)" "rgba(255, 42, 112, 0.24)"
      set_panel_theme "rgba(255, 42, 112, 0.86)" "rgba(255, 245, 250, 1)" "rgba(194, 148, 170, 1)"
      ;;
    bright-static-yellow)
      preset_name="Bright Yellow"
      set_glow_theme "rgba(255, 239, 64, 0.68)" "rgba(255, 239, 64, 0.68)" "rgba(255, 239, 64, 0.68)" "rgba(255, 239, 64, 0.68)" "rgba(255, 239, 64, 0.22)"
      set_panel_theme "rgba(255, 239, 64, 0.78)" "rgba(255, 252, 220, 1)" "rgba(188, 180, 120, 1)"
      ;;
    bright-static-blue)
      preset_name="Bright Blue"
      set_glow_theme "rgba(45, 126, 255, 0.72)" "rgba(45, 126, 255, 0.72)" "rgba(45, 126, 255, 0.72)" "rgba(45, 126, 255, 0.72)" "rgba(45, 126, 255, 0.26)"
      set_panel_theme "rgba(45, 126, 255, 0.86)" "rgba(235, 244, 255, 1)" "rgba(132, 158, 194, 1)"
      ;;
    bright-static-purple)
      preset_name="Bright Purple"
      set_glow_theme "rgba(185, 72, 255, 0.72)" "rgba(185, 72, 255, 0.72)" "rgba(185, 72, 255, 0.72)" "rgba(185, 72, 255, 0.72)" "rgba(185, 72, 255, 0.26)"
      set_panel_theme "rgba(185, 72, 255, 0.86)" "rgba(248, 238, 255, 1)" "rgba(170, 142, 194, 1)"
      ;;
    *) exit 0 ;;
  esac

  mkdir -p "$state_dir"
  printf '%s\n' "$preset_name" > "$preset_file"
}

case "$slot" in
  1) var="settings-glow-cyan" ;;
  2) var="settings-glow-blue" ;;
  3) var="settings-glow-purple" ;;
  4) var="settings-glow-pink" ;;
  accent) var="panel-accent" ;;
  header) var="panel-header" ;;
  subtext) var="panel-subtext" ;;
  preset)
    apply_preset "$mode"
    reload_eww
    exit 0
    ;;
  *) exit 1 ;;
esac

case "$mode" in
  cycle)
    current="$(get_var "$var")"
    set_var "$var" "$(next_color "$current")"
    ;;
  *)
    value="$(color_value "$mode")" || exit 0
    set_var "$var" "$value"
    if [ "$slot" = "accent" ]; then
      set_var panel-accent-muted "${value%, *}, 0.07)"
      set_var panel-accent-soft "${value%, *}, 0.18)"
      set_var panel-accent-hover "${value%, *}, 0.24)"
      set_var panel-accent-dot "${value%, *}, 0.28)"
    fi
    mkdir -p "$state_dir"
    printf '%s\n' "CUSTOM" > "$preset_file"
    ;;
esac

reload_eww

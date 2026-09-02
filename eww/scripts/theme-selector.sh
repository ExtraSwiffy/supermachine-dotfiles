#!/usr/bin/env bash
set -euo pipefail

mode="${1:-theme}"
action="${2:-open}"
field="${3:-}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
theme_root="$config_home/supermachine/themes"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/supermachine"
theme_state="$state_dir/active-theme"
theme_index="$state_dir/theme-picker-index"
wallpaper_index="$state_dir/wallpaper-picker-index"

mkdir -p "$state_dir"
mapfile -t themes < <(find "$theme_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
[ "${#themes[@]}" -gt 0 ] || exit 1

read_index() {
  local file="$1" max="$2" value
  value="$(cat "$file" 2>/dev/null || echo 0)"
  [[ "$value" =~ ^[0-9]+$ ]] || value=0
  printf '%s\n' "$((value % max))"
}

ensure_eww() {
  local attempt
  if ! eww ping >/dev/null 2>&1; then
    systemctl --user start supermachine-eww.service >/dev/null 2>&1 || \
      setsid -f eww daemon >/dev/null 2>&1
  fi
  for attempt in {1..20}; do
    eww ping >/dev/null 2>&1 && return 0
    sleep 0.1
  done
  notify-send "Theme picker" "Eww could not start." 2>/dev/null || true
  return 1
}

close_window() {
  local window="$1" attempt
  eww close "$window" >/dev/null 2>&1 || true
  for attempt in {1..20}; do
    if ! eww active-windows 2>/dev/null | grep -q "^${window}:"; then
      return 0
    fi
    sleep 0.05
  done
  return 1
}

theme_info() {
  local index slug conf preview
  index="$(read_index "$theme_index" "${#themes[@]}")"
  slug="${themes[index]}"
  conf="$theme_root/$slug/theme.conf"
  # shellcheck disable=SC1090
  source "$conf"
  preview="$theme_root/$slug/wallpapers/$THEME_WALLPAPER"
  case "$field" in
    name) printf '%s\n' "$THEME_NAME" ;;
    tagline) printf '%s\n' "$THEME_TAGLINE" ;;
    preview) printf '%s\n' "$preview" ;;
    previous-preview)
      local previous=$(((index - 1 + ${#themes[@]}) % ${#themes[@]}))
      source "$theme_root/${themes[previous]}/theme.conf"
      printf '%s\n' "$theme_root/${themes[previous]}/wallpapers/$THEME_WALLPAPER"
      ;;
    next-preview)
      local next=$(((index + 1) % ${#themes[@]}))
      source "$theme_root/${themes[next]}/theme.conf"
      printf '%s\n' "$theme_root/${themes[next]}/wallpapers/$THEME_WALLPAPER"
      ;;
  esac
}

set_scss_var() {
  local file="$1" name="$2" value="$3" tmp
  tmp="$(mktemp)"
  awk -v key="\$${name}:" -v line="\$${name}: ${value};" '
    index($0, key) == 1 { if (!done) print line; done=1; next }
    { print }
    END { if (!done) print line }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

apply_theme() {
  local index slug conf scss scss_work polybar wallpaper
  index="$(read_index "$theme_index" "${#themes[@]}")"
  slug="${themes[index]}"
  conf="$theme_root/$slug/theme.conf"
  source "$conf"
  scss="$config_home/eww/eww.scss"
  polybar="$config_home/polybar/config.ini"
  wallpaper="$theme_root/$slug/wallpapers/$THEME_WALLPAPER"

  # Close first: changing SCSS while this window is open makes Eww hot-reload
  # and resurrect the chooser before the old apply sequence can close it.
  close_window themechooser

  scss_work="$(mktemp)"
  cp "$scss" "$scss_work"
  set_scss_var "$scss_work" panel-accent "$THEME_ACCENT_RGBA"
  set_scss_var "$scss_work" window-border-accent "$THEME_ACCENT_RGBA"
  set_scss_var "$scss_work" settings-glow-cyan "$THEME_ACCENT_RGBA"
  set_scss_var "$scss_work" settings-glow-blue "$THEME_ACCENT_RGBA"
  set_scss_var "$scss_work" settings-glow-purple "$THEME_ACCENT_RGBA"
  set_scss_var "$scss_work" settings-glow-pink "$THEME_ACCENT_RGBA"
  set_scss_var "$scss_work" settings-glow-edge "$THEME_ACCENT_EDGE"
  set_scss_var "$scss_work" panel-accent-muted "$THEME_ACCENT_MUTED"
  set_scss_var "$scss_work" panel-accent-soft "$THEME_ACCENT_SOFT"
  set_scss_var "$scss_work" panel-accent-hover "$THEME_ACCENT_HOVER"
  set_scss_var "$scss_work" panel-accent-dot "$THEME_ACCENT_DOT"
  set_scss_var "$scss_work" panel-header "$THEME_HEADER_RGBA"
  set_scss_var "$scss_work" panel-subtext "$THEME_SUBTEXT_RGBA"
  set_scss_var "$scss_work" settings-panel-bg "$THEME_PANEL_RGBA"
  mv "$scss_work" "$scss"

  sed -i \
    -e "s|^background = .*|background = $THEME_POLYBAR_BG|" \
    -e "s|^foreground = .*|foreground = $THEME_POLYBAR_FG|" \
    -e "s|^muted = .*|muted = $THEME_POLYBAR_MUTED|" \
    -e "s|^accent = .*|accent = $THEME_POLYBAR_ACCENT|" "$polybar"

  printf '%s\n' "$slug" > "$theme_state"
  "$config_home/eww/scripts/apply-wallpaper.sh" "$wallpaper"
  "$config_home/eww/scripts/sync-openbox-theme.sh" >/dev/null 2>&1 || true
  eww reload >/dev/null 2>&1 || true
  systemctl --user restart supermachine-polybar.service >/dev/null 2>&1 || true
  notify-send "Theme applied" "$THEME_NAME" 2>/dev/null || true
}

wallpaper_info() {
  local slug index name
  slug="$(cat "$theme_state" 2>/dev/null || echo default)"
  [ -d "$theme_root/$slug" ] || slug=default
  mapfile -t wallpapers < <(find "$theme_root/$slug/wallpapers" -maxdepth 1 -type f -iname '*.png' | sort)
  index="$(read_index "$wallpaper_index" "${#wallpapers[@]}")"
  case "$field" in
    name)
      name="${wallpapers[index]##*/}"
      name="${name%.png}"
      printf '%s\n' "${name//-/ }"
      ;;
    preview) printf '%s\n' "${wallpapers[index]}" ;;
  esac
}

case "$mode:$action" in
  theme:open)
    ensure_eww
    close_window wallpaperchooser || true
    close_window themechooser || true
    eww open themechooser
    ;;
  theme:next|theme:previous)
    index="$(read_index "$theme_index" "${#themes[@]}")"
    [ "$action" = next ] && index=$(((index + 1) % ${#themes[@]})) || index=$(((index - 1 + ${#themes[@]}) % ${#themes[@]}))
    printf '%s\n' "$index" > "$theme_index"
    ;;
  theme:info) theme_info ;;
  theme:apply) apply_theme ;;
  wallpaper:open)
    ensure_eww
    printf '0\n' > "$wallpaper_index"
    close_window themechooser || true
    close_window wallpaperchooser || true
    eww open wallpaperchooser
    ;;
  wallpaper:next|wallpaper:previous)
    slug="$(cat "$theme_state" 2>/dev/null || echo default)"
    mapfile -t wallpapers < <(find "$theme_root/$slug/wallpapers" -maxdepth 1 -type f -iname '*.png' | sort)
    index="$(read_index "$wallpaper_index" "${#wallpapers[@]}")"
    [ "$action" = next ] && index=$(((index + 1) % ${#wallpapers[@]})) || index=$(((index - 1 + ${#wallpapers[@]}) % ${#wallpapers[@]}))
    printf '%s\n' "$index" > "$wallpaper_index"
    ;;
  wallpaper:info) wallpaper_info ;;
  wallpaper:apply)
    selected="$($0 wallpaper info preview)"
    "$config_home/eww/scripts/apply-wallpaper.sh" "$selected"
    close_window wallpaperchooser
    ;;
esac

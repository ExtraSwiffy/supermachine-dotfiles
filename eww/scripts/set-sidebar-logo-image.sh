#!/usr/bin/env bash
set -euo pipefail

input="${1:-choose}"
cfg="${EWW_CONFIG_DIR:-$HOME/.config/eww}"
state_dir="$cfg/state"
asset_dir="$cfg/assets/logos"
mode_file="$state_dir/sidebar-logo-mode"
image_file="$state_dir/sidebar-logo-image"
placeholder="$asset_dir/placeholder.svg"

mkdir -p "$state_dir" "$asset_dir"

choose_file() {
  if command -v rofi >/dev/null 2>&1; then
    {
      find "$cfg/assets/logos/presets" "$HOME/Pictures" "$HOME/Downloads" "$HOME/.config/eww/assets/logos" \
        -maxdepth 3 -type f \( \
          -iname '*.gif' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.svg' \
        \) 2>/dev/null
      printf '%s\n' "Type a custom path..."
    } | rofi -dmenu -i -p "Sidebar image/GIF" 2>/dev/null |
      while IFS= read -r choice; do
        if [ "$choice" = "Type a custom path..." ]; then
          rofi -dmenu -p "Image path" 2>/dev/null || true
        else
          printf '%s\n' "$choice"
        fi
      done
    return
  fi

  if command -v zenity >/dev/null 2>&1; then
    zenity --file-selection \
      --title="Choose sidebar logo" \
      --file-filter="Images | *.gif *.png *.jpg *.jpeg *.webp *.svg" 2>/dev/null || true
    return
  fi

  if command -v kdialog >/dev/null 2>&1; then
    kdialog --getopenfilename "$HOME" \
      "image/gif image/png image/jpeg image/webp image/svg+xml" 2>/dev/null || true
    return
  fi
}

case "$input" in
  reset|glyph|text)
    printf '%s\n' "glyph" > "$mode_file"
    printf '%s\n' "$placeholder" > "$image_file"
    eww -c "$cfg" update SIDEBAR_LOGO_MODE="glyph" SIDEBAR_LOGO_IMAGE="$placeholder" >/dev/null 2>&1 || true
    exit 0
    ;;
  choose)
    src="$(choose_file)"
    ;;
  preset)
    name="${2:-pulse-orb}"
    src="$asset_dir/presets/${name}.gif"
    [ -f "$src" ] || exit 0
    ;;
  *)
    src="$input"
    ;;
esac

[ -n "${src:-}" ] || exit 0
src="${src/#\~/$HOME}"
[ -f "$src" ] || exit 0

case "${src##*.}" in
  gif|GIF) ext="gif" ;;
  png|PNG) ext="png" ;;
  jpg|JPG|jpeg|JPEG) ext="jpg" ;;
  webp|WEBP) ext="webp" ;;
  svg|SVG) ext="svg" ;;
  *) exit 0 ;;
esac

dest="$asset_dir/sidebar-logo-current.$ext"

if command -v magick >/dev/null 2>&1 && [ "$ext" != "svg" ]; then
  magick "$src" -coalesce -resize '72x72>' -layers optimize "$dest"
else
  cp "$src" "$dest"
fi

printf '%s\n' "image" > "$mode_file"
printf '%s\n' "$dest" > "$image_file"

eww -c "$cfg" update SIDEBAR_LOGO_MODE="image" SIDEBAR_LOGO_IMAGE="$dest" >/dev/null 2>&1 || true

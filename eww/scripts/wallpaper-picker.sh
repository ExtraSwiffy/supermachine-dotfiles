#!/usr/bin/env bash
set -euo pipefail

if [ "${WALLPAPER_PICKER_DETACHED:-0}" != "1" ]; then
  setsid -f env WALLPAPER_PICKER_DETACHED=1 "$0" "$@" >/tmp/supermachine-wallpaper-picker.log 2>&1
  exit 0
fi

wallpaper_dir="$HOME/Pictures/wallpapers"
[ -d "$wallpaper_dir" ] || wallpaper_dir="$HOME/Pictures"
[ -d "$wallpaper_dir" ] || wallpaper_dir="$HOME"

pick_with_zenity() {
  zenity \
    --file-selection \
    --title="Choose Wallpaper" \
    --filename="$wallpaper_dir/" \
    --file-filter="Images | *.jpg *.jpeg *.png *.webp *.bmp" \
    --file-filter="All files | *"
}

pick_with_kdialog() {
  kdialog --getopenfilename "$wallpaper_dir" "image/jpeg image/png image/webp image/bmp"
}

pick_with_yad() {
  yad \
    --file-selection \
    --title="Choose Wallpaper" \
    --filename="$wallpaper_dir/" \
    --file-filter="Images | *.jpg *.jpeg *.png *.webp *.bmp"
}

pick_with_rofi() {
  find "$wallpaper_dir" "$HOME/Pictures" "$HOME/Downloads" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
    2>/dev/null |
    awk '!seen[$0]++' |
    rofi -dmenu -i -p "Wallpaper"
}

open_file_manager() {
  if command -v dolphin >/dev/null 2>&1; then
    setsid -f dolphin "$wallpaper_dir" >/dev/null 2>&1
  elif command -v xdg-open >/dev/null 2>&1; then
    setsid -f xdg-open "$wallpaper_dir" >/dev/null 2>&1
  fi
}

wallpaper=""

if command -v zenity >/dev/null 2>&1; then
  wallpaper="$(pick_with_zenity || true)"
fi

if [ -z "$wallpaper" ] && command -v kdialog >/dev/null 2>&1; then
  wallpaper="$(pick_with_kdialog || true)"
fi

if [ -z "$wallpaper" ] && command -v yad >/dev/null 2>&1; then
  wallpaper="$(pick_with_yad || true)"
fi

if [ -z "$wallpaper" ] && command -v rofi >/dev/null 2>&1; then
  wallpaper="$(pick_with_rofi || true)"
fi

if [ -z "$wallpaper" ]; then
  open_file_manager
  notify-send "Wallpaper" "Opened wallpapers folder. Install zenity, kdialog, or yad for a native file picker." 2>/dev/null || true
  exit 0
fi

[ -f "$wallpaper" ] || exit 1

case "${wallpaper,,}" in
  *.jpg|*.jpeg|*.png|*.webp|*.bmp) ;;
  *)
    notify-send "Wallpaper" "Selected file is not a supported image." 2>/dev/null || true
    exit 1
    ;;
esac

feh --bg-scale "$wallpaper"
chmod +x "$HOME/.fehbg" 2>/dev/null || true
notify-send "Wallpaper" "Wallpaper updated." 2>/dev/null || true

#!/usr/bin/env bash
set -euo pipefail

wallpaper="${1:-}"
[ -f "$wallpaper" ] || exit 1

feh --bg-fill "$wallpaper" "$wallpaper"

settings_file="${XDG_CONFIG_HOME:-$HOME/.config}/supermachine/settings.conf"
if [ -f "$settings_file" ]; then
  tmp="$(mktemp)"
  awk -v wallpaper="$wallpaper" '
    /^SUPERMACHINE_WALLPAPER=/ {
      gsub(/\\/, "\\\\", wallpaper)
      gsub(/"/, "\\\"", wallpaper)
      print "SUPERMACHINE_WALLPAPER=\"" wallpaper "\""
      found=1
      next
    }
    { print }
    END { if (!found) print "SUPERMACHINE_WALLPAPER=\"" wallpaper "\"" }
  ' "$settings_file" > "$tmp"
  mv "$tmp" "$settings_file"
fi

chmod +x "$HOME/.fehbg" 2>/dev/null || true

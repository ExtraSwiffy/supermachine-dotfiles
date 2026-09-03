#!/usr/bin/env bash
set -euo pipefail

wallpaper="${1:-}"
[ -f "$wallpaper" ] || exit 1

# feh's Xinerama sizing does not account for a rotated output reliably. Build
# one root image from the logical xrandr rectangles so every monitor receives
# its own filled crop of the same wallpaper, including portrait displays.
mapfile -t monitor_rects < <(
  xrandr --query | awk '
    / connected/ {
      for (i = 1; i <= NF; i++)
        if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) print $i
    }
  '
)

if command -v magick >/dev/null 2>&1 && [ "${#monitor_rects[@]}" -gt 0 ]; then
  composite_dir="$(mktemp -d)"
  trap 'rm -rf "$composite_dir"' EXIT
  canvas_width=0
  canvas_height=0

  for rect in "${monitor_rects[@]}"; do
    IFS='x+' read -r width height offset_x offset_y <<< "$rect"
    ((offset_x + width > canvas_width)) && canvas_width=$((offset_x + width))
    ((offset_y + height > canvas_height)) && canvas_height=$((offset_y + height))
  done

  magick -size "${canvas_width}x${canvas_height}" xc:'#000000' \
    -colorspace sRGB -type TrueColor "PNG24:$composite_dir/root.png"
  index=0
  for rect in "${monitor_rects[@]}"; do
    IFS='x+' read -r width height offset_x offset_y <<< "$rect"
    magick "$wallpaper" -colorspace sRGB -type TrueColor \
      -resize "${width}x${height}^" -gravity center \
      -extent "${width}x${height}" "PNG24:$composite_dir/monitor-${index}.png"
    magick "$composite_dir/root.png" "$composite_dir/monitor-${index}.png" \
      -geometry "+${offset_x}+${offset_y}" -composite \
      "PNG24:$composite_dir/root-next.png"
    mv "$composite_dir/root-next.png" "$composite_dir/root.png"
    index=$((index + 1))
  done
  magick "$composite_dir/root.png" -colorspace sRGB -type TrueColor \
    "PNG24:$composite_dir/root-color.png"
  feh --no-xinerama --no-fehbg --bg-center "$composite_dir/root-color.png"
else
  feh --bg-fill "$wallpaper" "$wallpaper"
fi

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

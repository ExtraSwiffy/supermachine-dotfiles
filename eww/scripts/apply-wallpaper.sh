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
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/supermachine"
  cache_image="$cache_dir/wallpaper-root.ppm"
  cache_key_file="$cache_dir/wallpaper-root.key"
  mkdir -p "$cache_dir"
  canvas_width=0
  canvas_height=0

  for rect in "${monitor_rects[@]}"; do
    IFS='x+' read -r width height offset_x offset_y <<< "$rect"
    ((offset_x + width > canvas_width)) && canvas_width=$((offset_x + width))
    ((offset_y + height > canvas_height)) && canvas_height=$((offset_y + height))
  done

  # Include the source's identity and the complete display layout in the key.
  # A cached root image makes reapplying the same choice effectively instant.
  source_key="$(stat -Lc '%n:%s:%Y' "$wallpaper")"
  cache_key="v2|$source_key|${monitor_rects[*]}"

  if [ ! -s "$cache_image" ] || [ "$(cat "$cache_key_file" 2>/dev/null || true)" != "$cache_key" ]; then
    tmp_image="$(mktemp "$cache_dir/wallpaper-root.XXXXXX.ppm")"
    composite_dir="$(mktemp -d "$cache_dir/wallpaper-build.XXXXXX")"
    trap 'rm -f "${tmp_image:-}"; rm -rf "${composite_dir:-}"' EXIT

    # Keep each crop independent so rotated and differently sized displays
    # retain the placement behavior of the original implementation. MIFF is
    # used only for temporary working images: unlike PNG it does not spend
    # seconds compressing every intermediate full-desktop canvas.
    magick -size "${canvas_width}x${canvas_height}" xc:'#000000' \
      -colorspace sRGB -type TrueColor "MIFF:$composite_dir/root.miff"
    index=0
    for rect in "${monitor_rects[@]}"; do
      IFS='x+' read -r width height offset_x offset_y <<< "$rect"
      magick "$wallpaper" -colorspace sRGB -type TrueColor \
        -resize "${width}x${height}^" -gravity center \
        -extent "${width}x${height}" "MIFF:$composite_dir/monitor.miff"
      magick "$composite_dir/root.miff" "$composite_dir/monitor.miff" \
        -geometry "+${offset_x}+${offset_y}" -composite \
        "MIFF:$composite_dir/root-next.miff"
      mv "$composite_dir/root-next.miff" "$composite_dir/root.miff"
      index=$((index + 1))
    done
    magick "$composite_dir/root.miff" -colorspace sRGB -type TrueColor \
      "PPM:$tmp_image"
    mv "$tmp_image" "$cache_image"
    printf '%s\n' "$cache_key" > "$cache_key_file"
    rm -rf "$composite_dir"
    trap - EXIT
  fi

  feh --no-xinerama --no-fehbg --bg-center "$cache_image"
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

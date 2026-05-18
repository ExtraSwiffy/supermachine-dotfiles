#!/bin/bash
set -euo pipefail

target_output="${1:-}"

selection="$(
  xrandr --query |
    awk '
      / connected/ { output = $1 }
      /^[[:space:]]+[0-9]+x[0-9]+/ {
        mode = $1
        for (i = 2; i <= NF; i++) {
          if ($i ~ /^[0-9.]+[*+]*$/) {
            rate = $i
            gsub(/[*+]/, "", rate)
            print output "  " mode "  " rate "Hz"
          }
        }
      }
    ' |
    { if [ -n "$target_output" ]; then grep "^$target_output  " || true; else cat; fi; } |
    rofi -dmenu -i -p "${target_output:-Display Mode}"
)"

[ -n "${selection:-}" ] || exit 0

output="$(awk '{print $1}' <<< "$selection")"
mode="$(awk '{print $2}' <<< "$selection")"
rate="$(awk '{print $3}' <<< "$selection" | sed 's/Hz$//')"

xrandr --output "$output" --mode "$mode" --rate "$rate"

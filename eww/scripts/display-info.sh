#!/usr/bin/env bash
set -euo pipefail

kind="${1:-summary}"
index="${2:-1}"

case "$index" in
  ''|*[!0-9]*) index=1 ;;
esac

case "$kind" in
  summary)
    xrandr --query 2>/dev/null |
      awk '
        / connected/ {
          geometry = "connected"
          for (i = 3; i <= NF; i++) {
            if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
              geometry = $i
              break
            }
          }
          print $1 "  " geometry
        }
      ' |
      paste -sd '    ' -
    ;;
  name)
    xrandr --query 2>/dev/null |
      awk -v wanted="$index" '/ connected/ {count++; if (count == wanted) {print $1; found=1; exit}} END {if (!found) print "Display-" wanted}'
    ;;
  mode)
    xrandr --query 2>/dev/null |
      awk -v wanted="$index" '
        / connected/ {
          count++
          active = count == wanted
          if (active) found = 1
          next
        }
        active && /^[[:space:]]+[0-9]+x[0-9]+/ && /\*/ {
          rate = ""
          for (i = 2; i <= NF; i++) {
            if ($i ~ /\*/) {
              rate = $i
              gsub(/[*+]/, "", rate)
              break
            }
          }
          print $1 " @ " rate "Hz"
          shown = 1
          exit
        }
        END {
          if (!found) print "disconnected"
          else if (!shown) print "connected"
        }
      '
    ;;
  *) exit 1 ;;
esac

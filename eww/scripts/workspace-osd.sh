#!/usr/bin/env bash
set -u

lock_file="/tmp/supermachine-workspace-osd.lock"
generation_file="/tmp/supermachine-workspace-osd-generation"

exec 9>"$lock_file"
flock -n 9 || exit 0

current_desktop() {
  xprop -root _NET_CURRENT_DESKTOP 2>/dev/null | awk -F' = ' 'NF > 1 {print $2 + 1; exit}'
}

previous="$(current_desktop)"
[ -n "$previous" ] || previous=1
generation=0

xprop -spy -root _NET_CURRENT_DESKTOP 2>/dev/null | while IFS= read -r property; do
  desktop="$(awk -F' = ' 'NF > 1 {print $2 + 1; exit}' <<<"$property")"
  [ -n "$desktop" ] || continue
  [ "$desktop" != "$previous" ] || continue

  if [ "$desktop" -gt "$previous" ]; then
    direction="›"
  else
    direction="‹"
  fi
  previous="$desktop"

  # Update desktop decorations immediately on a workspace change. The
  # separate visibility watcher still handles apps opening/closing/moving.
  "$HOME/.config/eww/scripts/fable-countdown.sh" sync >/dev/null 2>&1 || true

  # Game mode deliberately suppresses transient desktop overlays.
  [ -e "$HOME/.cache/eww-gamemode" ] && continue

  systemctl --user start supermachine-eww.service >/dev/null 2>&1 || \
    (pgrep -x eww >/dev/null 2>&1 || setsid -f eww daemon >/dev/null 2>&1)

  display="$(printf '%02d' "$desktop")"
  eww update WORKSPACE_OSD_NUMBER="$desktop" WORKSPACE_OSD_DISPLAY="$display" \
    WORKSPACE_OSD_DIRECTION="$direction" >/dev/null 2>&1 || continue
  eww open workspaceosd >/dev/null 2>&1 || continue

  generation=$((generation + 1))
  printf '%s\n' "$generation" >"$generation_file"
  (
    this_generation="$generation"
    sleep 0.9
    [ "$(cat "$generation_file" 2>/dev/null)" = "$this_generation" ] && \
      eww close workspaceosd >/dev/null 2>&1
  ) &
done

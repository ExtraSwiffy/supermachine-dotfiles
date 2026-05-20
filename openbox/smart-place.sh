#!/usr/bin/env bash
set -euo pipefail

gap="${SUPERMACHINE_WINDOW_GAP:-5}"
bottom_gap="${SUPERMACHINE_WINDOW_BOTTOM_GAP:-12}"
sidebar_width="${SUPERMACHINE_SIDEBAR_WIDTH:-90}"
right_edge_bleed="${SUPERMACHINE_WINDOW_RIGHT_EDGE_BLEED:-1}"
placement_inset="${SUPERMACHINE_WINDOW_PLACEMENT_INSET:-1}"
poll_interval="${SUPERMACHINE_SMART_PLACE_POLL:-1}"
fullscreen_override="/tmp/supermachine-fullscreen-sidebar-override"
state_dir="$HOME/.config/eww/state"
gap_file="$state_dir/window-gap"
sidebar_width_file="$state_dir/sidebar-width"
tiling_off_file="$state_dir/smart-tiling-off"

case "${1:-}" in
  --once|--left|--right|--up|--down|--upper-left|--upper-right|--lower-left|--lower-right) ;;
  *)
    exec 9>/tmp/supermachine-smart-place.lock
    flock -n 9 || exit 0
    ;;
esac

current_desktop() {
  wmctrl -d | awk '$2 == "*" {print $1; exit}'
}

update_runtime_settings() {
  local saved_gap saved_sidebar_width

  saved_gap="$(cat "$gap_file" 2>/dev/null || true)"
  if [[ "$saved_gap" =~ ^[0-9]+$ ]] && [ "$saved_gap" -ge 0 ] && [ "$saved_gap" -le 40 ]; then
    gap="$saved_gap"
  fi
  bottom_gap="$gap"
  [ "$right_edge_bleed" -gt "$((gap - 2))" ] && right_edge_bleed=$((gap - 2))
  [ "$right_edge_bleed" -lt 0 ] && right_edge_bleed=0
  [ "$placement_inset" -lt 0 ] && placement_inset=0
  [ "$placement_inset" -gt 4 ] && placement_inset=4

  saved_sidebar_width="$(cat "$sidebar_width_file" 2>/dev/null || true)"
  if [[ "$saved_sidebar_width" =~ ^[0-9]+$ ]] && [ "$saved_sidebar_width" -ge 85 ] && [ "$saved_sidebar_width" -le 130 ]; then
    sidebar_width="$saved_sidebar_width"
  fi
}

smart_tiling_enabled() {
  [ ! -f "$tiling_off_file" ]
}

workarea() {
  wmctrl -d |
    awk '$2 == "*" {
      for (i = 1; i <= NF; i++) {
        if ($i == "WA:") {
          split($(i + 1), pos, ",")
          split($(i + 2), size, "x")
          print pos[1], pos[2], size[1], size[2]
          exit
        }
      }
    }'
}

normalize_id() {
  awk '{ id = tolower($1); sub(/^0x0*/, "0x", id); print id; }' <<< "$1"
}

active_monitor_area() {
  local wx="$1"
  local wy="$2"
  local ww="$3"
  local wh="$4"
  local desktop="$5"
  local focus_id="${6:-}"
  local target_x target_y monitor

  target_x="$wx"
  target_y="$wy"

  monitor="$(
    wmctrl -lxG |
      awk -v desktop="$desktop" -v focus="$(normalize_id "$focus_id")" '
        function norm(id) {
          id = tolower(id)
          sub(/^0x0*/, "0x", id)
          return id
        }
        $2 == desktop && (!focus || norm($1) == focus) {print $3, $4, $5, $6; found=1}
        END {if (!found) exit 1}
      ' |
      tail -1 |
      while read -r x y w h; do
        printf '%s\n' "$(xrandr --query 2>/dev/null |
          awk -v wx="$x" -v wy="$y" -v ww="$w" -v wh="$h" '
            function max(a, b) { return a > b ? a : b }
            function min(a, b) { return a < b ? a : b }
            / connected/ && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
              geometry = substr($0, RSTART, RLENGTH)
              split(geometry, parts, /x|\+/)
              mx = parts[3]
              my = parts[4]
              mw = parts[1]
              mh = parts[2]

              ix = max(wx, mx)
              iy = max(wy, my)
              ir = min(wx + ww, mx + mw)
              ib = min(wy + wh, my + mh)
              overlap = 0
              if (ir > ix && ib > iy) overlap = (ir - ix) * (ib - iy)

              cx = wx + int(ww / 2)
              cy = wy + int(wh / 2)
              contains_center = (cx >= mx && cx < mx + mw && cy >= my && cy < my + mh)

              if (overlap > best_overlap || (overlap == best_overlap && contains_center && !best_contains_center)) {
                best_overlap = overlap
                best_contains_center = contains_center
                best = mx " " my " " mw " " mh
              }
            }
            END {
              if (best) print best
              else exit 1
            }
          ' || true)"
      done || true
  )"

  if [ -z "$monitor" ]; then
    monitor="$(xrandr --query 2>/dev/null |
      awk '
        / connected primary/ && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
          geometry = substr($0, RSTART, RLENGTH)
          split(geometry, parts, /x|\+/)
          print parts[3], parts[4], parts[1], parts[2]
          found = 1
          exit
        }
        / connected/ && !fallback && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
          geometry = substr($0, RSTART, RLENGTH)
          split(geometry, parts, /x|\+/)
          fallback = parts[3] " " parts[4] " " parts[1] " " parts[2]
        }
        END {
          if (!found && fallback) print fallback
        }
      ')"
  fi

  if [ -n "$monitor" ]; then
    read -r target_x target_y mw mh <<< "$monitor"
    local ax ay ar ab mx my mr mb

    ax="$wx"
    ay="$wy"
    ar=$((wx + ww))
    ab=$((wy + wh))
    mx="$target_x"
    my="$target_y"
    mr=$((target_x + mw))
    mb=$((target_y + mh))

    if [ "$mx" -lt "$ar" ] && [ "$mr" -gt "$ax" ] && [ "$my" -lt "$ab" ] && [ "$mb" -gt "$ay" ]; then
      [ "$mx" -lt "$ax" ] && mx="$ax"
      [ "$my" -lt "$ay" ] && my="$ay"
      [ "$mr" -gt "$ar" ] && mr="$ar"
      [ "$mb" -gt "$ab" ] && mb="$ab"
    fi

    printf '%s %s %s %s\n' "$mx" "$my" "$((mr - mx))" "$((mb - my))"
    return 0
  fi

  printf '%s %s %s %s\n' "$wx" "$wy" "$ww" "$wh"
}

sidebar_safe_area() {
  local x="$1"
  local y="$2"
  local w="$3"
  local h="$4"
  local primary

  primary="$(xrandr --query 2>/dev/null |
    awk '
      / connected primary/ && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
        geometry = substr($0, RSTART, RLENGTH)
        split(geometry, parts, /x|\+/)
        print parts[3], parts[4], parts[1], parts[2]
        exit
      }
    ')"

  if [ -n "$primary" ]; then
    read -r px py pw ph <<< "$primary"
    if [ "$x" -eq "$px" ] && [ "$y" -eq "$py" ] && [ "$sidebar_width" -gt 0 ] && [ "$w" -gt "$sidebar_width" ]; then
      x=$((x + sidebar_width))
      w=$((w - sidebar_width))
    fi
  fi

  printf '%s %s %s %s\n' "$x" "$y" "$w" "$h"
}

monitor_areas() {
  local wx="$1"
  local wy="$2"
  local ww="$3"
  local wh="$4"

  xrandr --query 2>/dev/null |
    awk -v wx="$wx" -v wy="$wy" -v ww="$ww" -v wh="$wh" '
      function max(a, b) { return a > b ? a : b }
      function min(a, b) { return a < b ? a : b }
      / connected/ && match($0, /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
        geometry = substr($0, RSTART, RLENGTH)
        split(geometry, parts, /x|\+/)
        mx = parts[3]
        my = parts[4]
        mw = parts[1]
        mh = parts[2]

        ix = max(wx, mx)
        iy = max(wy, my)
        ir = min(wx + ww, mx + mw)
        ib = min(wy + wh, my + mh)

        if (ir > ix && ib > iy) {
          print ix, iy, ir - ix, ib - iy
        }
      }
    ' |
    while read -r mx my mw mh; do
      sidebar_safe_area "$mx" "$my" "$mw" "$mh"
    done
}

is_normal_window() {
  local id="$1"
  local class="$2"
  local type state

  case "$class" in
    *.[Ee]ww|*[Ee]ww|*.[Rr]ofi|*[Rr]ofi|*.[Dd]unst|*[Dd]unst|*.[Nn]m-applet|*[Nn]m-applet) return 1 ;;
  esac

  type="$(xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null || true)"
  state="$(xprop -id "$id" _NET_WM_STATE 2>/dev/null || true)"

  grep -q '_NET_WM_WINDOW_TYPE_NORMAL' <<< "$type" || return 1
  grep -q '_NET_WM_STATE_FULLSCREEN' <<< "$state" && return 1

  return 0
}

window_ids() {
  local desktop="$1"

  wmctrl -lxG |
    awk -v desktop="$desktop" '$2 == desktop {print $1, $7}' |
    while read -r id class; do
      if is_normal_window "$id" "$class"; then
        printf '%s\n' "$id"
      fi
    done
}

window_ids_in_area() {
  local desktop="$1"
  local area_x="$2"
  local area_y="$3"
  local area_w="$4"
  local area_h="$5"
  local area_r area_b

  area_r=$((area_x + area_w))
  area_b=$((area_y + area_h))

  wmctrl -lxG |
    awk -v desktop="$desktop" '$2 == desktop {print $1, $3, $4, $5, $6, $7}' |
    while read -r id win_x win_y win_w win_h class; do
      local win_r win_b overlap_x overlap_y overlap_r overlap_b

      if ! is_normal_window "$id" "$class"; then
        continue
      fi

      win_r=$((win_x + win_w))
      win_b=$((win_y + win_h))
      overlap_x="$win_x"
      overlap_y="$win_y"
      overlap_r="$win_r"
      overlap_b="$win_b"

      [ "$overlap_x" -lt "$area_x" ] && overlap_x="$area_x"
      [ "$overlap_y" -lt "$area_y" ] && overlap_y="$area_y"
      [ "$overlap_r" -gt "$area_r" ] && overlap_r="$area_r"
      [ "$overlap_b" -gt "$area_b" ] && overlap_b="$area_b"

      if [ "$overlap_r" -gt "$overlap_x" ] && [ "$overlap_b" -gt "$overlap_y" ]; then
        printf '%s\n' "$id"
      fi
    done
}

current_geometry() {
  local id="$1"

  wmctrl -lxG |
    awk -v target="$(normalize_id "$id")" '
      function norm(id) {
        id = tolower(id)
        sub(/^0x0*/, "0x", id)
        return id
      }
      norm($1) == target {
        print $3, $4, $5, $6
        exit
      }
    '
}

abs() {
  local n="$1"
  if [ "$n" -lt 0 ]; then
    printf '%s\n' "$((-n))"
  else
    printf '%s\n' "$n"
  fi
}

move_window() {
  local id="$1"
  local x="$2"
  local y="$3"
  local w="$4"
  local h="$5"
  local req_x req_y req_w req_h actual ax ay aw ah dx dy dw dh pass

  [ "$w" -gt 80 ] || return 0
  [ "$h" -gt 80 ] || return 0

  wmctrl -ir "$id" -b remove,maximized_vert,maximized_horz,fullscreen >/dev/null 2>&1 || true

  req_x="$x"
  req_y="$y"
  req_w="$w"
  req_h="$h"

  for pass in 1 2 3 4; do
    [ "$req_w" -gt 80 ] || req_w=80
    [ "$req_h" -gt 80 ] || req_h=80

    wmctrl -ir "$id" -e "0,$req_x,$req_y,$req_w,$req_h" >/dev/null 2>&1 || true
    sleep 0.05

    actual="$(current_geometry "$id")"
    [ -n "$actual" ] || return 0
    read -r ax ay aw ah <<< "$actual"

    dx=$((x - ax))
    dy=$((y - ay))
    dw=$((w - aw))
    dh=$((h - ah))

    if [ "$(abs "$dx")" -le 1 ] &&
       [ "$(abs "$dy")" -le 1 ] &&
       [ "$(abs "$dw")" -le 1 ] &&
       [ "$(abs "$dh")" -le 1 ]; then
      return 0
    fi

    req_x=$((req_x + dx))
    req_y=$((req_y + dy))
    req_w=$((req_w + dw))
    req_h=$((req_h + dh))
  done
}

active_window() {
  xprop -root _NET_ACTIVE_WINDOW 2>/dev/null |
    awk -F'window id # ' 'NF > 1 && $2 != "0x0" {print tolower($2); exit}'
}

focus_window() {
  local id="$1"

  wmctrl -ir "$id" -b remove,below >/dev/null 2>&1 || true
  wmctrl -ia "$id" >/dev/null 2>&1 || true
}

is_active_fullscreen() {
  local id state type

  id="$(active_window)"
  [ -n "$id" ] || return 1

  type="$(xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null || true)"
  state="$(xprop -id "$id" _NET_WM_STATE 2>/dev/null || true)"

  grep -q '_NET_WM_WINDOW_TYPE_NORMAL' <<< "$type" || return 1
  grep -q '_NET_WM_STATE_FULLSCREEN' <<< "$state"
}

sidebar_is_open() {
  eww active-windows 2>/dev/null | grep -q '^sidebar:'
}

settings_are_open() {
  eww active-windows 2>/dev/null | grep -q '^systemsettings:'
}

close_settings_windows() {
  eww close settingsborder logoalignmentguide systemsettings bluetoothsettings displaysettings networksettings audiosettings \
    powersettings appearancesettings panelcustomization glowcolorpicker keybindsettings systeminfopanel \
    controlcenter >/dev/null 2>&1 || true
}

sync_sidebar_for_fullscreen() {
  if is_active_fullscreen; then
    if [ -f "$fullscreen_override" ] && settings_are_open; then
      return 0
    fi

    rm -f "$fullscreen_override"
    close_settings_windows
    eww close sidebar >/dev/null 2>&1 || true
    return 0
  fi

  rm -f "$fullscreen_override"
  if ! sidebar_is_open; then
    eww open sidebar >/dev/null 2>&1 || true
  fi
}

tile_remaining_area() {
  local skip_id="$1"
  local monitor_x="$2"
  local monitor_y="$3"
  local monitor_w="$4"
  local monitor_h="$5"
  local x="$6"
  local y="$7"
  local w="$8"
  local h="$9"
  local desktop n index id rows cols row col cell_w cell_h
  local -a ids ordered

  desktop="$(current_desktop)"
  mapfile -t ids < <(window_ids_in_area "$desktop" "$monitor_x" "$monitor_y" "$monitor_w" "$monitor_h" |
    awk -v skip="$skip_id" '
      function norm(id) {
        id = tolower(id)
        sub(/^0x0*/, "0x", id)
        return id
      }
      norm($1) != norm(skip)
    ')
  n="${#ids[@]}"
  [ "$n" -gt 0 ] || return 0

  for ((index = n - 1; index >= 0; index--)); do
    ordered+=("${ids[index]}")
  done

  if [ "$n" -eq 1 ]; then
    move_window "${ordered[0]}" "$x" "$y" "$w" "$h"
    return 0
  fi

  if [ "$n" -eq 2 ]; then
    cell_h=$(((h - gap) / 2))
    move_window "${ordered[0]}" "$x" "$y" "$w" "$cell_h"
    move_window "${ordered[1]}" "$x" "$((y + cell_h + gap))" "$w" "$((h - cell_h - gap))"
    return 0
  fi

  cols=2
  rows=$(((n + cols - 1) / cols))
  cell_w=$(((w - ((cols - 1) * gap)) / cols))
  cell_h=$(((h - ((rows - 1) * gap)) / rows))

  for ((index = 0; index < n; index++)); do
    id="${ordered[index]}"
    row=$((index / cols))
    col=$((index % cols))
    move_window "$id" \
      "$((x + col * (cell_w + gap)))" \
      "$((y + row * (cell_h + gap)))" \
      "$cell_w" \
      "$cell_h"
  done
}

tile_area() {
  local desktop="$1"
  local wx="$2"
  local wy="$3"
  local ww="$4"
  local wh="$5"
  local x y w h n id rows cols index row col cell_w cell_h
  local -a ids ordered

  mapfile -t ids < <(window_ids_in_area "$desktop" "$wx" "$wy" "$ww" "$wh")
  n="${#ids[@]}"
  [ "$n" -gt 0 ] || return 0

  x=$((wx + gap + placement_inset))
  y=$((wy + gap + placement_inset))
  w=$((ww - (gap * 2) + right_edge_bleed - (placement_inset * 2)))
  h=$((wh - (gap * 2) - (placement_inset * 2)))

  if [ "$n" -eq 1 ]; then
    move_window "${ids[0]}" "$x" "$y" "$w" "$h"
    return 0
  fi

  # Newest window becomes the left/master window for the Hyprland-like feel.
  for ((index = n - 1; index >= 0; index--)); do
    ordered+=("${ids[index]}")
  done

  if [ "$n" -eq 2 ]; then
    cell_w=$(((w - gap) / 2))
    move_window "${ordered[0]}" "$x" "$y" "$cell_w" "$h"
    move_window "${ordered[1]}" "$((x + cell_w + gap))" "$y" "$((w - cell_w - gap))" "$h"
    return 0
  fi

  if [ "$n" -eq 3 ]; then
    cell_w=$(((w - gap) / 2))
    cell_h=$(((h - gap) / 2))
    move_window "${ordered[0]}" "$x" "$y" "$cell_w" "$h"
    move_window "${ordered[1]}" "$((x + cell_w + gap))" "$y" "$((w - cell_w - gap))" "$cell_h"
    move_window "${ordered[2]}" "$((x + cell_w + gap))" "$((y + cell_h + gap))" "$((w - cell_w - gap))" "$((h - cell_h - gap))"
    return 0
  fi

  cols=2
  rows=$(((n + cols - 1) / cols))
  cell_w=$(((w - ((cols - 1) * gap)) / cols))
  cell_h=$(((h - ((rows - 1) * gap)) / rows))

  for ((index = 0; index < n; index++)); do
    id="${ordered[index]}"
    row=$((index / cols))
    col=$((index % cols))
    move_window "$id" \
      "$((x + col * (cell_w + gap)))" \
      "$((y + row * (cell_h + gap)))" \
      "$cell_w" \
      "$cell_h"
  done
}

place_focused() {
  local mode="$1"
  local desktop wx wy ww wh x y w h id half_w half_h

  update_runtime_settings
  id="$(active_window)"
  [ -n "$id" ] || return 0

  desktop="$(current_desktop)"
  read -r wx wy ww wh < <(workarea)
  [ -n "${wx:-}" ] || return 0
  read -r wx wy ww wh < <(active_monitor_area "$wx" "$wy" "$ww" "$wh" "$desktop" "$id")
  read -r wx wy ww wh < <(sidebar_safe_area "$wx" "$wy" "$ww" "$wh")

  x=$((wx + gap + placement_inset))
  y=$((wy + gap + placement_inset))
  w=$((ww - (gap * 2) + right_edge_bleed - (placement_inset * 2)))
  h=$((wh - (gap * 2) - (placement_inset * 2)))
  half_w=$(((w - gap) / 2))
  half_h=$(((h - gap) / 2))

  case "$mode" in
    left)
      move_window "$id" "$x" "$y" "$half_w" "$h"
      tile_remaining_area "$id" "$wx" "$wy" "$ww" "$wh" "$((x + half_w + gap))" "$y" "$((w - half_w - gap))" "$h"
      focus_window "$id"
      ;;
    right)
      move_window "$id" "$((x + half_w + gap))" "$y" "$((w - half_w - gap))" "$h"
      tile_remaining_area "$id" "$wx" "$wy" "$ww" "$wh" "$x" "$y" "$half_w" "$h"
      focus_window "$id"
      ;;
    up)
      move_window "$id" "$x" "$y" "$w" "$h"
      focus_window "$id"
      ;;
    down)
      tile_windows
      focus_window "$id"
      ;;
    upper-left)
      move_window "$id" "$x" "$y" "$half_w" "$half_h"
      focus_window "$id"
      ;;
    upper-right)
      move_window "$id" "$((x + half_w + gap))" "$y" "$((w - half_w - gap))" "$half_h"
      focus_window "$id"
      ;;
    lower-left)
      move_window "$id" "$x" "$((y + half_h + gap))" "$half_w" "$((h - half_h - gap))"
      focus_window "$id"
      ;;
    lower-right)
      move_window "$id" "$((x + half_w + gap))" "$((y + half_h + gap))" "$((w - half_w - gap))" "$((h - half_h - gap))"
      focus_window "$id"
      ;;
  esac
}

tile_windows() {
  local desktop wx wy ww wh mx my mw mh

  update_runtime_settings
  smart_tiling_enabled || return 0

  desktop="$(current_desktop)"
  read -r wx wy ww wh < <(workarea)

  [ -n "${wx:-}" ] || return 0
  while read -r mx my mw mh; do
    tile_area "$desktop" "$mx" "$my" "$mw" "$mh"
  done < <(monitor_areas "$wx" "$wy" "$ww" "$wh")
}

signature() {
  local desktop
  desktop="$(current_desktop)"
  printf '%s:' "$desktop"
  wmctrl -lxG |
    awk -v desktop="$desktop" '$2 == desktop {print $1, $3, $4, $5, $6, $7}' |
    while read -r id x y w h class; do
      if is_normal_window "$id" "$class"; then
        state="$(xprop -id "$id" _NET_WM_STATE 2>/dev/null || true)"
        flags=""
        grep -q '_NET_WM_STATE_MAXIMIZED_HORZ' <<< "$state" && flags="${flags}H"
        grep -q '_NET_WM_STATE_MAXIMIZED_VERT' <<< "$state" && flags="${flags}V"
        printf '%s:%s,%s,%s,%s:%s\n' "$id" "$x" "$y" "$w" "$h" "$flags"
      fi
    done |
    paste -sd ';' -
}

if [ "${1:-}" = "--once" ]; then
  update_runtime_settings
  tile_windows
  exit 0
fi

case "${1:-}" in
  --left)
    place_focused left
    exit 0
    ;;
  --right)
    place_focused right
    exit 0
    ;;
  --up)
    place_focused up
    exit 0
    ;;
  --down)
    place_focused down
    exit 0
    ;;
  --upper-left)
    place_focused upper-left
    exit 0
    ;;
  --upper-right)
    place_focused upper-right
    exit 0
    ;;
  --lower-left)
    place_focused lower-left
    exit 0
    ;;
  --lower-right)
    place_focused lower-right
    exit 0
    ;;
esac

last_signature=""

while true; do
  update_runtime_settings
  sync_sidebar_for_fullscreen
  current_signature="$(signature)"
  if smart_tiling_enabled && [ "$current_signature" != "$last_signature" ]; then
    tile_windows
    last_signature="$(signature)"
  elif ! smart_tiling_enabled; then
    last_signature="$current_signature"
  fi
  sleep "$poll_interval"
done

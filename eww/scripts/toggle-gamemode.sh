#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.cache/eww-gamemode"
PICOM_STATE="$HOME/.cache/eww-gamemode-picom-was-running"
PICOM_CONFIG="$HOME/.config/picom/picom.conf"
SMART_STATE="$HOME/.cache/eww-gamemode-smart-place-was-running"
POWER_STATE="$HOME/.cache/eww-gamemode-power-profile"
DUNST_STATE="$HOME/.cache/eww-gamemode-dunst-was-unpaused"
EWW_STATE="$HOME/.cache/eww-gamemode-eww-was-running"
BORDER_OFF_STATE="$HOME/.cache/eww-gamemode-window-border-was-off"
BORDER_ON_STATE="$HOME/.cache/eww-gamemode-window-border-was-on"
STEAM_STATE="$HOME/.cache/eww-gamemode-steam-started"

sync_openbox_theme() {
  "$HOME/.config/eww/scripts/sync-openbox-theme.sh" >/dev/null 2>&1 || true
}

close_eww_windows() {
  eww close \
    sidebar \
    settingsborder \
    logoalignmentguide \
    systemsettings \
    bluetoothsettings \
    displaysettings \
    networksettings \
    audiosettings \
    powersettings \
    appearancesettings \
    panelcustomization \
    glowcolorpicker \
    sidebarlogopicker \
    keybindsettings \
    systeminfopanel \
    supermachinewelcome \
    controlcenter >/dev/null 2>&1 || true
}

stop_smart_place() {
  local pids
  pids="$(pgrep -f "^bash $HOME/.config/openbox/smart-place.sh$" || true)"
  if [ -n "$pids" ]; then
    touch "$SMART_STATE"
    kill $pids >/dev/null 2>&1 || true
  fi
}

start_smart_place() {
  rm -f "$SMART_STATE"
  [ -f "$HOME/.config/eww/state/smart-tiling-off" ] && return 0
  if ! pgrep -f "^bash $HOME/.config/openbox/smart-place.sh$" >/dev/null 2>&1; then
    nohup "$HOME/.config/openbox/smart-place.sh" >/tmp/supermachine-smart-place.log 2>&1 &
  fi
}

start_steam_bigpicture() {
  command -v steam >/dev/null 2>&1 || return 0
  if ! pgrep -x steam >/dev/null 2>&1; then
    touch "$STEAM_STATE"
  fi
  setsid -f steam steam://open/bigpicture >/tmp/supermachine-steam-bigpicture.log 2>&1 || true
}

stop_steam() {
  command -v steam >/dev/null 2>&1 || return 0
  steam -shutdown >/tmp/supermachine-steam-shutdown.log 2>&1 || true
  sleep 1
  pkill -x steamwebhelper >/dev/null 2>&1 || true
  pkill -x steam >/dev/null 2>&1 || true
  rm -f "$STEAM_STATE"
}

enable_gamemode() {
  local mode="${1:-}"

  touch "$STATE"

  rm -f "$BORDER_OFF_STATE" "$BORDER_ON_STATE"
  if [ -f "$HOME/.config/eww/state/window-border-off" ]; then
    touch "$BORDER_OFF_STATE"
  else
    touch "$BORDER_ON_STATE"
  fi
  sync_openbox_theme

  if command -v powerprofilesctl >/dev/null 2>&1; then
    if [ "$mode" != "resume" ]; then
      powerprofilesctl get > "$POWER_STATE" 2>/dev/null || printf '%s\n' balanced > "$POWER_STATE"
    fi
    powerprofilesctl set performance >/dev/null 2>&1 || true
  fi

  if pgrep -x picom >/dev/null 2>&1; then
    touch "$PICOM_STATE"
    pkill -x picom >/dev/null 2>&1 || true
  fi

  stop_smart_place

  if command -v dunstctl >/dev/null 2>&1; then
    if dunstctl is-paused 2>/dev/null | grep -q false; then
      touch "$DUNST_STATE"
      dunstctl set-paused true >/dev/null 2>&1 || true
    fi
  fi

  eww update GAME_STATE=on >/dev/null 2>&1 || true
  eww update PERF_STATE=on >/dev/null 2>&1 || true
  if pgrep -x eww >/dev/null 2>&1; then
    touch "$EWW_STATE"
    close_eww_windows
    sleep 0.1
    eww kill >/dev/null 2>&1 || true
  fi

  start_steam_bigpicture
}

disable_gamemode() {
  rm "$STATE"

  if [ -s "$POWER_STATE" ] && command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl set "$(cat "$POWER_STATE")" >/dev/null 2>&1 || powerprofilesctl set balanced >/dev/null 2>&1 || true
  elif command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl set balanced >/dev/null 2>&1 || true
  fi
  rm -f "$POWER_STATE"

  if [ -f "$BORDER_ON_STATE" ]; then
    rm -f "$HOME/.config/eww/state/window-border-off"
  elif [ -f "$BORDER_OFF_STATE" ]; then
    touch "$HOME/.config/eww/state/window-border-off"
  fi
  rm -f "$BORDER_ON_STATE" "$BORDER_OFF_STATE"
  sync_openbox_theme

  if [ -f "$PICOM_STATE" ]; then
    rm -f "$PICOM_STATE"
    if ! pgrep -x picom >/dev/null 2>&1; then
      setsid -f picom --config "$PICOM_CONFIG" >/tmp/supermachine-picom.log 2>&1
    fi
  fi

  start_smart_place

  if [ -f "$DUNST_STATE" ] && command -v dunstctl >/dev/null 2>&1; then
    dunstctl set-paused false >/dev/null 2>&1 || true
  fi
  rm -f "$DUNST_STATE"

  if [ -f "$EWW_STATE" ]; then
    rm -f "$EWW_STATE"
    eww daemon >/dev/null 2>&1 || true
    sleep 0.2
    eww open sidebar >/dev/null 2>&1 || true
  fi

  eww update GAME_STATE=off >/dev/null 2>&1 || true
  eww update PERF_STATE=off >/dev/null 2>&1 || true
  stop_steam
}

case "${1:-toggle}" in
  on)
    enable_gamemode
    ;;
  off)
    [ -f "$STATE" ] && disable_gamemode
    ;;
  resume)
    [ -f "$STATE" ] && enable_gamemode resume
    ;;
  toggle|*)
    if [ -f "$STATE" ]; then
      disable_gamemode
    else
      enable_gamemode
    fi
    ;;
esac

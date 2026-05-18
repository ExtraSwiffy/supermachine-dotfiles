#!/bin/bash
set -euo pipefail

rofi_cmd=(rofi -dmenu -i -p "Bluetooth")

choose_device() {
  bluetoothctl devices | sed 's/^Device //'
}

case "$(printf "Scan and connect\nConnect paired\nDisconnect device\nPower on\nPower off\nOpen bluetoothctl" | "${rofi_cmd[@]}")" in
  "Scan and connect")
    bluetoothctl power on >/dev/null
    bluetoothctl agent on >/dev/null || true
    bluetoothctl default-agent >/dev/null || true
    timeout 8 bluetoothctl scan on >/dev/null 2>&1 || true
    device="$(choose_device | rofi -dmenu -i -p "Connect")"
    [ -n "${device:-}" ] || exit 0
    mac="${device%% *}"
    bluetoothctl pair "$mac" || true
    bluetoothctl trust "$mac" || true
    bluetoothctl connect "$mac"
    ;;
  "Connect paired")
    device="$(bluetoothctl devices Paired | sed 's/^Device //' | rofi -dmenu -i -p "Connect")"
    [ -n "${device:-}" ] || exit 0
    bluetoothctl connect "${device%% *}"
    ;;
  "Disconnect device")
    device="$(bluetoothctl devices Connected | sed 's/^Device //' | rofi -dmenu -i -p "Disconnect")"
    [ -n "${device:-}" ] || exit 0
    bluetoothctl disconnect "${device%% *}"
    ;;
  "Power on")
    bluetoothctl power on
    ;;
  "Power off")
    bluetoothctl power off
    ;;
  "Open bluetoothctl")
    alacritty -e bluetoothctl
    ;;
esac

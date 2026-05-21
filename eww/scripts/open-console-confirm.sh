#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/.config/eww"

if ! eww -c "$cfg" active-windows >/dev/null 2>&1; then
  eww -c "$cfg" daemon >/dev/null 2>&1 || true
  sleep 0.2
fi

eww -c "$cfg" open consoleconfirm >/dev/null 2>&1 || true

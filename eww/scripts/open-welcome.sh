#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/.config/eww"

"$cfg/scripts/close-welcome.sh"
eww -c "$cfg" open supermachinewelcome >/dev/null 2>&1 || true

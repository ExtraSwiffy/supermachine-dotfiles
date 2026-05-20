#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/.config/eww"

eww -c "$cfg" close supermachinewelcome >/dev/null 2>&1 || true
pgrep -f '^eww open supermachinewelcome$' | xargs -r kill >/dev/null 2>&1 || true


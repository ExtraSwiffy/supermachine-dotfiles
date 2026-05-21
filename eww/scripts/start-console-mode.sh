#!/usr/bin/env bash
set -euo pipefail

cfg="$HOME/.config/eww"

eww -c "$cfg" close consoleconfirm >/dev/null 2>&1 || true
"$HOME/.config/openbox/console-mode.sh" enter

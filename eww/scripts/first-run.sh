#!/usr/bin/env bash
set -euo pipefail

done_file="$HOME/.config/supermachine/first-run-done"

[ -f "$done_file" ] && exit 0

sleep 2
"$HOME/.config/eww/scripts/open-welcome.sh"

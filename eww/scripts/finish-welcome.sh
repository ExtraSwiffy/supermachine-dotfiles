#!/usr/bin/env bash
set -euo pipefail

done_file="$HOME/.config/supermachine/first-run-done"

mkdir -p "$(dirname "$done_file")"
touch "$done_file"
"$HOME/.config/eww/scripts/close-welcome.sh"

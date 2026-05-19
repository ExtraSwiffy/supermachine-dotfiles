#!/usr/bin/env bash
set -euo pipefail

done_file="$HOME/.config/supermachine/first-run-done"

mkdir -p "$(dirname "$done_file")"
touch "$done_file"
eww close supermachinewelcome >/dev/null 2>&1 || true


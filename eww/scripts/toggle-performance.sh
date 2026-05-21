#!/usr/bin/env bash
set -euo pipefail

if [ "$(powerprofilesctl get)" = "performance" ]; then
  powerprofilesctl set balanced
  eww update PERF_STATE=off >/dev/null 2>&1 || true
else
  powerprofilesctl set performance
  eww update PERF_STATE=on >/dev/null 2>&1 || true
fi

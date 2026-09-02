#!/bin/sh

polybar-msg cmd quit >/dev/null 2>&1 || true
pkill -x polybar >/dev/null 2>&1 || true

while pgrep -x polybar >/dev/null 2>&1; do
  sleep 0.2
done

# Detach from the caller so a manual launch survives after its shell exits.
setsid -f polybar --reload home >>"$HOME/.cache/polybar.log" 2>&1

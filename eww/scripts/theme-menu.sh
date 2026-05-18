#!/bin/bash
set -euo pipefail

theme="$(
  find "$HOME/.themes" -mindepth 2 -maxdepth 2 -type d -name openbox-3 2>/dev/null |
    sed "s#^$HOME/.themes/##; s#/openbox-3\$##" |
    sort |
    rofi -dmenu -i -p "Openbox Theme"
)"

[ -n "${theme:-}" ] || exit 0

rc="$HOME/.config/openbox/rc.xml"

if [ ! -f "$rc" ]; then
  notify-send "Theme switcher" "Missing $rc"
  exit 1
fi

perl -0pi -e "s#<theme>\\s*<name>.*?</name>#<theme>\\n    <name>\\Q$theme\\E</name>#s" "$rc"
openbox --reconfigure
notify-send "Theme applied" "$theme"

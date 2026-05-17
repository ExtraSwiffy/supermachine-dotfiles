#!/bin/sh

[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

exec dbus-run-session openbox-session

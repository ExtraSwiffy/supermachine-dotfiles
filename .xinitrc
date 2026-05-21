if [ -x "$HOME/.config/openbox/console-mode.sh" ] && "$HOME/.config/openbox/console-mode.sh" should-start; then
  exec "$HOME/.config/openbox/console-mode.sh" session
fi

exec openbox-session

#!/usr/bin/env python3
import os
import pathlib
import subprocess

import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gio, GLib, Gtk

ROOT = pathlib.Path(__file__).resolve().parent
HOME = pathlib.Path.home()
EWW = HOME / ".config/eww/scripts"

class SettingsApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="dev.supermachine.Settings", flags=Gio.ApplicationFlags.DEFAULT_FLAGS)

    def do_activate(self):
        existing = self.get_active_window()
        if existing:
            existing.present()
            return
        builder = Gtk.Builder.new_from_file(str(ROOT / "app.ui"))
        self.builder = builder
        self.window = builder.get_object("main_window")
        self.window.set_application(self)
        self.css = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_display(self.window.get_display(), self.css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        self.active_theme = None
        self._load_theme_css()
        self._wire_navigation()
        self._wire_actions()
        self.obj("close_app").connect("clicked", lambda _button: self.window.close())
        self._refresh()
        GLib.timeout_add_seconds(1, self._watch_theme)
        self.window.present()

    def obj(self, name):
        return self.builder.get_object(name)

    def _wire_navigation(self):
        for page in ("appearance", "devices", "system", "about"):
            self.obj(f"nav_{page}").connect("clicked", self._show_page, page)

    def _show_page(self, _button, page):
        self.obj("page_stack").set_visible_child_name(page)
        for name in ("appearance", "devices", "system", "about"):
            button = self.obj(f"nav_{name}")
            (button.add_css_class if name == page else button.remove_css_class)("active")
        self._refresh()

    def _wire_actions(self):
        commands = {
            "theme_picker": [EWW / "theme-selector.sh", "theme", "open"],
            "wallpaper_picker": [EWW / "theme-selector.sh", "wallpaper", "open"],
            "gtk_appearance": ["lxappearance"], "openbox_settings": ["obconf-qt"],
            "smart_tiling": [EWW / "toggle-smart-tiling.sh"],
            "gap_down": [EWW / "set-window-gap.sh", "down"], "gap_up": [EWW / "set-window-gap.sh", "up"],
            "border_down": [EWW / "set-window-border.sh", "thinner"], "border_up": [EWW / "set-window-border.sh", "thicker"],
            "radius_down": [EWW / "set-window-radius.sh", "down"], "radius_up": [EWW / "set-window-radius.sh", "up"],
            "network": ["nm-connection-editor"], "bluetooth": [EWW / "bluetooth-menu.sh"], "audio": ["pavucontrol"], "displays": ["arandr"],
            "mute": ["pamixer", "-t"], "game_mode": [EWW / "toggle-gamemode.sh"], "night_mode": [EWW / "toggle-nightmode.sh"],
            "console_mode": [HOME / ".config/openbox/console-mode.sh", "enter"], "check_updates": [EWW / "update-supermachine.sh", "check"],
            "reload_openbox": ["openbox", "--reconfigure"], "edit_settings": ["code", ROOT],
        }
        for widget, command in commands.items():
            self.obj(widget).connect("clicked", self._run, [str(x) for x in command])
        self.obj("volume").connect("value-changed", self._set_volume)

    def _run(self, _widget, command):
        try:
            subprocess.Popen(command, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError as error:
            self._notice(str(error))
        self._refresh_later()

    def _set_volume(self, scale):
        if getattr(self, "loading_volume", False): return
        subprocess.Popen(["pamixer", "--set-volume", str(round(scale.get_value()))])

    def _read(self, path, fallback="0"):
        try: return pathlib.Path(path).read_text().strip()
        except OSError: return fallback

    def _theme_values(self, slug):
        values = {}
        theme_file = HOME / ".config/supermachine/themes" / slug / "theme.conf"
        try:
            for raw_line in theme_file.read_text().splitlines():
                line = raw_line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                value = value.strip()
                if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                values[key.strip()] = value
        except OSError:
            pass
        return values

    def _load_theme_css(self):
        slug = self._read(HOME / ".local/state/supermachine/active-theme", "default")
        values = self._theme_values(slug)
        defaults = {
            "__ACCENT__": "rgba(34, 139, 86, 0.84)",
            "__GOLD__": "rgba(34, 139, 86, 0.28)",
            "__HEADER__": "rgba(235, 255, 246, 1)",
            "__SUBTEXT__": "rgba(132, 178, 156, 1)",
            "__PANEL__": "rgba(12, 14, 16, 0.95)",
            "__DETAIL__": "rgba(12, 14, 16, 0.98)",
            "__SECTION__": "rgba(255, 255, 255, 0.0494)",
        }
        replacements = {
            "__ACCENT__": values.get("THEME_ACCENT_RGBA", defaults["__ACCENT__"]),
            "__GOLD__": values.get("THEME_ACCENT_DOT", defaults["__GOLD__"]),
            "__HEADER__": values.get("THEME_HEADER_RGBA", defaults["__HEADER__"]),
            "__SUBTEXT__": values.get("THEME_SUBTEXT_RGBA", defaults["__SUBTEXT__"]),
            "__PANEL__": values.get("THEME_PANEL_RGBA", defaults["__PANEL__"]),
            "__DETAIL__": values.get("THEME_DETAIL_RGBA", defaults["__DETAIL__"]),
            "__SECTION__": values.get("THEME_SECTION_RGBA", defaults["__SECTION__"]),
        }
        stylesheet = (ROOT / "style.css").read_text()
        for token, color in replacements.items():
            stylesheet = stylesheet.replace(token, color)
        self.css.load_from_data(stylesheet.encode())
        self.active_theme = slug

    def _watch_theme(self):
        slug = self._read(HOME / ".local/state/supermachine/active-theme", "default")
        if slug != self.active_theme:
            self._load_theme_css()
            self._refresh()
        return True

    def _output(self, command, fallback="unknown"):
        try: return subprocess.run(command, text=True, capture_output=True, timeout=2).stdout.strip() or fallback
        except (OSError, subprocess.TimeoutExpired): return fallback

    def _refresh(self):
        gap = self._read(HOME / ".config/eww/state/window-gap", "5")
        border = self._read(HOME / ".config/eww/state/window-border-width", "2")
        radius = self._output(["sh", "-c", "awk -F'= ' '/corner-radius/ {gsub(/;| /,\"\",$2); print $2; exit}' ~/.config/picom/picom.conf"], "0")
        theme = self._read(HOME / ".local/state/supermachine/active-theme", "default")
        self.obj("gap_value").set_text(f"{gap} px")
        self.obj("border_value").set_text(f"{border} px")
        self.obj("radius_value").set_text(f"{radius} r")
        self.obj("appearance_summary").set_text(f"Active atmosphere: {theme.replace('-', ' ').title()}")
        volume = self._output(["pamixer", "--get-volume"], "0")
        self.loading_volume = True
        self.obj("volume").set_value(float(volume) if volume.isdigit() else 0)
        self.loading_volume = False
        host = self._output(["hostname"], "SuperMachine")
        kernel = self._output(["uname", "-r"])
        uptime = self._output(["uptime", "-p"])
        memory = self._output(["sh", "-c", "free -h | awk '/Mem:/ {print $3 \" / \" $2}'"])
        root_use = self._output(["sh", "-c", "df -h / | awk 'NR==2 {print $3 \" / \" $2 \" (\" $5 \")\"}'"])
        packages = self._output(["sh", "-c", "pacman -Qq 2>/dev/null | wc -l"])
        self.obj("sidebar_status").set_text(f"{host}\n{theme.replace('-', ' ').title()} atmosphere")
        self.obj("system_info").set_text(f"Host       {host}\nKernel     {kernel}\nUptime     {uptime}\nMemory     {memory}\nRoot disk  {root_use}\nPackages   {packages}\nTheme      {theme}\nSession    Openbox / X11")

    def _refresh_later(self):
        GLib.timeout_add(500, lambda: (self._refresh(), False)[1])

    def _notice(self, text):
        self.obj("sidebar_status").set_text(text)

if __name__ == "__main__":
    raise SystemExit(SettingsApp().run())

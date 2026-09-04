# SuperMachine Dotfiles

A simple, minimal Openbox desktop for a fresh Arch Linux installation. It
combines keyboard-friendly semi-tiling with a normal floating desktop.

## Fresh Arch installation

Download only the installer, make it executable, and run it as your normal
user. It installs Git when needed, clones this repository, installs the
packages and deploys the desktop:

```bash
wget https://raw.githubusercontent.com/ExtraSwiffy/supermachine-dotfiles/main/install.sh
chmod +x install.sh
./install.sh
```

Do not run the installer itself with `sudo`; it asks for sudo only when a
system package or service requires it. Reboot when installation finishes.

## Everyday maintenance

Run these inside `~/supermachine-dotfiles`:

```bash
./setup check    # validate dependencies and config syntax
./setup deploy   # copy repository configs into the home directory
./setup restart  # restart Polybar and the tiler
./setup update   # pull, deploy, and restart
```

Machine-specific defaults live in
`~/.config/supermachine/settings.conf`. Tiling runtime state lives under
`~/.local/state/supermachine`. Existing Eww appearance choices are preserved
when configs are redeployed or updated.

## Features

- Openbox floating desktop with optional semi-tiling
- Polybar workspace and system status bar
- Rofi launcher
- Native, frameless GTK 4 settings and customization application
- Editable GtkBuilder `app.ui` layout with live theme-color synchronization
- Console/game mode helpers
- Multi-monitor wallpaper and placement support

## Visual themes

- Right-double-click an empty part of the desktop to open the theme carousel.
- Left-double-click the desktop to choose a wallpaper from the active theme.
- Use the side previews or arrow buttons to browse, then Apply to switch the
  wallpaper, Eww accents, Openbox borders, Polybar colors, and the open GTK
  settings application together.
- `Default` includes the original wallpaper and the graphite SuperMachine
  wordmark. `Snow Forest` includes two moonlit winter wallpapers.
- `Ember Dusk`, `Neon Rain`, and `Golden Canopy` add coordinated volcanic,
  cyber-city, and autumn-forest atmospheres.
- `Fable` combines three original fairy-tale landscapes with five clean,
  HUD-free promotional screenshots from the new game.

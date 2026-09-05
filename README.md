# SuperMachine Dotfiles

> SuperMachine 2.0 is being developed in [`hyprland-super`](hyprland-super/).
> The existing Openbox/Eww generation remains available on this branch while
> the new Hyprland and Quickshell desktop is developed and tested.

## Hyprland development generation

The new desktop currently includes only a portable Hyprland Lua configuration
and an original Quickshell shell skeleton with a screen frame, left rail, and
expanding top-edge menu. Application choices such as the terminal, launcher,
file manager, notifications, wallpaper, and lock screen are intentionally not
part of the core yet.

Its standalone two-stage installation guide is in
[`hyprland-super/README.md`](hyprland-super/README.md).

Install it from a local clone with:

```bash
cd hyprland-super
./superbase.sh
```

For development without installing packages or replacing the running shell:

```bash
cd hyprland-super
./check.sh
./deploy.sh
qs -p ./config/quickshell/supermachine
```

The deploy script preserves an existing `~/.config/hypr/monitors.lua`, keeping
machine-specific display geometry out of the portable dotfiles. During the
migration, it is safest to test the custom shell from a TTY or after stopping
Caelestia so the two shells do not overlap.

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

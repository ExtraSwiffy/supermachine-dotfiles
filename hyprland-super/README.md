# SuperMachine 2.0

A minimal, from-scratch Hyprland and Quickshell desktop. Hyprland owns the
session and window management; Quickshell provides the rounded screen frame,
left rail, launcher, wallpaper deck, badge deck, and control center.

## Shell shortcuts

- `Super+Space` — application launcher
- `Super+W` — wallpaper deck
- `Super+B` — badge deck
- `Super+Tab` — settings deck

The first-stage deployment adds a guarded TTY1 login hook that starts Hyprland
through `startx`. Creating `~/.config/supermachine/console-mode` skips graphical
startup; that flag is reserved for the future Console Mode switch.

## Stage one: fresh Arch TTY

Run this as your normal user, not with `sudo`:

```bash
wget https://raw.githubusercontent.com/ExtraSwiffy/supermachine-dotfiles/supermachine-2.0/hyprland-super/superbase.sh
chmod +x superbase.sh
./superbase.sh
```

The script downloads this branch into `~/supermachine-dotfiles`, installs every
official package in `pkg.list`, and deploys the initial Hyprland configuration.
Start Hyprland after it completes.

## Stage two: inside Hyprland

Open Foot with `Super+Return`, then run:

```bash
cd ~/supermachine-dotfiles/hyprland-super
./superbase-advance.sh
```

This installs `yay` when necessary, installs `yay.list`, deploys Quickshell,
and starts the SuperMachine shell. Display-specific rules belong in
`~/.config/hypr/monitors.lua`; deployment preserves that file.

## Development

```bash
./check.sh
./deploy.sh
qs -p ./config/quickshell/supermachine
```

Use `./deploy.sh --shell-only` when previewing Quickshell without replacing the
active Hyprland configuration.

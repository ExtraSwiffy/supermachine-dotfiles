# SuperMachine 2.0

A minimal, from-scratch Hyprland and Quickshell desktop. Hyprland owns the
session and window management; Quickshell provides the rounded screen frame,
left rail, launcher, wallpaper deck, badge deck, and control center.
Foot uses the included SuperOS terminal profile and prompt rather than any
shell branding inherited from an older desktop configuration.

## Shell shortcuts

- `Super+Space` — application launcher
- `Super+W` — wallpaper deck
- `Super+B` — badge deck
- `Super+G` — SuperOS Arcade
- `Super+Tab` — settings deck

The first-stage deployment adds a guarded TTY1 login hook that starts the
persistent session selected in the control center. Desktop Mode launches
Hyprland; Console Mode launches Steam's Gamepad UI through Gamescope. Steam's
Desktop Mode action clears the saved Console Mode flag and returns to Hyprland.

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

## Logs and diagnostics

Persistent, size-limited session logs are stored in
`~/.local/state/supermachine/logs/`. Quickshell runs as a user service and
automatically restarts after unexpected failures. In `Super+Tab` → System,
**View live shell log** follows the current shell log and **Build diagnostic
report** creates a timestamped report under
`~/.local/state/supermachine/reports/` with recent session, journal, graphics,
and crash information.

Console Mode writes its complete Gamescope and Steam launch output to
`~/.local/state/supermachine/logs/console-mode.log`; that log is also embedded
in every diagnostic report.

#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
profile_file="${HOME}/.bash_profile"

mkdir -p "${config_home}/quickshell/supermachine"
cp -a "${project_dir}/config/quickshell/supermachine/." "${config_home}/quickshell/supermachine/"

mkdir -p "${config_home}/supermachine"
mkdir -p "${HOME}/.local/bin"
if [[ ! -e "${HOME}/.local/bin/startx" ]]; then
    install -m 0755 "${project_dir}/bin/startx" "${HOME}/.local/bin/startx"
fi
touch "${profile_file}"
if ! grep -q 'SUPERMACHINE AUTO START' "${profile_file}"; then
    printf '%s\n' \
        '' \
        '# SUPERMACHINE AUTO START' \
        '# A future Console Mode toggle can create this flag to stay in the TTY.' \
        'if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "$(tty)" == "/dev/tty1" && ! -e "$HOME/.config/supermachine/console-mode" ]]; then' \
        '    exec "$HOME/.local/bin/startx"' \
        'fi' >> "${profile_file}"
fi

if [[ "${1:-}" != "--shell-only" ]]; then
    mkdir -p "${config_home}/hypr"
    cp "${project_dir}/config/hypr/hyprland.lua" "${config_home}/hypr/hyprland.lua"
    if [[ ! -f "${config_home}/hypr/monitors.lua" ]]; then
        cp "${project_dir}/config/hypr/monitors.lua.example" "${config_home}/hypr/monitors.lua"
    fi
fi

echo "SuperMachine 2.0 configuration deployed."

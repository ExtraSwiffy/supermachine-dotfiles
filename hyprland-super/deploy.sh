#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

mkdir -p "${config_home}/quickshell/supermachine"
cp -a "${project_dir}/config/quickshell/supermachine/." "${config_home}/quickshell/supermachine/"

if [[ "${1:-}" != "--shell-only" ]]; then
    mkdir -p "${config_home}/hypr"
    cp "${project_dir}/config/hypr/hyprland.lua" "${config_home}/hypr/hyprland.lua"
    if [[ ! -f "${config_home}/hypr/monitors.lua" ]]; then
        cp "${project_dir}/config/hypr/monitors.lua.example" "${config_home}/hypr/monitors.lua"
    fi
fi

echo "SuperMachine 2.0 configuration deployed."

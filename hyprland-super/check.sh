#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -n "${project_dir}/superbase.sh" \
    "${project_dir}/superbase-advance.sh" \
    "${project_dir}/deploy.sh" \
    "${project_dir}/check.sh"

if command -v Hyprland >/dev/null 2>&1; then
    Hyprland --verify-config -c "${project_dir}/config/hypr/hyprland.lua"
else
    echo "warning: Hyprland is not installed; skipped its parser check"
fi

if command -v qmllint >/dev/null 2>&1; then
    qmllint "${project_dir}/config/quickshell/supermachine/"*.qml
else
    echo "warning: qmllint is not installed; skipped QML linting"
fi

echo "SuperMachine 2.0 checks passed."

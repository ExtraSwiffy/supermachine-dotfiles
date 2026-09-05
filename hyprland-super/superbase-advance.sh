#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -eq 0 ]]; then
    echo "Run this as your normal user, not as root or through sudo."
    exit 1
fi

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    echo "Stage two must be run from a terminal inside Hyprland."
    exit 1
fi

if ! command -v yay >/dev/null 2>&1; then
    echo "Installing the yay AUR helper..."
    sudo pacman -S --needed base-devel git
    yay_build_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "${yay_build_dir}/yay"
    (cd "${yay_build_dir}/yay" && makepkg -si --needed)
fi

mapfile -t yay_packages < <(sed '/^[[:space:]]*\(#\|$\)/d' "${project_dir}/yay.list")
if ((${#yay_packages[@]})); then
    echo "Installing AUR packages from yay.list..."
    yay -S --needed --answerclean None --answerdiff None "${yay_packages[@]}"
fi

"${project_dir}/deploy.sh"
qs -c supermachine kill >/dev/null 2>&1 || true
qs -c supermachine -d

echo "SuperMachine 2.0 is installed and running."

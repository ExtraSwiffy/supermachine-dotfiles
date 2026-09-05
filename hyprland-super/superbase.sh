#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/ExtraSwiffy/supermachine-dotfiles.git"
branch="supermachine-2.0"
repo_dir="${HOME}/supermachine-dotfiles"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -eq 0 ]]; then
    echo "Run this as your normal user, not as root or through sudo."
    exit 1
fi

# A lone copy downloaded with wget bootstraps the branch, then hands off to it.
if [[ ! -f "${script_dir}/pkg.list" || ! -f "${script_dir}/deploy.sh" ]]; then
    echo "Downloading the SuperMachine 2.0 branch..."
    sudo pacman -Sy --needed git
    if [[ -d "${repo_dir}/.git" ]]; then
        git -C "${repo_dir}" fetch origin "${branch}"
        git -C "${repo_dir}" switch "${branch}"
        git -C "${repo_dir}" pull --ff-only
    elif [[ -e "${repo_dir}" ]]; then
        echo "${repo_dir} exists but is not a Git repository. Move it and retry."
        exit 1
    else
        git clone --branch "${branch}" --single-branch "${repo_url}" "${repo_dir}"
    fi
    exec "${repo_dir}/hyprland-super/superbase.sh"
fi

echo "Installing the minimal Hyprland base from pkg.list..."
if ! grep -Eq '^\[multilib\]' /etc/pacman.conf; then
    echo "Enabling Arch multilib for Steam..."
    sudo sed -i '/^#\[multilib\]/{s/^#//; n; s/^#//;}' /etc/pacman.conf
    sudo pacman -Sy
fi
sudo pacman -Syu --needed - < "${script_dir}/pkg.list"
sudo systemctl enable --now power-profiles-daemon.service
"${script_dir}/deploy.sh"

echo
echo "Stage one is complete. Start Hyprland, open Foot with Super+Return, then run:"
echo "  cd ${repo_dir}/hyprland-super"
echo "  ./superbase-advance.sh"

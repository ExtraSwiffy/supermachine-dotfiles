#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script with sudo or as root."
    echo "Run it as your normal user: ./install.sh"
    exit 1
fi

aur_packages=()
while IFS= read -r package; do
    [[ -z "$package" || "$package" == \#* ]] && continue
    aur_packages+=("$package")
done < aurlist.txt

echo "Installing SuperMachine packages..."

if ! grep -Eq '^\[multilib\]' /etc/pacman.conf; then
    echo "Enabling pacman multilib repo for Steam/Wine 32-bit gaming packages..."
    sudo sed -i '/^#\[multilib\]/{s/^#//; n; s/^#//;}' /etc/pacman.conf
    sudo pacman -Sy
fi

sudo pacman -S --needed - < pkglist.txt

echo "Enabling desktop services..."

sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now power-profiles-daemon.service

echo "Creating config folders..."

mkdir -p ~/.config
mkdir -p ~/Pictures/wallpapers
mkdir -p ~/.icons
mkdir -p ~/.themes
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0
mkdir -p ~/.local/bin

echo "Copying wallpaper..."

cp -r wallpapers/* ~/Pictures/wallpapers/

echo "Copying configs..."

cp -r eww ~/.config/
cp -r openbox ~/.config/
cp -r rofi ~/.config/
cp -r picom ~/.config/
cp -r alacritty ~/.config/
cp -r themes/* ~/.themes/
if [ -d local/bin ]; then
    cp -r local/bin/* ~/.local/bin/
fi

cp .fehbg ~/
cp .xinitrc ~/
cp -r .screenlayout ~/

echo "Copying cursor theme..."

cp -r icons/ArchCursor ~/.icons/

cp .Xresources ~/
xrdb ~/.Xresources

cp gtk-3.0/settings.ini ~/.config/gtk-3.0/
cp gtk-4.0/settings.ini ~/.config/gtk-4.0/

echo "Making scripts executable..."

chmod +x ~/.config/eww/scripts/*.sh
chmod +x ~/.config/openbox/*.sh
if [ -d ~/.local/bin ]; then
    chmod +x ~/.local/bin/* 2>/dev/null || true
fi
chmod +x ~/.screenlayout/monitors.sh
chmod +x ~/.fehbg
chmod +x ~/.xinitrc

echo "Loading i2c-dev for monitor brightness..."

echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
sudo modprobe i2c-dev

echo "Installing yay AUR helper if needed..."

if ! command -v yay &> /dev/null
then
    sudo pacman -S --needed base-devel git

    rm -rf /tmp/yay
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si
    cd -
fi

echo "Installing AUR packages..."

if [ "${#aur_packages[@]}" -gt 0 ]; then
    yay -S --needed "${aur_packages[@]}"
fi

echo "Done."

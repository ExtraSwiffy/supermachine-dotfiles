#!/bin/bash

echo "Installing SuperMachine packages..."

sudo pacman -S --needed - < pkglist.txt

echo "Creating config folders..."

mkdir -p ~/.config
mkdir -p ~/Pictures/wallpapers
mkdir -p ~/.icons
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

echo "Copying wallpaper..."

cp -r wallpapers/* ~/Pictures/wallpapers/

echo "Copying configs..."

cp -r eww ~/.config/
cp -r openbox ~/.config/
cp -r rofi ~/.config/
cp -r picom ~/.config/
cp -r alacritty ~/.config/

cp .fehbg ~/
cp -r .screenlayout ~/

echo "Copying cursor theme..."

cp -r icons/ArchCursor ~/.icons/

cp .Xresources ~/
xrdb ~/.Xresources

cp gtk-3.0/settings.ini ~/.config/gtk-3.0/
cp gtk-4.0/settings.ini ~/.config/gtk-4.0/

echo "Making scripts executable..."

chmod +x ~/.config/eww/scripts/*.sh
chmod +x ~/.screenlayout/monitors.sh
chmod +x ~/.fehbg

echo "Loading i2c-dev for monitor brightness..."

echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
sudo modprobe i2c-dev

echo "Installing yay AUR helper if needed..."

if ! command -v yay &> /dev/null
then
    sudo pacman -S --needed base-devel git

    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si
    cd -
fi

echo "Installing AUR packages..."

yay -S --needed - < aurlist.txt

echo "Done."
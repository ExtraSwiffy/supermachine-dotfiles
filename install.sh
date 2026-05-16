#!/bin/bash

echo "Installing SuperMachine packages..."

sudo pacman -S --needed - < pkglist.txt

echo "Creating config folders..."

mkdir -p ~/.config

echo "Copying configs..."

cp -r eww ~/.config/
cp -r openbox ~/.config/
cp -r rofi ~/.config/
cp -r picom ~/.config/

cp .fehbg ~/
cp -r .screenlayout ~/

echo "Making scripts executable..."

chmod +x ~/.config/eww/scripts/*.sh
chmod +x ~/.screenlayout/monitors.sh

echo "Installing yay AUR helper if needed..."

if ! command -v yay &> /dev/null
then
    sudo pacman -S --needed base-devel git

    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si
fi

echo "Installing AUR packages..."

yay -S --needed - < aurlist.txt

echo "Done."
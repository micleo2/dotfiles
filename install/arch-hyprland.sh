#!/bin/sh

# setup software from pacman
sudo pacman -S waybar hyprpaper

# install walker and providers
paru -S walker-bin elephant-all-bin

# setup walker config files.
ln -sf ~/dotfiles/.config/walker/config.toml ~/.config/walker/
sudo mkdir -p /etc/xdg/walker/themes/omarchy-based/
sudo ln -sf ~/.config/mythemes/current/ /etc/xdg/walker/themes/omarchy-based/
sudo ln -sf ~/dotfiles/.config/walker/style.css /etc/xdg/walker/themes/omarchy-based/


#!/bin/sh

# setup software from pacman
sudo pacman -S waybar hyprpaper

# install walker and providers
paru -S walker-bin elephant-all-bin

# Setup themes
cd ~
mkdir oss
git clone https://github.com/basecamp/omarchy.git
ln -sf ~/oss/omarchy/themes ~/.config/mythemes
ln -sf ~/.config/mythemes/catppuccin ~/.config/mythemes/current

# setup walker config files.
ln -sf ~/dotfiles/.config/walker/config.toml ~/.config/walker/
sudo mkdir -p /etc/xdg/walker/themes/omarchy-based/
sudo ln -sf ~/.config/mythemes/current/ /etc/xdg/walker/themes/omarchy-based/
sudo ln -sf ~/dotfiles/.config/walker/style.css /etc/xdg/walker/themes/omarchy-based/

# setup hyprland config files.
mkdir ~/.config/hypr/
touch ~/.config/hypr/monitors.conf
ln -sf ~/dotfiles/.config/hypr/hyprland.conf ~/.config/hypr
ln -sf ~/dotfiles/.config/hypr/hyprpaper.conf ~/.config/hypr

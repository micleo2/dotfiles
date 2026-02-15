#!/bin/sh

# setup software from pacman
sudo pacman -S hyprpaper fuzzel hyprshot unixodbc
# needed by hyprpm
sudo pacman -S --needed cmake cpio

# setup hyprland config files.
ln -sf ~/dotfiles/.config/hypr/hyprland.conf ~/.config/hypr/
ln -sf ~/dotfiles/.config/hypr/hyprpaper.conf ~/.config/hypr/

# setup fuzzel config files.
mkdir ~/.config/fuzzel
ln -sf ~/dotfiles/.config/fuzzel/fuzzel.ini ~/.config/fuzzel/ && \
  ln -sf ~/dotfiles/.config/fuzzel/colors.ini ~/.config/fuzzel/

# cursor
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors && \
  hyprpm enable dynamic-cursors

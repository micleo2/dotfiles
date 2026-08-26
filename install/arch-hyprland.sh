#!/bin/sh

# setup software from pacman
sudo pacman -S hyprpaper rofi hyprshot unixodbc
# needed by hyprpm
sudo pacman -S --needed cmake cpio

# setup hyprland config files.
ln -sf ~/dotfiles/.config/hypr/hyprland.lua ~/.config/hypr/
ln -sf ~/dotfiles/.config/hypr/hyprpaper.conf ~/.config/hypr/
ln -sf ~/dotfiles/.config/hypr/monitors.lua ~/.config/hypr/
ln -sf ~/dotfiles/.config/hypr/universal-clipboard.lua ~/.config/hypr/
ln -sf ~/dotfiles/.config/hypr/appmap.lua ~/.config/hypr/

# app launcher + web app scripts
mkdir -p ~/.local/bin
for s in app-launch-or-focus webapp-install webapp-launch webapp-launch-or-focus webapp-remove; do
  ln -sf ~/dotfiles/scripts/apps/$s ~/.local/bin/
done

# setup fuzzel config files.
mkdir ~/.config/fuzzel
ln -sf ~/dotfiles/.config/fuzzel/fuzzel.ini ~/.config/fuzzel/ &&
  ln -sf ~/dotfiles/.config/fuzzel/colors.ini ~/.config/fuzzel/

# cursor
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors &&
  hyprpm enable dynamic-cursors

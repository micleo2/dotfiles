#!/bin/sh

# setup software from pacman
sudo pacman -S --needed hyprpaper rofi unixodbc f3d yazi gum
# needed by hyprpm
sudo pacman -S --needed cmake cpio

# applications
sudo pacman -S --needed freecad obsidian blender inkscape spotify-launcher

# everything hyprland.lua and the submaps shell out to:
#   quickshell            top bar + submap overlay (`qs -c retro`, `qs -c gw-idle`)
#   swaync                notification daemon
#   cliphist              clipboard history behind SUPER+SHIFT+V
#   libqalculate          `qalc`, the SUPER+U calculator scratchpad
#   hyprpicker            color picker in the screenshot submap
#   gpu-screen-recorder-ui  `gsr-ui-cli`, screenshots + recording
#   wl-clipboard          wl-copy/wl-paste, behind SUPER+V and the cliphist watchers
#   gtk3                  `gtk-launch`, how every SUPER+A entry starts its app
#   playerctl, wireplumber  media and volume keys
#   grim                  screen capture used by the screensaver
sudo pacman -S --needed quickshell swaync cliphist libqalculate hyprpicker gpu-screen-recorder-ui \
  wl-clipboard gtk3 playerctl wireplumber grim

# from the AUR (paru is bootstrapped in arch-setup.sh):
#   snappy-switcher  ALT+Tab switcher daemon
#   voxtype          push-to-talk dictation on SUPER+R
# paru -S --needed snappy-switcher voxtype

# make xdg-open detect real MIME types (mimetype reads shared-mime-info DB,
# not libmagic which misclassifies 3D/font files)
sudo pacman -S --needed perl-file-mimeinfo

# default app for 3D model files -> f3d
for m in model/stl model/step application/vnd.step model/obj model/iges \
  application/vnd.ply application/vnd.3ds application/vnd.dae \
  application/vnd.drc application/vnd.fbx application/vnd.off \
  application/vnd.vtk application/vnd.vtp model/gltf+json \
  model/gltf-binary application/vnd.usd application/vnd.usdc; do
  xdg-mime default f3d.desktop "$m"
done

# setup hyprland config files.
ln -s ~/dotfiles/.config/hypr/ ~/.config/
ln -s ~/dotfiles/ ~/.config/

# app launcher + web app scripts
mkdir -p ~/.local/bin
for s in app-launch-or-focus webapp-install webapp-launch webapp-launch-or-focus webapp-remove; do
  ln -sf ~/dotfiles/scripts/apps/$s ~/.local/bin/
done

# uwsm session environment
mkdir -p ~/.config/uwsm
ln -s ~/dotfiles/.config/uwsm/env ~/.config/uwsm/

# cursor
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors &&
  hyprpm enable dynamic-cursors

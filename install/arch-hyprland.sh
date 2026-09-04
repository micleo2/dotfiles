#!/bin/sh

# setup software from pacman
sudo pacman -S --needed hyprpaper fzf unixodbc f3d gum
# needed by hyprpm
sudo pacman -S --needed cmake cpio

# applications
sudo pacman -S --needed freecad obsidian blender inkscape spotify-launcher

sudo pacman -S --needed hyprpolkitagent
systemctl --user enable --now hyprpolkitagent.service

# everything hyprland.lua and the submaps shell out to:
#   quickshell            top bar, submap overlay and notification daemon (`qs -c retro`, `qs -c gw-idle`)
#   cliphist              clipboard history behind SUPER+SHIFT+V
#   libqalculate          `qalc`, the SUPER+U calculator scratchpad
#   hyprpicker            color picker in the screenshot submap
#   gpu-screen-recorder-ui  `gsr-ui-cli`, screenshots + recording
#   wl-clipboard          wl-copy/wl-paste, behind SUPER+V and the cliphist watchers
#   gtk3                  `gtk-launch`, how every SUPER+A entry starts its app
#   playerctl, wireplumber  media and volume keys
#   grim                  screen capture for scripts/ocr-region-select.sh
sudo pacman -S --needed quickshell cliphist libqalculate hyprpicker gpu-screen-recorder-ui \
  wl-clipboard gtk3 playerctl wireplumber grim

# from the AUR (paru is bootstrapped in arch-setup.sh):
#   snappy-switcher  ALT+Tab switcher daemon
#   voxtype          push-to-talk dictation on SUPER+R
# paru -S --needed snappy-switcher voxtype

# make xdg-open detect real MIME types (mimetype reads shared-mime-info DB,
# not libmagic which misclassifies 3D/font files)
sudo pacman -S --needed perl-file-mimeinfo

# setup hyprland config files.
ln -s ~/dotfiles/.config/hypr/ ~/.config/
ln -s ~/dotfiles/ ~/.config/

# app launcher + web app scripts
mkdir -p ~/.local/bin
for s in app-launch-or-focus webapp-install webapp-launch webapp-launch-or-focus webapp-remove; do
  ln -sf ~/dotfiles/scripts/apps/$s ~/.local/bin/
done

ln -sf ~/dotfiles/scripts/retro-launcher ~/.local/bin/
ln -sf ~/dotfiles/scripts/retro-ssh ~/.local/bin/

sudo pacman -S --needed hypridle
systemctl --user enable --now hypridle.service

# uwsm session environment
mkdir -p ~/.config/uwsm
ln -s ~/dotfiles/.config/uwsm/env ~/.config/uwsm/

# cursor
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors &&
  hyprpm enable dynamic-cursors

# Allow kitty to handle Terminal=true .desktop apps.
paru -S --needed xdg-terminal-exec
echo 'kitty.desktop' >~/.config/xdg-terminals.list

# Install and setup yazi as the system file picker.
sudo pacman -S --needed yazi
paru -S xdg-desktop-portal-termfilechooser-hunkyburrito-git

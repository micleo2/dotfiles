#!/bin/sh

# setup software from pacman
sudo pacman -S --needed hyprpaper rofi hyprshot unixodbc f3d yazi
# needed by hyprpm
sudo pacman -S --needed cmake cpio

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
paru -S --needed snappy-switcher voxtype

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

# default app for .3mf -> Bambu Studio (flatpak); only if the flatpak is installed
if command -v flatpak >/dev/null 2>&1 && flatpak info com.bambulab.BambuStudio >/dev/null 2>&1; then
  cat >~/.local/share/applications/bambu-studio-3mf.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Bambu Studio
Exec=flatpak run --filesystem=host --command=entrypoint com.bambulab.BambuStudio %F
MimeType=model/3mf;application/vnd.ms-3mfdocument;
NoDisplay=true
EOF
  for m in model/3mf application/vnd.ms-3mfdocument; do
    xdg-mime default bambu-studio-3mf.desktop "$m"
  done
fi

# setup hyprland config files.
ln -s ~/dotfiles/.config/hypr/ ~/.config/

# app launcher + web app scripts
mkdir -p ~/.local/bin
for s in app-launch-or-focus webapp-install webapp-launch webapp-launch-or-focus webapp-remove; do
  ln -sf ~/dotfiles/scripts/apps/$s ~/.local/bin/
done

# web app launchers (the SUPER+A webapp entries). The .desktop files live in
# ~/.local/share/applications and are generated, not tracked -- webapps.tsv is
# the tracked source of truth.
TAB=$(printf '\t')
while IFS="$TAB" read -r name url icon; do
  case "$name" in '' | '#'*) continue ;; esac
  ~/dotfiles/scripts/apps/webapp-install "$name" "$url" ~/dotfiles/install/webapp-icons/"$icon"
done <~/dotfiles/install/webapps.tsv

# uwsm session environment
mkdir -p ~/.config/uwsm
ln -sf ~/dotfiles/.config/uwsm/env ~/.config/uwsm/

# setup fuzzel config files.
mkdir ~/.config/fuzzel
ln -sf ~/dotfiles/.config/fuzzel/fuzzel.ini ~/.config/fuzzel/ &&
  ln -sf ~/dotfiles/.config/fuzzel/colors.ini ~/.config/fuzzel/

# cursor
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors &&
  hyprpm enable dynamic-cursors

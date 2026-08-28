#!/bin/sh

# setup software from pacman
sudo pacman -S --needed hyprpaper rofi hyprshot unixodbc f3d yazi
# needed by hyprpm
sudo pacman -S --needed cmake cpio

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

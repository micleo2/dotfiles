#!/bin/sh

# setup software from pacman
sudo pacman -S --needed base-devel git
# (xorg-xhost needed by gparted and rpi-imager)
sudo pacman -S --needed git github-cli os-prober man-db nvim nfs-utils fish unzip bat fd fzf rustup less bitwarden nodejs npm zoxide gparted xorg-xhost btop
sudo pacman -S --needed noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji otf-firamono-nerd ttf-jetbrains-mono-nerd
sudo pacman -S --needed pavucontrol syncthing discord gwenview
sudo pacman -S --needed pavucontrol ethtool ddcutil
sudo pacman -S --needed pavucontrol moonlight-qt

sudo pacman -S mesa

# Add sunshine repo (https://github.com/LizardByte/pacman-repo)
sudo pacman -S sunshine
# IMPORTANT: In webui, Configuration > Advanced > Force a Specific Capture Method > KMS

# For wake on lan config: https://wiki.archlinux.org/title/Wake-on-LAN#systemd_service
# Then `systemctl enable wol.service`

# enable syncthing on startup
systemctl --user enable --now syncthing.service

# Auto mounting USBs
sudo pacman -S udisks2 udiskie

# setup paru
git clone https://aur.archlinux.org/paru.git
cd paru
rustup default stable
makepkg -si
# Add SkipReview to /etc/paru.conf

# For a high res monitor, set the following in grub
# GRUB_GFXMODE=1920x1080x32

# setup github integration
gh auth login

# install fisher
sudo pacman -S --needed fisher &&
  fisher install PatrickF1/fzf.fish && fisher install kidonng/zoxide.fish

# Setup dotfiles
gh repo clone micleo2/dotfiles
mkdir ~/.config/nvim
ln -s ~/dotfiles/.config/lazynvim ~/.config/nvim &&
  ln -sf ~/dotfiles/.config/fish/config.fish ~/.config/fish/config.fish &&
  ln -s ~/dotfiles/.config/fish/functions/fish_prompt.fish ~/.config/fish/functions/ &&
  ln -s ~/dotfiles/.config/kitty/kitty.conf ~/.config/kitty &&
  ln -s ~/dotfiles/.config/kitty/current-theme.conf ~/.config/kitty &&

  # Kanata
  # Visit this link https://github.com/jtroo/kanata/wiki/Avoid-using-sudo-on-Linux
  paru -S kanata-bin

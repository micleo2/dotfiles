#!/bin/sh

# setup software from pacman
sudo pacman -S --needed base-devel git
# (xorg-xhost needed by gparted and rpi-imager)
sudo pacman -S git github-cli os-prober man-db nvim fish unzip bat fd fzf rustup nautilus less hyprpolkitagent bitwarden nodejs npm zoxide gparted xorg-xhost qmk tmux blueman
sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji otf-firamono-nerd ttf-jetbrains-mono-nerd
# Add sunshine repo (https://github.com/LizardByte/pacman-repo)
sudo pacman -S pavucontrol sunshine syncthing ethtool ddcutil discord gwenview btop

# For wake on lan config: https://wiki.archlinux.org/title/Wake-on-LAN#systemd_service
# Then `systemctl enable wol.service`

# enable syncthing on startup
systemctl --user enable --now syncthing.service

# setup paru
git clone https://aur.archlinux.org/paru.git
cd paru
rustup default stable
makepkg -si
# Add SkipReview to /etc/paru.conf

# For a high res monitor, set the following in grub
# GRUB_GFXMODE=1920x1080x32

# download software from paru
paru -S google-chrome kanata-bin
paru -S localsend

# setup github integration
gh auth login

# install fisher
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install PatrickF1/fzf.fish

# Setup dotfiles
gh repo clone micleo2/dotfiles
mkdir ~/.config/nvim
ln -sf ~/dotfiles/.config/nvim/init.lua ~/.config/nvim/
ln -sf ~/dotfiles/.config/fish/config.fish ~/.config/fish/config.fish 
ln -sf ~/dotfiles/.config/fish/functions/fish_prompt.fish ~/.config/fish/functions/
ln -sf ~/dotfiles/.config/kitty/kitty.conf ~/.config/kitty
ln -sf ~/dotfiles/.config/kitty/current-theme.conf ~/.config/kitty

# Kanata
# Visit this link https://github.com/jtroo/kanata/wiki/Avoid-using-sudo-on-Linux

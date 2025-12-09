#!/bin/sh

# setup software from pacman
sudo pacman -S --needed base-devel git
sudo pacman -S base-devel git github-cli nvim fish unzip bat fd fzf rustup dolphin less noto-fonts noto-fonts-cjk noto-fonts-extra noto-fonts-emoji otf-firamono-nerd nodejs npm

# setup paru
git clone https://aur.archlinux.org/paru.git
cd paru
rustup default stable
makepkg -si

# download software from paru
paru -S google-chrome kanata-bin

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

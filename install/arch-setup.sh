#!/bin/sh

# setup software from pacman
sudo pacman -S base-devel git github-cli nvim fish unzip bat fd fzf rustup

# setup paru
git clone https://aur.archlinux.org/paru.git
cd paru
rustup default stable
makepkg -si

# download software from paru
paru -S google-chrome kanata-bin

# setup github integration
gh auth login

# install chrome
paru -S google-chrome

# install fisher
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install PatrickF1/fzf.fish

# Setup dotfiles
gh repo clone micleo2/dotfiles
ln -sf ~/dotfiles/.config/nvim/init.lua ~/.config/nvim/
ln -sf ~/dotfiles/.config/fish/config.fish ~/.config/fish/config.fish 
ln -sf ~/dotfiles/.config/fish/functions/fish_prompt.fish ~/.config/fish/functions/

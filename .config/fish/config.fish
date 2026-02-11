set fish_greeting

fish_vi_key_bindings

# homebrew
export HOMEBREW_PREFIX="/opt/homebrew"

export HOMEBREW_CELLAR="/opt/homebrew/Cellar"

export HOMEBREW_REPOSITORY="/opt/homebrew"

fish_add_path /opt/homebrew/bin --path
fish_add_path /opt/homebrew/sbin --path

# Custom directories to add to PATH
fish_add_path $HOME/.local/mybin --path
fish_add_path $HOME/.local/bin --path

# fzf
fish_add_path ~/.fzf/bin/ --path
fzf_configure_bindings --directory=\ct

# --- Aliases and abbreviations
# neovim
alias v='nvim'
abbr --add vim nvim
abbr --add lnv 'nvim -u ~/.config/nvim/lean_init.vim'

# common dirs
abbr --add cdc 'cd ~/.config'
abbr --add cdd 'cd ~/dotfiles/.config'

# editing rc's
abbr --add ef 'nvim ~/.config/fish/config.fish && source ~/.config/fish/config.fish'
abbr --add et 'nvim ~/.tmux.conf'
abbr --add ev 'nvim ~/.config/nvim/init.vim'
abbr --add ea 'nvim ~/.aerospace.toml'
abbr --add eh 'nvim ~/.config/hypr/hyprland.conf'
abbr --add ec 'nvim (fd . ~/.config -t file | fzf)'
abbr --add ed 'nvim (fd . ~/dotfiles/.config -t file | fzf)'

# git
abbr --add gs 'git status'
abbr --add ga 'git add .'
abbr --add gc --set-cursor 'git commit -m "%"'
abbr --add gd 'git diff'
abbr --add diff 'git diff --no-index'

# tmux
abbr --add tls 'tmux ls'
abbr --add tks 'tmux kill-server'
abbr --add ta 'tmux a -t'
abbr --add tn 'tmux new -s'

abbr --add rp realpath
abbr --add rpc --set-cursor 'realpath % | pbcopy'

# debugging
abbr --add sdbg 'ln -sf (realpath (fzf)) /tmp/todbg'
abbr --add sdbf 'ln -sf (realpath (fzf)) /tmp/file.js'

# arch stuff
abbr --add pi 'sudo pacman -S --needed'
abbr --add pr 'sudo pacman -Rns'

# --- VARIABLES
set -Ux EDITOR 'nvim'

# Setup zoxide
zoxide init fish | source

# --- Load additional, optional config files.
if test -e ~/.config/fish/conf.d/work.fish
    source ~/.config/fish/conf.d/work.fish
end

if test -e ~/.config/fish/conf.d/home.fish
    source ~/.config/fish/conf.d/home.fish
end

if test -e ~/.cargo/env.fish
    source ~/.cargo/env.fish
end

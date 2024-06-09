if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting

# homebrew
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
fish_add_path /opt/homebrew/bin --path
fish_add_path /opt/homebrew/sbin --path

fish_add_path $HOME/.local/mybin --path
fish_add_path $HOME/.local/bin --path

# fzf
fish_add_path ~/.fzf/bin/ --path
fzf_configure_bindings --directory=\ct

# GENERAL ALIASES ------------------------------------------------------------------
# kitty theme
abbr --add dark kitty +kitten themes Catppuccin-Mocha
abbr --add light kitty +kitten themes Catppuccin-Latte

abbr --add python python3

# neovim
alias v='nvim'
abbr --add vim 'nvim'
abbr --add lnv 'nvim -u ~/.config/nvim/lean_init.vim'

# editing rc's
abbr --add ez 'nvim ~/.zshrc'
abbr --add ef 'nvim ~/.config/fish/config.fish && source ~/.config/fish/config.fish'
abbr --add et 'nvim ~/.tmux.conf'
abbr --add ev 'nvim ~/.config/nvim/init.vim'
abbr --add ea 'nvim ~/.aerospace.toml'
abbr --add sf 'source ~/.config/fish/config.fish'

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

abbr --add rp 'realpath'

export EDITOR='/Users/fbmal7/nvims/0.9.0-dev/bin/nvim'

if test -e ~/.config/fish/conf.d/work.fish
  source ~/.config/fish/conf.d/work.fish
end

if test -e ~/.config/fish/conf.d/home.fish
  source ~/.config/fish/conf.d/home.fish
end

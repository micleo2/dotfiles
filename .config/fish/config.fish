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

# ls
abbr --add ll 'ls -alh'

# editing rc's
abbr --add ef 'nvim ~/.config/fish/config.fish && source ~/.config/fish/config.fish'
abbr --add et 'nvim ~/.tmux.conf'
abbr --add ev 'nvim ~/.config/nvim/init.vim'
abbr --add ea 'nvim ~/.aerospace.toml'
abbr --add eh 'cd ~/.config/hypr && nvim ~/.config/hypr/hyprland.lua'
abbr --add ez 'nvim ~/.config/zellij/config.kdl'
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

# quickly add an absoulte path to clipboard
abbr --add rp --set-cursor 'realpath % | wl-copy -n'
function append_wl_copy -d "append wl-copy to current or last command"
    set -l cmd (commandline)
    # If the current typed line is empty, grab the last line.
    if test -z "$cmd"
        set cmd $history[1]
    end
    # Append the pipe and update the command line buffer
    commandline -r "$cmd | wl-copy -n"
end
bind -M insert \ec append_wl_copy
bind \ec append_wl_copy

# debugging
abbr --add sdbg 'ln -sf (realpath (fzf)) /tmp/todbg'
abbr --add sdbf 'ln -sf (realpath (fzf)) /tmp/file.js'

# arch stuff
abbr --add pi 'sudo pacman -S --needed'
abbr --add pr 'sudo pacman -Rns'
abbr --add oc 'OPENCODE_ENABLE_EXA=true opencode'

abbr --add uz unzip

# --- VARIABLES
set -Ux EDITOR nvim

# Setup zoxide
zoxide init fish | source

# yazi
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

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

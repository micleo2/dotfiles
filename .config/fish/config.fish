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

# fzf
fish_add_path ~/.fzf/bin/ --path
fzf_configure_bindings --directory=\ct

# GENERAL ALIASES ------------------------------------------------------------------
# kitty theme
abbr --add dark kitty +kitten themes Catppuccin-Mocha
abbr --add light kitty +kitten themes Catppuccin-Latte

abbr --add python python3

# neovim
alias nvim='~/nvims/0.9.5/bin/nvim'
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
abbr --add gc 'git commit'
abbr --add diff 'git diff --no-index'

# tmux
abbr --add tls 'tmux ls'
abbr --add tks 'tmux kill-server'
abbr --add ta 'tmux a -t'
abbr --add tn 'tmux new -s'

abbr --add rp 'realpath'

export EDITOR='/Users/fbmal7/nvims/0.9.0-dev/bin/nvim'

# # WORK STUFF -----------------------------------------------------------------------
# # misc internal tools
abbr --add s 'mosh -6 devvm12221.prn0.facebook.com'
abbr --add af 'arc f'
abbr --add u 'hg pull && hg co remote/master'

# hg
abbr --add hgd 'hg diff'
abbr --add hga 'hg absorb'
abbr --add hgs 'hg status .'
abbr --add hgl 'hg log --limit 3'
abbr --add hgll 'hg hg-sl-up'
abbr --add hgr 'hg revert .'

# common dirs
abbr --add C 'cd ~/fbsource/xplat/hermes/'
abbr --add c 'cd ~/fbsource/xplat/static_h/'
abbr --add cdb 'cd ~/builds/shdebug/'
abbr --add cdr 'cd ~/builds/shrelease/'
abbr --add cdB 'cd ~/builds/debug/'
abbr --add cdR 'cd ~/builds/release/'
abbr --add cdt 'cd ~/tests/'
abbr --add cdc 'cd ~/.config/'

# common build invocations
abbr --add n 'ninja hermes hermesvm shermes'
abbr --add N 'ninja hermes'
abbr --add nh 'ninja hermes && ./bin/hermes'
abbr --add nH 'ninja hermesvm shermes && ./bin/shermes'
abbr --add nl 'ninja hermes && lldb -- ./bin/hermes'
abbr --add nL 'ninja shermes && lldb -- ./bin/shermes'
abbr --add nu 'ninja update-lit'
abbr --add nc 'ninja check-hermes'
abbr --add t262 '/Users/fbmal7/fbsource/xplat/hermes/utils/testsuite/run_testsuite.py -b ~/builds/debug/bin'
abbr --add compdb 'ninja -t compdb > ~/fbsource/xplat/hermes/compile_commands.json'
abbr --add shcompdb 'ninja -t compdb > ~/fbsource/xplat/static_h/compile_commands.json'

# hardcoded binary paths
alias jsc='/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc'
alias v8='/Users/fbmal7/oss/v8/out/x64.release/d8'
alias mypy='/Users/fbmal7/.pyenv/versions/3.8.18/bin/python3'

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/mike/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  # git
  zsh-autosuggestions
  z
  colored-man-pages
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
# alias ssh_241='ssh mal7@fa18-cs241-164.cs.illinois.edu'
alias ssh_427='ssh mal7@fa20-cs427-125.cs.illinois.edu'
alias pl='git pull'
alias ph='git push'
alias gs='git status'
alias gr='git remote -v'
alias tg='sh ~/development/dotfiles/tmuxgo.sh'
alias tgr='sh ~/development/dotfiles/tmuxgo.sh irb'
alias tgp='sh ~/development/dotfiles/tmuxgo.sh python3'
alias tgh='sh ~/development/dotfiles/tmuxgo.sh ghci'
alias tls='tmux ls'
alias ta='tmux a -t '
alias s='. ~/.zshrc'
alias se='vim ~/.zshrc'
alias gn='git checkout -b '
alias gd='git diff'
alias gc='git checkout '
alias gf='git fetch'
alias gl='git log'
alias gcp='git checkout -'
# alias sa='tmux send-keys "yarn start" C-m && tmux split-window && tmux send-keys -t down "yarn android"'
alias sa='tmux send-keys "yarn start" C-m && tmux send-keys -t bottom "yarn android" C-m'
alias ys='yarn start'
alias ya='yarn android'

function scottify(){
	PS1='\[\e[32m>\]\[\e[0m\] '
}

# alias func='git josh'
# func() {
#   command ls
# }

# tmux send keys to the right
function tsr {
  args=$@
  tmux send-keys -t right "$args" C-m
}

export GOROOT=/usr/local/go
export GOPATH='/home/mike/go'
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# give width and height of grid as parameters
# start with window containing just a single pane
function tgrid() {
  for (( n = 1; n < $1; n++ )); do
    tmux split-window -h -t $n
  done
  tmux select-layout even-horizontal

  width=$(tmux display -p '#{window_width}')
  height=$(tmux display -p '#{window_height}')
  cell_width=$(($width/$1))
  cell_height=$(($height/$2))

  for (( tpane = 1; tpane <= $1 * ($2-1); tpane++ )); do
    tmux split-window -v -t $tpane
    tmux resize-pane -t $tpane -x $cell_width -y $cell_height
  done
}

function grr(){
  grep -R $@ ./* -n
}

function lcl(){
  cat > "$1.py" <<- EOF
# Definition for singly-linked list.
class ListNode:
    def __init__(self, x):
        self.val = x
        self.next = None
def linked(ls):
    if len(ls) == 0:
        return None
    head = ListNode(ls[0])
    cur = head
    for i in range(1, len(ls)):
        cur.next = ListNode(ls[i])
        cur = cur.next
    return head
def print_linked(head):
    vals = []
    while head is not None:
        vals.append(str(head.val))
        head = head.next
    print("vals: ", vals)
    print("->".join(vals))

class Solution:
    def $1(self, holder):
      return holder

obj = Solution()

print(obj.$1(sample))
EOF
  vim "$1.py"
}

function lc(){
  cat > "$1.py" <<- EOF
class Solution:
    def $1(self, holder):
      return holder

obj = Solution()

print(obj.$1(sample))
EOF
  vim "$1.py"
}


export TORCH_ROOT=~/torch
export JAVA_OPTS='-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee'


. /home/mike/torch/install/bin/torch-activate

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/mike/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/mike/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/mike/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/mike/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


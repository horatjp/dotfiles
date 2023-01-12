export LANG=ja_JP.UTF-8

# alias
source ~/dotfiles/zsh/.zshrc.alias

# history
source ~/dotfiles/zsh/.zshrc.history

# enable zsh default function
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 100
zstyle ':chpwd:*' recent-dirs-default yes
zstyle ':completion:*' recent-dirs-insert both

# option
setopt no_beep

# HomeBrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# asdf
. $(brew --prefix asdf)/libexec/asdf.sh

# direnv
eval "$(direnv hook zsh)"

# starship
eval "$(starship init zsh)"

# fzf
if [ -f ~/dotfiles/fzf/.fzf.zsh ]; then
  source ~/dotfiles/fzf/.fzf.zsh
  source ~/dotfiles/fzf/.zshrc.fzf
fi

# zsnap
[[ -f ~/.zsh/zsh-snap/znap.zsh ]] ||
    git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git ~/.zsh/zsh-snap

source ~/.zsh/zsh-snap/znap.zsh

# zsh plugins
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting
znap source marlonrichert/zsh-autocomplete


# initialize autocomplete
autoload -Uz compinit && compinit -u

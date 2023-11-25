export LANG=ja_JP.UTF-8  # Character encoding
export EDITOR=vim        # Editor

setopt no_beep           # Disable beep sound
setopt correct           # Automatically correct command spelling

# alias
[ -f ~/.zshrc.alias ] && source ~/.zshrc.alias

# history
[ -f ~/.zshrc.history ] && source ~/.zshrc.history

# znap
[ -f ~/.zshrc.znap ] && source ~/.zshrc.znap

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.zshrc.fzf ] && source ~/.zshrc.fzf

# starship
eval "$(starship init zsh)"

# ssh-agent
eval "$(ssh-agent -s)"

# asdf
. $(brew --prefix asdf)/libexec/asdf.sh

# gh completion
[ -n "$(which gh)" ] && eval "$(gh completion -s zsh)"

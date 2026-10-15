export ZDOTDIR="$HOME/.config/zsh"

# PATH(入れ子のシェルや tmux で同じパスが重ならないよう重複を落とす)
typeset -U path PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.agents/bin:$PATH"

export LANG=ja_JP.UTF-8     # 文字コード
export LC_ALL=ja_JP.UTF-8   # ロケール
export EDITOR=nvim          # エディタ
setopt no_beep              # ビープ音を鳴らさない
setopt correct              # コマンドのスペルを自動修正
setopt auto_cd              # ディレクトリ名だけでcd
setopt interactive_comments # コマンドライン上のコメントを有効化

# 環境変数の読み込み
if [ -f "$HOME/.env" ]; then
  set -a
  source "$HOME/.env"
  set +a
fi

# alias
[ -f "$ZDOTDIR/.zshrc.alias" ] && source "$ZDOTDIR/.zshrc.alias"

# history
[ -f "$ZDOTDIR/.zshrc.history" ] && source "$ZDOTDIR/.zshrc.history"

# WSL
if [[ "$(uname -r)" == *microsoft* ]]; then
  [ -f "$ZDOTDIR/.zshrc.wsl" ] && source "$ZDOTDIR/.zshrc.wsl"
fi

# znap
[ -f "$ZDOTDIR/.zshrc.znap" ] && source "$ZDOTDIR/.zshrc.znap"

# starship
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

# fzf
(( $+commands[fzf] )) && eval "$(fzf --zsh)"
[ -f "$ZDOTDIR/.zshrc.fzf" ] && source "$ZDOTDIR/.zshrc.fzf"

# mise
eval "$(mise activate zsh)"
eval "$(mise completion zsh)"

# docker completion (WSL: skip if daemon is not running)
(( $+commands[docker] )) && docker info &>/dev/null && source <(docker completion zsh)

# ssh-agent
SSH_ENV="${HOME}/.ssh/agent.env"

agent_start() {
    ssh-agent -s -t 1h > "${SSH_ENV}"
    chmod 600 "${SSH_ENV}"
    source "${SSH_ENV}" > /dev/null
}

# ssh-agentが起動しているか確認
if [ -f "${SSH_ENV}" ]; then
    source "${SSH_ENV}" > /dev/null
    # プロセスが実際に動いているか確認
    ps -p ${SSH_AGENT_PID} > /dev/null 2>&1 || agent_start
else
    agent_start
fi

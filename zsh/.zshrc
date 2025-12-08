export LANG=ja_JP.UTF-8   # 文字コード
export LC_ALL=ja_JP.UTF-8 # ロケール
export EDITOR=vim         # エディタ
setopt no_beep            # ビープ音を鳴らさない
setopt correct            # コマンドのスペルを自動修正
setopt auto_cd            # ディレクトリ名だけでcd
setopt interactive_comments # コマンドライン上のコメントを有効化

# 環境変数の読み込み
if [ -f "$HOME/.env" ]; then
  set -a
  source "$HOME/.env"
  set +a
fi

# alias
[ -f ~/.zshrc.alias ] && source ~/.zshrc.alias

# history
[ -f ~/.zshrc.history ] && source ~/.zshrc.history

# WSL
if [[ "$(uname -r)" == *microsoft* ]]; then
  [ -f ~/.zshrc.wsl ] && source ~/.zshrc.wsl
fi

# znap
[ -f ~/.zshrc.znap ] && source ~/.zshrc.znap

# starship
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.zshrc.fzf ] && source ~/.zshrc.fzf

# mise
eval "$(mise activate zsh)"

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

# path
export PATH="$HOME/.cache/.bun/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

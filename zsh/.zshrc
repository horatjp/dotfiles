export LANG=ja_JP.UTF-8     # 文字コード
export LC_ALL=ja_JP.UTF-8   # ロケール
export EDITOR=nvim          # エディタ
setopt no_beep              # ビープ音を鳴らさない
setopt correct              # コマンドのスペルを自動修正
setopt auto_cd              # ディレクトリ名だけでcd
setopt interactive_comments # コマンドライン上のコメントを有効化

# 1Password: ~/.env の op:// 参照を展開して現在のシェルに読み込む
# 展開結果は一時ディレクトリにキャッシュし、認証を再起動後の初回のみにする
# （1Password CLI は新しいターミナルセッションごとに確認を出す仕様のため）
OPENV_CACHE="${TMPDIR:-/tmp}/openv.env"
openv() {
  (umask 077; op inject -i "$HOME/.env" > "$OPENV_CACHE") || { rm -f "$OPENV_CACHE"; return 1; }
  set -a
  source "$OPENV_CACHE"
  set +a
}

# 環境変数の読み込み
# op:// 参照を含む場合はキャッシュ→1Password の順で展開（op がない環境ではスキップ）
if [ -f "$HOME/.env" ]; then
  if grep -q "op://" "$HOME/.env"; then
    if [ -s "$OPENV_CACHE" ]; then
      set -a
      source "$OPENV_CACHE"
      set +a
    elif command -v op >/dev/null 2>&1; then
      openv 2>/dev/null
    fi
  else
    set -a
    source "$HOME/.env"
    set +a
  fi
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

# OrbStack completion
if (( $+commands[orbctl] )); then
  eval "$(orbctl completion zsh)"
  compdef _orb orbctl
  compdef _orb orb
fi

# ssh-agent
# macOS: 1Password SSH エージェントがあれば優先（なければ従来の ssh-agent 運用）
OP_SSH_SOCK="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [ -S "${OP_SSH_SOCK}" ]; then
    export SSH_AUTH_SOCK="${OP_SSH_SOCK}"
else
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
fi

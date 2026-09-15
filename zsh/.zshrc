export LANG=ja_JP.UTF-8     # 文字コード
export LC_ALL=ja_JP.UTF-8   # ロケール
export EDITOR=nvim          # エディタ
setopt no_beep              # ビープ音を鳴らさない
setopt correct              # コマンドのスペルを自動修正
setopt auto_cd              # ディレクトリ名だけでcd
setopt interactive_comments # コマンドライン上のコメントを有効化

# 1Password: ~/.env の環境変数を現在のシェルに読み込む。~/.env の種類で方式が変わる
# - 名前付きパイプ(Mac): 1Password Environments のマウント。読むたびにアプリが中身を渡し、平文はディスクに残らない
# - 通常ファイル(WSL 等): op:// 参照を op inject で展開し、結果を一時ディレクトリにキャッシュする
#   （1Password CLI は新しいターミナルセッションごとに確認を出す仕様のため、認証を再起動後の初回のみにする）
OPENV_CACHE="${TMPDIR:-/tmp}/openv.env"
openv() {
  (umask 077; op inject -i "$HOME/.env" > "$OPENV_CACHE") || { rm -f "$OPENV_CACHE"; return 1; }
  set -a
  source "$OPENV_CACHE"
  set +a
}

# パイプは読むたびに 1Password へ要求が飛び、アプリが応答しないと読み取りが固まる。
# 1 回だけ読んで変数に受け、アプリの起動確認とタイムアウト（承認ダイアログに答える時間を見て 60 秒）を入れる。
# 複数のシェルが同時に読むと一部が空になる（公式の制限。herdr でペインを一斉に開くと起きる）ため、
# ロックで 1 つずつ読み、読み取りは成功したのに空だった場合だけ少し待って読み直す
openv_pipe() {
  pgrep -xi 1password >/dev/null || return 1
  local lock="$HOME/.cache/openv.lock" fd= out= i
  # zsystem flock はロックファイルを作らないので先に用意する
  mkdir -p "${lock:h}" && { [ -e "$lock" ] || : > "$lock"; }
  zmodload -F zsh/system b:zsystem 2>/dev/null && zsystem flock -t 65 -f fd "$lock" 2>/dev/null
  for i in 1 2 3; do
    out=$(
      cat "$HOME/.env" & p=$!
      ( sleep 60; kill $p ) >/dev/null 2>&1 & w=$!
      wait $p; s=$?; kill $w 2>/dev/null; exit $s
    ) || break
    [ -n "$out" ] && break
    sleep 0.3
  done
  [ -n "$fd" ] && zsystem flock -u "$fd"
  [ -n "$out" ] || return 1
  set -a
  source <(print -r -- "$out")
  set +a
}

# 環境変数の読み込み
# op:// 参照を含む場合はキャッシュ→1Password の順で展開（op がない環境ではスキップ）
if [ -p "$HOME/.env" ]; then
  openv_pipe 2>/dev/null
elif [ -f "$HOME/.env" ]; then
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

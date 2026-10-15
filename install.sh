#!/usr/bin/env bash

set -e

# sudo
# 途中で何度もパスワードを聞かれないよう、実行中だけパスワードなしの sudo を許す。
# 終わったら(途中で失敗しても)消す。常に残すと、エージェントからも確認なしで root に届くため
SUDOERS_FILE="/etc/sudoers.d/$(whoami)"
echo "$(whoami) ALL=(root) NOPASSWD:ALL" | sudo tee "$SUDOERS_FILE" > /dev/null
trap 'sudo rm -f "$SUDOERS_FILE"' EXIT

# not macOS
if [ "$(uname)" != 'Darwin' ]; then
  # apt
  echo "# apt"
  sudo apt-get update
  sudo apt install -y build-essential curl dnsutils file fonts-noto-cjk git jq locales nfs-client rsync tree wget whois zip zsh

  ## apt GUI
  sudo apt-get install -y libgtk-3-0t64 libgtk-3-common libnotify-dev libnss3 libxss1 libasound2t64 libxtst6 libgbm-dev wl-clipboard xauth xvfb feh

  ## apt Chromium
  sudo apt-get install -y chromium

  ## apt Python build
  sudo apt-get install -y libffi-dev libssl-dev libbz2-dev libsqlite3-dev libreadline-dev libncurses-dev liblzma-dev tk-dev zlib1g-dev

  # locale
  echo "# locale"
  sudo sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen
  sudo locale-gen
  sudo update-locale LANG=ja_JP.UTF-8
fi

# macOS
if [ "$(uname)" == 'Darwin' ]; then
  if [ -n "$(which xhost)" ]; then
    # Allow X11 connections
    xhost + localhost
  fi
fi

# WSL
if [ -n "$(which explorer.exe)" ]; then

  echo "# WSL setting"
  if [ ! -d ~/dotfiles ]; then
    ln -sf /mnt/c/Users/$(/mnt/c/Windows/System32/cmd.exe /c "<nul set /p=%UserName%" 2>/dev/null)/dotfiles ~/dotfiles
  fi

  if [ ! -d ~/.ssh ]; then
    ln -sf /mnt/c/Users/$(/mnt/c/Windows/System32/cmd.exe /c "<nul set /p=%UserName%" 2>/dev/null)/.ssh ~/.ssh
  fi

  # 既存の wsl.conf(systemd や既定ユーザーの設定)を消さないよう、[automount] が無いときだけ追記する
  if ! grep -qs '^\[automount\]' /etc/wsl.conf; then
    echo -e "[automount]\noptions = \"metadata,umask=22,fmask=11\"" | sudo tee -a /etc/wsl.conf
  fi

  # DNS
  echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
  echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
fi

# Homebrew
if [ ! -n "$(which brew)" ]; then

  echo "# Homebrew"
  export NONINTERACTIVE=1
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  mkdir -p ~/.config/zsh
  if [ "$(uname)" == 'Darwin' ]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.config/zsh/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ "$(uname)" == 'Linux' ]; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.config/zsh/.zprofile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

ln -sf ~/dotfiles/homebrew/Brewfile ~/Brewfile
brew bundle install --file=~/Brewfile --verbose

# git
mkdir -p ~/.config/git
ln -sf ~/dotfiles/git/config ~/.config/git/config
ln -sf ~/dotfiles/git/ignore ~/.config/git/ignore

# Create config.local if it doesn't exist
if [ ! -f ~/.config/git/config.local ]; then
  cat >~/.config/git/config.local <<EOF
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL
EOF
  echo "Created ~/.config/git/config.local - Please edit it to set your name and email"
fi

# vim
mkdir -p ~/.config/vim
ln -sf ~/dotfiles/vim/vimrc ~/.config/vim/vimrc

# ディレクトリへのリンクは -n を付ける(無いと、再実行時に既存リンクの先=リポジトリ内へリンクを作ってしまう)
# Neovim
mkdir -p ~/.config
# 以前の install.sh は ~/.config/nvim を実ディレクトリで作っていた。そのままだとリンクが中に作られるので退避する
[ -d ~/.config/nvim ] && [ ! -L ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d%H%M%S)
ln -sfn ~/dotfiles/nvim ~/.config/nvim

# scripts
ln -sfn ~/dotfiles/scripts ~/scripts
chmod +x ~/dotfiles/scripts/*

# zsh
mkdir -p ~/.config/zsh
ln -sf ~/dotfiles/zsh/.zshenv ~/.zshenv
# ~/.env(git 管理外)から API キーを読み込む。実体はマシンごとに自分で用意する
#  - Mac: 1Password Environments を ~/.env にマウントする(名前付きパイプ。平文はディスクに残らない)
#  - WSL 等: op:// 参照を書いた通常ファイルを置く(.zshrc が op inject で展開してキャッシュする)
# パイプを -f で判定すると「無い」扱いになるため、種類を問わず存在で判定する
if [ ! -e ~/.env ]; then
  echo "~/.env がありません。1Password Environments をマウントするか、op:// 参照を書いたファイルを作成してください"
fi
ln -sf ~/dotfiles/zsh/.zshrc ~/.config/zsh/.zshrc
ln -sf ~/dotfiles/zsh/.zshrc.alias ~/.config/zsh/.zshrc.alias
ln -sf ~/dotfiles/zsh/.zshrc.history ~/.config/zsh/.zshrc.history

# WSL
ln -sf ~/dotfiles/zsh/.zshrc.wsl ~/.config/zsh/.zshrc.wsl

# Znap
ln -sf ~/dotfiles/zsh/.zshrc.znap ~/.config/zsh/.zshrc.znap
ln -sf ~/dotfiles/zsh/.zshrc.fzf ~/.config/zsh/.zshrc.fzf

# starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# tmux
mkdir -p ~/.config/tmux
ln -sf ~/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
# TPM (tmux plugin manager)
if [ ! -d ~/.config/tmux/plugins/tpm ]; then
  mkdir -p ~/.config/tmux/plugins
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi

# herdr
# 設定ディレクトリにはログ・ソケットも作られるため config.toml のみリンクする
mkdir -p ~/.config/herdr
ln -sf ~/dotfiles/herdr/config.toml ~/.config/herdr/config.toml
# 通知音(config.toml から相対参照)。リンク元基準で解決されても見つかるよう置く
ln -sfn ~/dotfiles/herdr/sounds ~/.config/herdr/sounds
command -v herdr >/dev/null && herdr plugin install smarzban/herdr-file-viewer --yes

# druk
mkdir -p ~/.config/druk
ln -sf ~/dotfiles/druk/config.json ~/.config/druk/config.json

# mise
mkdir -p ~/.config/mise
ln -sf ~/dotfiles/mise/mise.toml ~/.config/mise/config.toml
mise install
# 以降の npm / npx は mise が入れた node を使う(非対話の bash では mise が有効になっていない)
eval "$(mise activate bash --shims)"

# EditorConfig
ln -sf ~/dotfiles/editorconfig/.editorconfig ~/.editorconfig


# Claude
mkdir -p ~/.claude
ln -sf ~/dotfiles/claude/AGENTS.md ~/.claude/CLAUDE.md
# settings.json はツール(herdr 連携や /config)が書き込む実ファイルとして各マシンに持ち、
# 共有ベース(settings.base.json)を jq でマージして反映する。
# スカラーはベース優先、配列は和集合(ローカル分を先に保ち重複は落とす)、ローカルだけのキーは残す。
# マシン固有の絶対パスを含むフック等はベースに入れず、ローカル側に書く。
[ -L ~/.claude/settings.json ] && rm ~/.claude/settings.json  # 旧 symlink 方式からの移行
[ -f ~/.claude/settings.json ] || echo '{}' > ~/.claude/settings.json
jq -s '
  def merge($a; $b):
    if ($a | type) == "object" and ($b | type) == "object" then
      reduce (($a | keys) + ($b | keys) | unique | .[]) as $k ({}; .[$k] = merge($a[$k]; $b[$k]))
    elif ($a | type) == "array" and ($b | type) == "array" then $a + ($b - $a)
    elif $b == null then $a
    else $b end;
  merge(.[0]; .[1])
' ~/.claude/settings.json ~/dotfiles/claude/settings.base.json > ~/.claude/settings.json.tmp
mv ~/.claude/settings.json.tmp ~/.claude/settings.json
ln -sfn ~/dotfiles/claude/agents ~/.claude/agents
ln -sfn ~/dotfiles/claude/skills ~/.claude/skills
# ~/.claude.json はログイン情報やプロジェクトごとの状態も持つ実ファイルなので、mcpServers だけを差し替える
[ -s ~/.claude.json ] || echo '{}' > ~/.claude.json
jq -s '.[0] * {mcpServers: ((.[0].mcpServers // {}) + .[1].mcpServers)}' ~/.claude.json ~/dotfiles/claude/mcp.json > ~/.claude.json.tmp
mv ~/.claude.json.tmp ~/.claude.json
curl -fsSL https://claude.ai/install.sh | bash

# Codex
mkdir -p ~/.codex
ln -sf ~/dotfiles/codex/AGENTS.md ~/.codex/AGENTS.md
ln -sfn ~/dotfiles/codex/skills ~/.codex/skills
# config.toml は Codex が projects.* / hooks.state 等を書き込むユーザー層(~/.codex/config.toml)には置かず、
# 共有分を system 層(/etc/codex/config.toml、ユーザー層より低優先でキー単位に深くマージされる)へリンクする。
# 配列キー(writable_roots 等)は層をまたいで置換されるため、共有側とローカル側の両方に書かない。
sudo mkdir -p /etc/codex
sudo ln -sfn ~/dotfiles/codex/config.toml /etc/codex/config.toml
if [ -L ~/.codex/config.toml ]; then  # 旧 symlink 方式からの移行: Codex の書き込みがリポジトリへ混ざらないよう実ファイル化
  target="$(readlink -f ~/.codex/config.toml)"
  rm ~/.codex/config.toml && cp "$target" ~/.codex/config.toml
fi
npm install -g @openai/codex

# Pi (earendil-works/pi)
# スキルは ~/.agents/skills のみ標準で読むため、~/.claude/skills を skills に冪等に追加する。
# settings.json は Pi も書き込むため dotfiles では管理しない(同名スキルは ~/.claude/skills 側が優先される)
npm install -g @earendil-works/pi-coding-agent
mkdir -p ~/.pi/agent
[ -f ~/.pi/agent/settings.json ] || echo '{}' > ~/.pi/agent/settings.json
jq '.skills = ((.skills // []) | if index(["~/.claude/skills"]) then . else . + ["~/.claude/skills"] end)' ~/.pi/agent/settings.json > ~/.pi/agent/settings.json.tmp
mv ~/.pi/agent/settings.json.tmp ~/.pi/agent/settings.json
# 拡張(確認ダイアログ・保護パス)はディレクトリごとリンクする。実ディレクトリがあると ln が中にリンクを作るので退避する
[ -d ~/.pi/agent/extensions ] && [ ! -L ~/.pi/agent/extensions ] && mv ~/.pi/agent/extensions ~/.pi/agent/extensions.bak.$(date +%Y%m%d%H%M%S)
ln -sfn ~/dotfiles/pi/extensions ~/.pi/agent/extensions
# Pi は OpenRouter だけで使う。Pi にはプロバイダーを止める設定がなく、環境変数にキーがあるプロバイダーは
# すべて使える扱いになる。models.json で他のプロバイダーのキーを、定義しない変数 $PI_DISABLED_KEY に向けて外す
# (シェルの ANTHROPIC_API_KEY などは他のツール用にそのまま残る)。models.json は Pi が書き込まないのでリンクする
ln -sf ~/dotfiles/pi/models.json ~/.pi/agent/models.json
# Pi パッケージ(版を固定。入れた記録は settings.json の packages に残る)
#   pi-web-access: Web 検索・取得 / pi-usage: OpenRouter 残高 / rpiv-ask-user-question: 選択式の質問
#   cc-safety-net: 危険なコマンドと秘密ファイルの読み取りを止める / context-mode: ツール出力を会話に入れず索引に逃がす
for pkg in pi-web-access@0.41.0 @narumitw/pi-usage@0.66.0 @juicesharp/rpiv-ask-user-question@2.13.8 cc-safety-net@2.6.12 context-mode@1.0.169; do
  pi install "npm:$pkg"
done
# context-mode は MCP サーバー本体を別に入れる。postinstall が ~/.claude/settings.json の enabledPlugins に
# 勝手に true を書くため、settings.base.json で false(明示的な opt-out は書き換えない)を先に入れておく
npm install -g context-mode@1.0.169
jq -e '.mcpServers["context-mode"]' ~/.pi/agent/mcp.json >/dev/null 2>&1 || pi mcp add context-mode -- context-mode

# Cloudflare cf (Wrangler 後継の統合CLI。beta)
npm install -g cf

# Dev Container CLI
npm install -g @devcontainers/cli

# Third-party skills (gitでは追跡しない / .gitignore 参照)
# --all は「全スキルを全エージェント(約50個の ~/.<agent>/ を生成)へ配布」なので使わない。
# 相対リンクは ~/.claude/skills(symlink)経由だと壊れるため --copy で実体を置く。
# Codex は ~/.agents/skills を直接読む(-a codex の実体もそこ)。Pi も標準で同じ場所を読む。
npx -y skills add cloudflare/skills -g -a claude-code -a codex -s '*' --copy -y
npx -y skills add herdrdev/herdr --skill herdr -g -a claude-code -a codex --copy -y
# Runpod 公式スキル(Claude Code はプラグイン経由で持つため Codex / Pi 用に ~/.agents/skills へ)
npx -y skills add runpod/runpod-plugins-official -g -a codex -s '*' --copy -y

# ax (Web取得CLI + スキル)
curl -fsSL https://ax.yusuke.run/install | sh
npx -y skills add yusukebe/ax -g -a claude-code --copy -y

# Context7 (ctx7 CLI + find-docs スキル + ~/.claude/rules/context7.md を生成 / 対話プロンプトあり)
npx -y ctx7 setup

# agmsg (agent messaging)
bash <(curl -fsSL https://raw.githubusercontent.com/fujibee/agmsg/main/setup.sh)
# agmsg は Pi を種類として持たないため、Pi 用のプラグインとスキルを足す(受信は pi/extensions/agmsg.ts)
bash ~/dotfiles/pi/agmsg/install.sh

# Change default shell
# 以前はここで exec zsh していたが、それより後ろが実行されなくなるため最後に置き、再ログインは案内だけにする
[ "$(basename "$SHELL")" = zsh ] || sudo chsh -s "$(which zsh)" "$USER"
echo "完了しました。新しいターミナルを開くか、exec zsh -l で再ログインしてください"

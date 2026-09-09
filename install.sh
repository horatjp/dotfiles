#!/usr/bin/env bash

set -e

# sudo
echo "$(whoami) ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami)

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

  echo -e "[automount]\noptions = \"metadata,umask=22,fmask=11\"" | sudo tee /etc/wsl.conf

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

# Neovim
mkdir -p ~/.config/nvim
ln -sf ~/dotfiles/nvim ~/.config/nvim

# scripts
ln -sf ~/dotfiles/scripts ~/scripts
chmod +x ~/dotfiles/scripts/*

# zsh
mkdir -p ~/.config/zsh
ln -sf ~/dotfiles/zsh/.zshenv ~/.zshenv
# ~/.env は 1Password の op:// 参照を書く個人ファイル(git 管理外)。無ければテンプレから作る
if [ ! -f ~/.env ]; then
  (umask 077; cp ~/dotfiles/zsh/.env.example ~/.env)
  echo "~/.env をテンプレから作成しました。op:// の <vault>/<item> を自分の 1Password に合わせて編集してください"
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
ln -sf ~/dotfiles/tmux/scripts ~/.config/tmux/scripts
# TPM (tmux plugin manager)
if [ ! -d ~/.config/tmux/plugins/tpm ]; then
  mkdir -p ~/.config/tmux/plugins
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi

# herdr
# 設定ディレクトリにはログ・ソケットも作られるため config.toml のみリンクする
mkdir -p ~/.config/herdr
ln -sf ~/dotfiles/herdr/config.toml ~/.config/herdr/config.toml
herdr plugin install smarzban/herdr-file-viewer --yes

# druk
mkdir -p ~/.config/druk
ln -sf ~/dotfiles/druk/config.json ~/.config/druk/config.json

# mise
mkdir -p ~/.config/mise
ln -sf ~/dotfiles/mise/mise.toml ~/.config/mise/config.toml
mise install

# Change default shell
sudo chsh -s "$(which zsh)" $USER

# Relogin shell
exec "$(which zsh)" -l

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
ln -sf ~/dotfiles/claude/agents ~/.claude/agents
ln -sf ~/dotfiles/claude/skills ~/.claude/skills
cp ~/dotfiles/claude/mcp.json ~/.claude.json
curl -fsSL https://claude.ai/install.sh | bash

# Codex
mkdir -p ~/.codex
ln -sf ~/dotfiles/codex/AGENTS.md ~/.codex/AGENTS.md
ln -sf ~/dotfiles/codex/skills ~/.codex/skills
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

# Gemini
mkdir -p ~/.gemini
npm install -g @google/gemini-cli
gemini extensions install https://github.com/gemini-cli-extensions/nanobanana

# GitHub Copilot
mkdir -p ~/.github
ln -sf ~/dotfiles/github/AGENTS.md ~/.github/copilot-instructions.md
ln -sf ~/dotfiles/github/copilot-commit-message-instructions.md ~/.github/copilot-commit-message-instructions.md
ln -sf ~/dotfiles/github/instructions ~/.github/instructions
ln -sf ~/dotfiles/github/prompts ~/.github/prompts
# Note: cp -rL ~/.github .github
npm install -g @github/copilot

# Kimi Code CLI
npm install -g @moonshot-ai/kimi-code
mkdir -p ~/.kimi-code
ln -sf ~/dotfiles/kimi/AGENTS.md ~/.kimi-code/AGENTS.md
# config.toml は CLI が所有・書き換えるため dotfiles では管理せず、
# dotfiles のスキルを読むための extra_skill_dirs のみ冪等に追加する
# （同名スキルは後勝ちなので claude/skills を最後に置いて優先させる）
if ! grep -q '^extra_skill_dirs' ~/.kimi-code/config.toml 2>/dev/null; then
  if [ -f ~/.kimi-code/config.toml ]; then
    printf 'extra_skill_dirs = [ "~/.agents/skills", "~/dotfiles/codex/skills", "~/dotfiles/claude/skills" ]\n\n' | cat - ~/.kimi-code/config.toml > ~/.kimi-code/config.toml.tmp
    mv ~/.kimi-code/config.toml.tmp ~/.kimi-code/config.toml
  else
    printf 'extra_skill_dirs = [ "~/.agents/skills", "~/dotfiles/codex/skills", "~/dotfiles/claude/skills" ]\n' > ~/.kimi-code/config.toml
  fi
  chmod 600 ~/.kimi-code/config.toml
fi
# MCP サーバー定義（認証は ~/.env の RUNPOD_API_KEY を参照するため秘密情報は含まない）
cp ~/dotfiles/kimi/mcp.json ~/.kimi-code/mcp.json

# OpenCode
# グローバル指示は ~/.config/opencode/AGENTS.md(~/.claude/CLAUDE.md より優先)。
# スキルは ~/.claude/skills と ~/.agents/skills を標準で読むため追加設定なし。
# opencode.json は MCP 等をツール側が書き込むため dotfiles では管理しない
mkdir -p ~/.config/opencode
ln -sf ~/dotfiles/opencode/AGENTS.md ~/.config/opencode/AGENTS.md
npm install -g opencode-ai

# Grok CLI (Grok Build)
npm install -g @xai-official/grok

# Cloudflare Wrangler
npm install -g wrangler

# Dev Container CLI
npm install -g @devcontainers/cli

# Third-party skills (gitでは追跡しない / .gitignore 参照)
# --all は「全スキルを全エージェント(約50個の ~/.<agent>/ を生成)へ配布」なので使わない。
# 相対リンクは ~/.claude/skills(symlink)経由だと壊れるため --copy で実体を置く。
# Codex は ~/.agents/skills を直接読む(-a codex の実体もそこ)。Kimi も extra_skill_dirs で同じ場所を読む。
npx -y skills add cloudflare/skills -g -a claude-code -a codex -s '*' --copy -y
npx -y skills add herdrdev/herdr --skill herdr -g -a claude-code --copy -y
# Runpod 公式スキル(Claude Code はプラグイン経由で持つため Codex / Kimi 用に ~/.agents/skills へ)
npx -y skills add runpod/runpod-plugins-official -g -a codex -s '*' --copy -y

# ax (Web取得CLI + スキル)
curl -fsSL https://ax.yusuke.run/install | sh
npx -y skills add yusukebe/ax -g -a claude-code --copy -y

# Context7 (ctx7 CLI + find-docs スキル + ~/.claude/rules/context7.md を生成 / 対話プロンプトあり)
npx -y ctx7 setup

# agmsg (agent messaging)
bash <(curl -fsSL https://raw.githubusercontent.com/fujibee/agmsg/main/setup.sh)

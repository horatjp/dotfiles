#!/usr/bin/env bash

set -e

# sudo
echo "`whoami` ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/`whoami`


# not macOS
if [ "$(uname)" != 'Darwin' ]; then
  # apt
  echo "# apt"
  sudo apt-get update
  sudo apt install -y build-essential curl dnsutils file fonts-noto-cjk git locales nfs-client rsync tree wget whois zip zsh

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
fi

# brew
if [ ! -n "$(which brew)" ]; then

    echo "# brew"
    export NONINTERACTIVE=1
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ "$(uname)" == 'Darwin' ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ "$(uname)" == 'Linux' ]; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

ln -sf ~/dotfiles/homebrew/Brewfile ~/Brewfile
brew bundle install --file=~/Brewfile --verbose

# git
mkdir -p ~/.config/git
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/ignore ~/.config/git/ignore

# Create .gitconfig.local if it doesn't exist
if [ ! -f ~/.gitconfig.local ]; then
    cat > ~/.gitconfig.local <<EOF
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL
EOF
    echo "Created ~/.gitconfig.local - Please edit it to set your name and email"
fi

# vim
ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc

# neovim
if [ -e ~/.config/nvim ] && [ ! -L ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.$(date +%Y%m%d%H%M%S).bak
fi
ln -sf ~/dotfiles/nvim ~/.config/nvim

# zsh
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/zsh/.zshrc.alias ~/.zshrc.alias
ln -sf ~/dotfiles/zsh/.zshrc.history ~/.zshrc.history

# WSL
ln -sf ~/dotfiles/zsh/.zshrc.wsl ~/.zshrc.wsl

# Znap
ln -sf ~/dotfiles/zsh/.zshrc.znap ~/.zshrc.znap

# starship
mkdir -p ~/.config/starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# fzf
ln -sf ~/dotfiles/fzf/.fzf.zsh ~/.fzf.zsh
ln -sf ~/dotfiles/fzf/.zshrc.fzf ~/.zshrc.fzf

# tmux
mkdir -p ~/.config/tmux
ln -sf ~/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
ln -sf ~/dotfiles/tmux/scripts ~/.config/tmux/scripts
# TPM (tmux plugin manager)
if [ ! -d ~/.tmux/plugins/tpm ]; then
  mkdir -p ~/.tmux/plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# sesh
mkdir -p ~/.config/sesh
ln -sf ~/dotfiles/sesh/sesh.toml ~/.config/sesh/sesh.toml

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

# Prettier
echo "# Prettier"
ln -sf ~/dotfiles/prettier/.prettierrc.json ~/.prettierrc.json
ln -sf ~/dotfiles/prettier/.prettierignore ~/.prettierignore

# Claude
mkdir -p ~/.claude
ln -sf ~/dotfiles/ai/AGENTS.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json
ln -sf ~/dotfiles/claude/agents ~/.claude/agents
ln -sf ~/dotfiles/claude/commands ~/.claude/commands
ln -sf ~/dotfiles/claude/skills ~/.claude/skills
cp ~/dotfiles/ai/mcp.json ~/.claude.json
bun install -g @anthropic-ai/claude-code

# Codex
mkdir -p ~/.codex
ln -sf ~/dotfiles/codex/config.toml ~/.codex/config.toml
ln -sf ~/dotfiles/ai/AGENTS.md ~/.codex/AGENTS.md
bun install -g @openai/codex

# Gemini
mkdir -p ~/.gemini
bun install -g @google/gemini-cli
gemini extensions install https://github.com/gemini-cli-extensions/nanobanana
export NANOBANANA_MODEL=gemini-3-pro-image-preview

# GitHub Copilot
mkdir -p ~/.github
ln -sf ~/dotfiles/ai/AGENTS.md ~/.github/copilot-instructions.md
ln -sf ~/dotfiles/github/copilot-commit-message-instructions.md ~/.github/copilot-commit-message-instructions.md
ln -sf ~/dotfiles/github/instructions ~/.github/instructions
ln -sf ~/dotfiles/github/prompts ~/.github/prompts
# Note: cp -rL ~/.github .github

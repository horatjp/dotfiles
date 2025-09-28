#!/usr/bin/env bash

set -e

# sudo
echo "`whoami` ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/`whoami`


# not macOS
if [ "$(uname)" != 'Darwin' ]; then
  # apt
  echo "# apt"
  sudo apt-get update
  sudo apt-get install -y build-essential curl dnsutils file fonts-ipafont git locales nfs-client procps rsync tree wget whois zip

  ## apt Python build
  sudo apt-get install -y libffi-dev libssl-dev libbz2-dev libsqlite3-dev libreadline-dev libncurses5-dev liblzma-dev tk-dev uuid-dev zlib1g-dev

  ## apt GUI
  sudo apt-get install -y libgtk2.0-0 libgtk-3-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 libgbm-dev xauth xvfb fonts-ipafont feh

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
brew bundle install --file=~/Brewfile --no-lock --verbose

# git
mkdir -p ~/.config/git
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/ignore ~/.config/git/ignore

# vim
ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc

# zsh
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/zsh/.zshrc.alias ~/.zshrc.alias
ln -sf ~/dotfiles/zsh/.zshrc.history ~/.zshrc.history

# znap
ln -sf ~/dotfiles/zsh/.zshrc.znap ~/.zshrc.znap

# starship
mkdir -p ~/.config/starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# fzf
ln -sf ~/dotfiles/fzf/.fzf.zsh ~/.fzf.zsh
ln -sf ~/dotfiles/fzf/.zshrc.fzf ~/.zshrc.fzf

# asdf
echo "# asdf"
ln -sf ~/dotfiles/asdf/.asdfrc ~/.asdfrc
ln -sf ~/dotfiles/asdf/.tool-versions ~/.tool-versions

is_dir() {
  path=$1
  [ -d "$path" ]
}

for plugin in $(awk '{print $1}' ~/.tool-versions); do
  if ! is_dir ~/.asdf/plugins/"$plugin"; then
    asdf plugin add "$plugin"
  fi
done

asdf install

while IFS= read -r line; do
  if [ -n "$line" ]; then
    asdf global ${line}
  fi
done < ~/.tool-versions

if [ -n "$(which poetry)" ]; then
  poetry config virtualenvs.in-project true
fi


# Change default shell
sudo chsh -s "$(which zsh)" $USER

# Relogin shell
exec "$(which zsh)" -l


# claude
mkdir -p ~/.claude
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/claude/settings.json ~/.claude/settings.json

if [ ! -n "$(which npm)" ]; then
    npm install -g @anthropic-ai/claude-code
    claude mcp add -s user context7 -- npx -y @upstash/context7-mcp@latest
fi


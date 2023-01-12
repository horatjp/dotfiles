#!/usr/bin/env bash

set -e

# sudo
echo "`whoami` ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/`whoami`

# apt
echo "# apt"
sudo apt update
sudo apt install -y build-essential curl dnsutils file fonts-ipafont git locales nfs-client procps rsync tree wget whois zip zsh

# locale
echo "# locale"
sudo sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=ja_JP.UTF-8

# WSL
if [ -n "$(which explorer.exe)" ]; then

  echo "# WSL setting"
  if [ ! -d ~/dotfiles ]; then
    ln -sf /mnt/c/Users/$(/mnt/c/Windows/System32/cmd.exe /c "<nul set /p=%UserName%" 2>/dev/null)/dotfiles ~/dotfiles
  fi

  if [ ! -d ~/.ssh ]; then
    ln -sf /mnt/c/Users/$(/mnt/c/Windows/System32/cmd.exe /c "<nul set /p=%UserName%" 2>/dev/null)/.ssh ~/.ssh
  fi

  sudo ln -sf ~/dotfiles/wsl/wsl.conf /etc/wsl.conf
fi

# dotfiles
if [ ! -d ~/dotfiles ]; then
  echo "# clone dotfiles"
  git clone https://github.com/horatjp/dotfiles ~/dotfiles
fi

# brew
echo "# brew"
if [ -z "$(command -v brew)" ]; then

  export NONINTERACTIVE=1
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # add to profile
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
ln -sf ~/dotfiles/homebrew/Brewfile ~/Brewfile
brew bundle install --file=~/Brewfile --no-lock --verbose

# git
mkdir -p ~/.config/git
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/ignore ~/.config/git/ignore

# vim
ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc

# bash
#ln -sf ~/dotfiles/bash/bashrc ~/.bashrc

# zsh
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc

# starship
mkdir -p ~/.config/starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

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
     COMMAND="asdf global ${line}"
     echo $COMMAND
     eval $COMMAND
  fi
done < ~/.tool-versions


# Change default shell
sudo chsh -s "$(which zsh)" $USER

# Relogin shell
#exec "$(which zsh)" -l
zsh ~/.zshrc

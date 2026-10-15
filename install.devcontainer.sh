#!/usr/bin/env bash
set -e

sudo apt-get update
sudo apt-get install -y curl fzf jq neovim vim zip zsh
# eza は新しめのディストリにしか無い。無くても .zshrc.alias は元の ls のまま動くので失敗は無視する
sudo apt-get install -y eza || true

# vim
ln -sf ~/dotfiles/vim/vimrc ~/.vimrc

# neovim
mkdir -p ~/.config
rm -rf ~/.config/nvim
ln -sfn ~/dotfiles/nvim ~/.config/nvim

# zsh
ln -sf ~/dotfiles/zsh/.zshrc.devcontainer ~/.zshrc
ln -sf ~/dotfiles/zsh/.zshrc.alias ~/.zshrc.alias
ln -sf ~/dotfiles/zsh/.zshrc.history ~/.zshrc.history

# znap
ln -sf ~/dotfiles/zsh/.zshrc.znap ~/.zshrc.znap

# starship
curl -sS https://starship.rs/install.sh | sh -s -- --yes
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# fzf
ln -sf ~/dotfiles/zsh/.zshrc.fzf ~/.zshrc.fzf

# Change default shell
sudo chsh -s "$(which zsh)" "$USER"

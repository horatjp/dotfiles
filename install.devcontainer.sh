#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y curl exa fzf jq vim zip zsh

# vim
ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc

# zsh
ln -sf ~/dotfiles/zsh/.zshrc.devcontainer ~/.zshrc
ln -sf ~/dotfiles/zsh/.zshrc.alias ~/.zshrc.alias
ln -sf ~/dotfiles/zsh/.zshrc.history ~/.zshrc.history

# znap
ln -sf ~/dotfiles/zsh/.zshrc.znap ~/.zshrc.znap

# starship
curl -sS https://starship.rs/install.sh | sh -s -- --yes
mkdir -p ~/.config/starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# fzf
ln -sf ~/dotfiles/fzf/.zshrc.fzf ~/.zshrc.fzf

# Change default shell
sudo chsh -s "$(which zsh)" $USER

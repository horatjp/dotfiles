#!/usr/bin/env zsh

# starship
curl -sS https://starship.rs/install.sh | sh -s -- --yes
mkdir -p ~/.config/starship
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

# vim
ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc

# zsh
ln -sf ~/dotfiles/zsh/.zshrc-devcontainer ~/.zshrc

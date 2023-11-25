#!/usr/bin/env bash

set -e

sudo -v

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Finder
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show full path
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show hard drives on desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

# Disable animations
defaults write com.apple.finder DisableAllAnimations -bool true


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Dock
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Automatically hide the Dock
defaults write com.apple.dock autohide -bool true

# Change the speed of hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Change the size of icons in the Dock
defaults write com.apple.dock tilesize -int 48

# Disable application launch animation
defaults write com.apple.dock launchanim -bool false

# Set the minimize effect to "scale"
defaults write com.apple.dock mineffect -string "scale"

# Disable automatic space switching based on most recent use
defaults write com.apple.dock mru-spaces -bool "false"

# Hide recently opened applications
defaults write com.apple.dock show-recents -bool false

# Remove all apps from the Dock
defaults write com.apple.dock persistent-apps -array


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# System settings
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Turn off the startup sound of the Mac
sudo nvram StartupMute=%01

# Set key repeat speed
defaults write -g KeyRepeat -float 1.8
defaults write -g InitialKeyRepeat -int 20

# Change key press and hold behavior
defaults write -g ApplePressAndHoldEnabled -bool false

# Don't capitalize the first letter automatically
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Change trackpad speed
defaults write -g com.apple.mouse.scaling 2

# Change scroll speed
defaults write -g com.apple.scrollwheel.scaling 4

# Disable natural scrolling
defaults write -g com.apple.swipescrolldirection -bool false

# Speed up window resizing and moving
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Don't create .DS_Store files on network drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Don't create .DS_Store files on USB drives
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Don't add shadow to screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Set screenshot save location
mkdir -p ~/Pictures/Screenshots
defaults write com.apple.screencapture location -string "~/Pictures/Screenshots"

# Dark mode
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# Rosetta 2
/usr/sbin/softwareupdate --install-rosetta --agree-to-license


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Homebrew
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
export NONINTERACTIVE=1
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)" > /dev/null


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# dotfiles
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ ! -d ~/dotfiles ]; then
  echo "# clone dotfiles"
  git clone https://github.com/horatjp/dotfiles ~/dotfiles
fi


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Kitty
brew install --cask kitty

# Visual Studio Code
brew install --cask visual-studio-code

# OrbStack
brew install --cask orbstack

# XQuartz
brew install --cask xquartz

# Raycast
brew install --cask raycast

# Google Chrome
brew install --cask google-chrome

# DBeaver
brew install --cask dbeaver-community


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# font
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
brew tap homebrew/cask-fonts
brew install font-hackgen-nerd


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Kitty
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mkdir -p ~/.config/kitty
ln -sf ~/dotfiles/kitty/kitty.conf ~/.config/kitty/kitty.conf

# Kitty onehalf theme
curl -o ~/.config/kitty/onehalf-dark.conf https://raw.githubusercontent.com/sonph/onehalf/master/kitty/onehalf-dark.conf


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Visual Studio Code
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mkdir -p ~/Library/Application\ Support/Code/User/
ln -sf ~/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

# extension
vscodeExtensionsPath="$HOME/dotfiles/vscode/extensions"
if [[ -f $vscodeExtensionsPath ]]; then
    extensions=$(cat $vscodeExtensionsPath)
    for extension in $extensions; do
        if [[ -n $extension ]]; then
            code --install-extension $extension
        fi
    done
fi

# locale
echo '{"locale": "ja"}' > ~/.vscode/argv.json


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Xquartz
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow connections from network clients
defaults write org.xquartz.X11 nolisten_tcp -bool false

# Prevent xterm from launching at startup
defaults write org.xquartz.X11 app_to_run ""

# Enable OpenGL
defaults write org.xquartz.X11 enable_iglx -bool true


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# END
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo -e "\nReboot the computer: sudo reboot"

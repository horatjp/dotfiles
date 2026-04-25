#!/usr/bin/env bash

set -e

sudo -v


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# sudo no password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo "$(whoami) ALL=(root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami)


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Computer name
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf "コンピュータ名を入力してください [mac-mini-m2]: "
read -r computer_name
computer_name="${computer_name:-mac-mini-m2}"

sudo scutil --set ComputerName "$computer_name"
sudo scutil --set HostName "$computer_name"
sudo scutil --set LocalHostName "$computer_name"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$computer_name"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Finder
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# すべての拡張子を表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# 隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool true

# パスバーを表示
defaults write com.apple.finder ShowPathbar -bool true

# ステータスバーを表示
defaults write com.apple.finder ShowStatusBar -bool true

# タイトルバーにフルパスを表示
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Finder のデフォルト表示をリスト表示に
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# フォルダを先に表示
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# デスクトップに接続中のサーバを表示
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

# 新規ウィンドウでホームフォルダを開く
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# 検索のデフォルトを現在のフォルダ内に
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# ゴミ箱を空にする前の確認ダイアログを無効
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# アニメーションを無効
defaults write com.apple.finder DisableAllAnimations -bool true

# Finderの操作音を無効
defaults write com.apple.finder FinderSounds -bool false


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Dock
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 自動で隠す
defaults write com.apple.dock autohide -bool true

# ホバー後の表示遅延をゼロ
defaults write com.apple.dock autohide-delay -float 0

# 表示アニメーション時間
defaults write com.apple.dock autohide-time-modifier -float 0.3

# アイコンのサイズを変更
defaults write com.apple.dock tilesize -int 48

# アプリケーションの起動中アニメーションを無効
defaults write com.apple.dock launchanim -bool false

# アプリケーション最小化アニメーションを設定
defaults write com.apple.dock mineffect -string "scale"

# 最近使用したスペースに基づく自動的なスペース切り替えを無効
defaults write com.apple.dock mru-spaces -bool false

# 最近起動したアプリを非表示
defaults write com.apple.dock show-recents -bool false

# アプリ削除（Dock をまっさら）
defaults write com.apple.dock persistent-apps -array


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# System settings
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 起動音を OFF
sudo nvram StartupMute=%01

# キーリピート速度設定
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# 長押し時のアクセント記号入力無効
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# 最初の文字を大文字にしない
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# 自動修正を無効
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# "--" が "—" に自動変換されるのを無効
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# スマートクォートを無効
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# スペース2回で "." に変換されるのを無効
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# テキスト補完のポップアップを無効
defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false

# ライブ変換を無効
defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false

# 全角数字を入力を無効
defaults write com.apple.inputmethod.Kotoeri JIMPrefFullWidthNumeralCharactersKey -bool false

# 入力ソースを自動的に切り替えを無効化
defaults write com.apple.HIToolbox AppleGlobalTextInputProperties -dict-add TextInputGlobalPropertyPerContextInput -bool false

# マウス軌跡速度
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.7

# スクロール速度
defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0

# ナチュラルスクロールを無効
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# ウィンドウのリサイズ・移動を高速化
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# ウィンドウを開く際のアニメーションを無効
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# デスクトップをクリックしてデスクトップを表示する機能を無効
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# ネットワークドライブに .DS_Store を作成しない
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# USB ドライブに .DS_Store を作成しない
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# カレントディレクトリに .DS_Store を作成しない
defaults write com.apple.desktopservices DSDontWriteLocalStores -bool true

# スクリーンショットに影をつけない
defaults write com.apple.screencapture disable-shadow -bool true

# スクリーンショットファイル名変更
defaults write com.apple.screencapture name ""

# スクリーンショット保存場所
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# スクリーンショットのデフォルト保存先をクリップボードに変更
defaults write com.apple.screencapture target clipboard

# Spotlightのショートカットを無効化
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/></dict>'

# ダークモード
defaults write NSGlobalDomain AppleInterfaceStyle Dark

# 効果音OFF（UI全般）
defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0

# 音量変更時のポコッ音を無効
defaults write NSGlobalDomain com.apple.sound.beep.feedback -integer 0

# アラート音の音量をゼロに
defaults write NSGlobalDomain com.apple.sound.beep.volume -float 0.0

# アンチエイリアスを無効化
defaults write NSGlobalDomain CGFontRenderingFontSmoothingDisabled -bool true

# コンピュータのスリープを無効
sudo systemsetup -setcomputersleep Never

# ディスプレイのスリープまでの時間（分）
sudo pmset -a displaysleep 30


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
# WezTerm
brew install --cask wezterm

# Visual Studio Code
brew install --cask visual-studio-code

# OrbStack
brew install --cask orbstack

# XQuartz
brew install --cask xquartz

# Raycast
brew install --cask raycast

# Cyberduck
brew install --cask cyberduck

# Karabiner-Elements
brew install --cask karabiner-elements

# CleanShot X
brew install --cask cleanshot

# 1password
brew install --cask 1password

# Claude
brew install --cask claude

# Codex
brew install --cask codex

# Google Chrome
brew install --cask google-chrome

# Google Drive
brew install --cask google-drive

# Mozilla Thunderbird
brew install --cask thunderbird

# DBeaver
brew install --cask dbeaver-community

# SmoothCSV
brew install --cask smoothcsv

# KeyCastr
brew install --cask keycastr

# The Unarchiver
brew install --cask the-unarchiver

# GIMP
brew install --cask gimp

# Inkscape
brew install --cask inkscape

# FontBase
brew install --cask fontbase

# Slack
brew install --cask slack

# IINA
brew install --cask iina

# Mp3tag
brew install --cask mp3tag

# Steam
brew install --cask steam

# YACReader
brew install --cask yacreader

# Brave
brew install --cask brave-browser

# Mac App Store
brew install mas

# LINE
mas install 539883307

# Amazon Kindle
mas install 302584613

# Badgeify
mas install 6738112492


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# font
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
brew install font-hackgen-nerd


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# WezTerm
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ln -sf ~/dotfiles/wezterm/.wezterm.lua ~/.wezterm.lua


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
# ネットワーク・クライアントからの接続を許可する ON
defaults write org.xquartz.X11 nolisten_tcp -bool false

# 起動時に xterm が起動しないようにする
defaults write org.xquartz.X11 app_to_run ""

# OpenGL を有効にする
defaults write org.xquartz.X11 enable_iglx -bool true


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Rosetta 2
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/usr/sbin/softwareupdate --install-rosetta --agree-to-license


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# END
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo -e "\nReboot the computer: sudo reboot"

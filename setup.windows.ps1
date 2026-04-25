# Administrator check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) {
    Write-Output "Please run with administrator privileges."
    pause
    exit;
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PowerShell settings
Write-Output "# PowerShell settings"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -scope CurrentUser


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# dotfiles
Write-Output "# dotfiles"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
${DOTFILES}="${HOME}\dotfiles"

if(!(where.exe git)) {
    Write-Output "# Git"
    winget install Git.Git --silent --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

if(!(Test-Path -Path ${DOTFILES} )) {
    git config --global core.autocrlf input
    git clone https://github.com/horatjp/dotfiles ${DOTFILES}
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Windows settings
Write-Output "# Windows settings"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

## ========== エクスプローラー表示設定 ==========

# "登録されている拡張子は表示しない" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "HideFileExt" -Value 0

# "隠しファイル、隠しフォルダ、および隠しドライブを表示する" ON
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Hidden" -Value 1

# "自動的に現在のフォルダーまで展開する" ON
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "NavPaneExpandToCurrentFolder" -Value 1

# エクスプローラーの起動時「PC」を表示
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "LaunchTo" -Value 1

# フルパスをタイトルバーに表示
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState -Name "FullPath" -Value 1

# コンパクトビュー ON
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "UseCompactMode" -Value 1

## ========== エクスプローラーポップアップ設定 ==========

# "フォルダとデスクトップの項目説明ポップアップ" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowInfoTip" -Value 0

# "フォルダヒントのサイズ情報" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "FolderContentsInfoTip" -Value 0

## ========== エクスプローラー表示内容設定 ==========

# "最近使用したフォルダの表示" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer -Name "ShowFrequent" -Value 0

# "最近使用したファイルの表示" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer -Name "ShowRecent" -Value 0

# "Office.comのファイルの表示" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer -Name "ShowCloudFilesInQuickAccess" -Value 0

# "空のドライブは表示しない" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "HideDrivesWithNoMedia" -Value 0

# "同期プロバイダー通知" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowSyncProviderNotifications" -Value 0

## ========== タスクバー設定 ==========

# タスクバーの検索アイコンを非表示
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name "SearchboxTaskbarMode" -Value 0

# タスクバーのタスクビューボタンを非表示
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowTaskViewButton" -Value 0

# タスクバー・検索ボックスWeb検索非表示
New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
New-ItemProperty HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer -Name "DisableSearchBoxSuggestions" -Value 1 -Force | Out-Null

# タスクバーでアニメーション効果を無効化
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarAnimations" -Value 0

## ========== スタート画面設定 ==========

# 最近追加したアプリを表示しない
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Start -Name "ShowRecentList" -Value 0

# よく使うアプリを表示しない
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Start -Name "ShowFrequentList" -Value 0

# 最近開いた項目をスタート、ジャンプリスト、ファイルエクスプローラーに表示しない
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Start_TrackDocs" -Value 0

# ヒント、ショートカット、新しいアプリなどのおすすめを表示しない
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Start_IrisRecommendations" -Value 0

# スタート画面にアカウント関連の通知を表示しない
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Start_AccountNotifications" -Value 0

## ========== その他のシステム設定 ==========

# クリップボード履歴オン
Set-ItemProperty HKCU:\Software\Microsoft\Clipboard -Name "EnableClipboardHistory" -Value 1

# ダークモード
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name "AppsUseLightTheme" -Value 0

# "高速スタートアップを有効にする" チェックOFF
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0

## ========== 設定の反映 ==========

# エクスプローラーを再起動して設定を反映
Stop-Process -Name explorer -Force


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uninstall unnecessary apps
Write-Output "# Uninstall unnecessary apps"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
winget uninstall "Windows Web Experience Pack"
winget uninstall Microsoft.OneDrive
winget uninstall "Power Automate"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# winget
Write-Output "# winget"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
winget install Adobe.Acrobat.Reader.64-bit
winget install Amazon.Kindle
winget install Apple.iTunes
winget install AutoHotkey.AutoHotkey
winget install DBeaver.DBeaver.Community
winget install Docker.DockerDesktop
winget install GIMP.GIMP.3
winget install Git.Git
winget install Google.Chrome
winget install Google.GoogleDrive
winget install Gyan.FFmpeg
winget install Inkscape.Inkscape
winget install Levitsky.FontBase
winget install LINE.LINE
winget install Microsoft.VisualStudioCode
winget install Mozilla.Thunderbird
winget install Mp3tag.Mp3tag
winget install Neovim.Neovim
winget install NickeManarin.ScreenToGif
winget install RARLab.WinRAR
winget install Raycast.Raycast
winget install SlackTechnologies.Slack
winget install 7zip.7zip
winget install wez.wezterm
winget install WinSCP.WinSCP

winget install CoreyButler.NVMforWindows

# Update the environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# sudo 有効
sudo config --enable normal


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Rlogin
Write-Output "# Rlogin"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Invoke-WebRequest -Uri https://github.com/kmiya-culti/RLogin/releases/download/2.31.0/rlogin_x64.zip -OutFile rlogin_x64.zip -UseBasicParsing
Expand-Archive -Path rlogin_x64.zip -DestinationPath ${HOME}\RLogin
rm rlogin_x64.zip


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Font HackGen
Write-Output "# Font HackGen"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Invoke-WebRequest -Uri https://github.com/yuru7/HackGen/releases/download/v2.10.0/HackGen_NF_v2.10.0.zip -OutFile HackGen_NF.zip -UseBasicParsing
Expand-Archive -Path HackGen_NF.zip -DestinationPath .
$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
dir HackGen_NF_v2.10.0/*.ttf | %{ $fonts.CopyHere($_.fullname) }
rm HackGen_NF* -Recurse


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# WSL
Write-Output "# WSL"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sudo wsl --install Debian
New-Item -Force -Type SymbolicLink ${HOME}\.wslconfig -Value ${DOTFILES}\wsl\.wslconfig


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ssh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mkdir ${HOME}/.ssh


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# WezTerm
Write-Output "# WezTerm"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
New-Item -Force -Type SymbolicLink ${HOME}\.wezterm.lua -Value ${DOTFILES}\wezterm\.wezterm.lua


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Windows Terminal
Write-Output "# Windows Terminal"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$settings = if (Test-Path $settingsPath) { Get-Content $settingsPath | ConvertFrom-Json } else { @{} }

$debianProfile = $settings.profiles.list | Where-Object { $_.name -eq "Debian" }
if ($debianProfile) {
    $settings.defaultProfile = $debianProfile.guid
} else {
    Write-Output "Warning: Debian profile not found. Set default profile manually after WSL setup."
}

$settings.profiles.defaults = @{
    colorScheme = "One Half Dark"
    font = @{
        face = "HackGen Console NF"
        size = 11
    }
    opacity = 90
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Visual Studio Code
Write-Output "# Visual Studio Code"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
New-Item -Force -Type SymbolicLink $env:APPDATA\Code\User\settings.json -Value ${DOTFILES}\vscode\settings.json

# extension
$filePath = "${DOTFILES}\vscode\extensions"
if ((Test-Path -Path $filePath)) {
    $extensions = Get-Content -Path $filePath
    foreach ($extension in $extensions) {
        if (![string]::IsNullOrWhiteSpace($extension)) {
            Write-Output "Installing $extension..."
            code --install-extension $extension
        }
    }
}

# open
code
Start-Sleep -Seconds 5

# locale
$vscodeArgvPath = "$env:USERPROFILE\.vscode\argv.json"
$content = Get-Content $vscodeArgvPath -Raw
$content = $content -replace '(?m)^\s*//.*$'
$json = $content | ConvertFrom-Json
$json | Add-Member -Type NoteProperty -Name "locale" -Value "ja"
$json | ConvertTo-Json | Set-Content $vscodeArgvPath


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Neovim alias
Write-Output "# Neovim alias"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
$profileContent = "`nSet-Alias vi nvim`nSet-Alias vim nvim"
if (!(Test-Path -Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null
}
Add-Content -Path $PROFILE -Value $profileContent
. $PROFILE


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# AutoHotkey startup
Write-Output "# AutoHotkey startup"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
$StartupFolder = [Environment]::GetFolderPath("Startup")
$AHKScriptPath = "${DOTFILES}\AutoHotkey\AutoHotkey.ahk"

if (Test-Path -Path $AHKScriptPath) {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut("$StartupFolder\AutoHotkey.lnk")
    $Shortcut.TargetPath = $AHKScriptPath
    $Shortcut.WorkingDirectory = "${DOTFILES}\AutoHotkey"
    $Shortcut.Save()
    Write-Output "Created startup shortcut for AutoHotkey"
} else {
    Write-Output "Warning: AutoHotkey script not found at $AHKScriptPath"
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# END
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo "`nReboot the computer: Restart-Computer"
pause

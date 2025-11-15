# Administrator check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) {
    Write-Output "Please run with administrator privileges."
    pause
    exit;
}


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
# "Hide extensions for known file types" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "HideFileExt" -Value 0

# "Show hidden files, folders, and drives" ON
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "Hidden" -Value 1

# "Automatically expand to the current folder" ON
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "NavPaneExpandToCurrentFolder" -Value 1

# Display "This PC" at startup of Explorer
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "LaunchTo" -Value 1

# "Show recently used folders" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer -name "ShowFrequent" -Value 0

# "Show recently used files" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer -name "ShowRecent" -Value 0

# "Item description popups on folders and desktop" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "ShowInfoTip" -Value 0

# "Size information in folder tips" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "FolderContentsInfoTip" -Value 0

# "Do not show empty drives" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "HideDrivesWithNoMedia" -Value 0

# "Sync provider notifications" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "ShowSyncProviderNotifications" -Value 0

# "Show files from Office.com" OFF
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer -name "ShowCloudFilesInQuickAccess" -Value 0

# Compact view ON
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "UseCompactMode" -Value 1

# Taskbar widgets hidden
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name "TaskbarDa" -Value 0

# Hide web search in taskbar search box
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name "DisableSearchBoxSuggestions" -Value 1

# Dark mode
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name "AppsUseLightTheme" -Value 0

# "HiberbootEnabled" OFF
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# winget
Write-Output "# winget"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
winget install Amazon.Kindle
winget install Apple.iTunes
winget install dbeaver.dbeaver
winget install Docker.DockerDesktop
winget install gerardog.gsudo
winget install GIMP.GIMP
winget install Git.Git
winget install GNU.Nano
winget install Google.Chrome
winget install Google.ChromeRemoteDesktop
winget install Google.Drive
winget install Inkscape.Inkscape
winget install Levitsky.FontBase
winget install LINE.LINE
winget install Microsoft.PowerToys
winget install Microsoft.VisualStudioCode
winget install Mozilla.Thunderbird
winget install Mp3tag.Mp3tag
winget install NickeManarin.ScreenToGif
winget install Obsidian.Obsidian
winget install RARLab.WinRAR
winget install SlackTechnologies.Slack
winget install WinSCP.WinSCP
winget install CoreyButler.NVMforWindows

# Update the environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Rlogin
Write-Output "# Rlogin"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Invoke-WebRequest -Uri https://github.com/kmiya-culti/RLogin/files/13221806/rlogin_x64.zip -OutFile rlogin_x64.zip -UseBasicParsing
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
wsl --install --distribution Debian
New-Item -Force -Type SymbolicLink ${HOME}\.wslconfig -Value ${DOTFILES}\wsl\.wslconfig


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ssh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
mkdir ${HOME}/.ssh


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Windows Terminal
Write-Output "# Windows Terminal"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
New-Item -Force -Type SymbolicLink $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Value ${DOTFILES}\windowsterminal\settings.json


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
# Node.js via NVM
Write-Output "# Node.js via NVM"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
nvm install lts
nvm use lts


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# END
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo "`nReboot the computer: Restart-Computer"
pause

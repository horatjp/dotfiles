# dotfiles


## Install

### Windows

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/horatjp/dotfiles/main/setup.windows.ps1')
```

### macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/horatjp/dotfiles/main/setup.macos.sh)"
```

### Windows(WSL)/macOS Shell

#### Windows(WSL)

```bash
/bin/bash -c /mnt/c/Users/$(/mnt/c/Windows/System32/cmd.exe /c "<nul set /p=%UserName%" 2>/dev/null)/dotfiles/install.sh
```

#### macOS

```bash
/bin/bash -c ~/dotfiles/install.sh
```

#### Other

install.sh は ~/dotfiles にあるファイルをリンクするため、先にクローンする。

```bash
git clone https://github.com/horatjp/dotfiles ~/dotfiles && bash ~/dotfiles/install.sh
```


## Components

### Windows

* Windows settings
* Windows Terminal
* WSL2
* Docker Desktop
* Visual Studio Code
* Font HackGen

### macOS

* macOS settings
* WezTerm
* Orbstack
* Visual Studio Code
* Font HackGen
* Xquartz

### Windows(WSL)/macOS Shell

* Homebrew
* Zsh
* Znap!
* FZF
* Starship
* mise
* Tmux
* Herdr
* Neovim (LazyVim)


## Visual Studio Code devcontainer dotfiles 

`.devcontainer/devcontainer.json`
```json:.devcontainer/devcontainer.json
...
    "customizations": {
        "vscode": {
            "settings": {
                "dotfiles.repository": "horatjp/dotfiles",
                "dotfiles.targetPath": "~/dotfiles",
                "dotfiles.installCommand": "install.devcontainer.sh"
            }
        }
    },
...
```

`.vscode/settings.json`
```json:.vscode/settings.json
{
    "dotfiles.repository": "horatjp/dotfiles",
    "dotfiles.targetPath": "~/dotfiles",
    "dotfiles.installCommand": "install.devcontainer.sh"
}
```

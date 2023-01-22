# dotfiles

## Install

### Windows

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/horatjp/dotfiles/main/setup.ps1')
```

### Linux(Debian, Ubuntu, WSL)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/horatjp/dotfiles/main/setup.sh)"
```


## Components

### Windows

* Windows settings
* Git
* Windows Terminal
* WSL2
* Docker Desktop
* VS Code
* Font HackGen

### Linux(Debian, Ubuntu, WSL)

* zsh
* homebrew
* fzf
* starship
* asdf


## devcontainer dotfiles 

```
{
  "dotfiles.repository": "horatjp/dotfiles",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "~/dotfiles/setup-devcontainer.sh",
}
```

> ```
> chmod 755 setup-devcontainer.sh
> ```

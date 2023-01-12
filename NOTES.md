
## Backup

### Windows


#### Windows Terminal

```powershell
# PowerShell
PS> cp $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json $HOME/dotfiles/windowsterminal/settings.json
```

#### VS Code

```powershell
# PowerShell
PS> code --list-extensions > $HOME/dotfiles/vscode/extensions
```

```powershell
# PowerShell
PS> cp $env:APPDATA\Code\User\settings.json $HOME/dotfiles/vscode/settings.json
```

#### winget

```powershell
# PowerShell
PS> winget export -o $HOME/dotfiles/winget/packages.json
```

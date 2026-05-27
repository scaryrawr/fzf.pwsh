# fzf.pwsh

PowerShell widgets and keybindings for [fzf](https://github.com/junegunn/fzf), based on [fzf.zsh](https://github.com/scaryrawr/fzf.zsh).

## Prerequisites

- [PowerShell](https://github.com/PowerShell/PowerShell) 5.1+
- [fzf](https://github.com/junegunn/fzf) (required; import shows a warning and stops loading the module if missing)
- [PSReadLine](https://github.com/PowerShell/PSReadLine) (required for keybindings)

## Optional dependencies

- [python](https://www.python.org/) or `python3` (preferred preview backend)
- [fd](https://github.com/sharkdp/fd) (faster file/directory discovery)
- [bat](https://github.com/sharkdp/bat) (better file previews)
- [eza](https://github.com/eza-community/eza) or [exa](https://github.com/ogham/exa) (directory previews)
- [chafa](https://github.com/hpjansson/chafa) (image previews)
- `file` command (better file type detection in previews)
- [delta](https://github.com/dandavison/delta) (diff formatting for git previews)
- `yarn` / `npm` / `cargo` (better package workspace discovery for the package widget)

## Installation

### PowerShell Gallery

```powershell
Install-Module -Name fzf.pwsh -Scope CurrentUser
```

### Manual

Clone to a module path, then import:

```powershell
git clone https://github.com/scaryrawr/fzf.pwsh.git "<your-module-path>/fzf.pwsh"
Import-Module fzf.pwsh
```

## Usage

On import, `Set-PsFzfKeyBindings` is called automatically.

## Default keybindings

- **Ctrl+T**: insert selected file path(s)
- **Ctrl+R**: reverse history search
- **Ctrl+S**: forward history search
- **Alt+C**: fuzzy-select directory and run `cd`
- **Alt+G**: browse git log and insert commit hash
- **Alt+S**: browse `git status` and insert selected file path(s)
- **Alt+V**: insert selected PowerShell variable name
- **Alt+P**: select package/workspace names from local `package.json`/`Cargo.toml` data

`Invoke-FzfGitBlameWidget` is exported but **not** bound to a key by default.

## Exported functions

- `Set-PsFzfKeyBindings`
- `Invoke-FzfFileWidget`
- `Invoke-FzfHistoryWidget`
- `Invoke-FzfCdWidget`
- `Invoke-FzfGitLogWidget`
- `Invoke-FzfGitStatusWidget`
- `Invoke-FzfVariablesWidget`
- `Invoke-FzfPackageWidget`
- `Invoke-FzfGitBlameWidget`
- `Find-FzfFiles`

## Configuration

Set variables before importing the module if you want to override defaults:

```powershell
$env:FZF_DEFAULT_OPTS = "--ansi --cycle --layout=reverse --border --height=90% --preview-window=wrap"
$env:FZF_PREVIEW_CMD = "<custom-preview-command>"
$env:FZF_GIT_BLAME_PREVIEW_CMD = "<custom-git-blame-preview-command>"
$env:FZF_GIT_COMMIT_PREVIEW_CMD = "<custom-git-commit-preview-command>"
$env:FZF_GIT_LOG_PREVIEW_CMD = "<custom-git-log-preview-command>"
$env:FZF_GIT_STATUS_PREVIEW_CMD = "<custom-git-status-preview-command>"
$env:FZF_PACKAGE_PREVIEW_CMD = "<custom-package-preview-command>"
$env:FZF_DIFF_PREVIEW_CMD = "<custom-diff-preview-command>"
```

If unset, the module picks defaults and prefers Python preview scripts when available; otherwise it uses PowerShell preview scripts.

## Verbose diagnostics

Widget commands support `-Verbose`:

```powershell
Invoke-FzfGitStatusWidget -Verbose
```

or enable verbose output for the session:

```powershell
$VerbosePreference = "Continue"
```

or during import:

```powershell
Import-Module fzf.pwsh -Verbose
```

## Credits

PowerShell port of [fzf.zsh](https://github.com/scaryrawr/fzf.zsh), mostly implemented with GitHub Copilot.

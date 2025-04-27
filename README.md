# fzf.pwsh

A PowerShell module that integrates [fzf](https://github.com/junegunn/fzf) (command-line fuzzy finder) with PowerShell to enhance your terminal experience. This is a port of the [fzf.zsh](https://github.com/scaryrawr/fzf.zsh) plugin.

## Prerequisites

- [PowerShell](https://github.com/PowerShell/PowerShell) 5.1 or higher
- [fzf](https://github.com/junegunn/fzf) command-line fuzzy finder
- [PSReadLine](https://github.com/PowerShell/PSReadLine) module

## Optional Dependencies

- [bat](https://github.com/sharkdp/bat) - A cat clone with syntax highlighting (enhances previews)
- [fd](https://github.com/sharkdp/fd) - A simple, fast alternative to `find`
- [eza](https://github.com/eza-community/eza) or [exa](https://github.com/ogham/exa) - Modern replacement for `ls`
- [delta](https://github.com/dandavison/delta) - Syntax-highlighting pager for git
- [chafa](https://github.com/hpjansson/chafa) - Terminal graphics for image previews

## Installation

### Manual Installation

1. Clone this repository:

   ```powershell
   git clone https://github.com/scaryrawr/fzf.pwsh.git "$env:USERPROFILE\Documents\PowerShell\Modules\fzf.pwsh"
   ```

2. Import the module in your PowerShell profile:

   ```powershell
   Import-Module fzf.pwsh
   ```

## Features

This module provides several widget functions that can be accessed through keyboard shortcuts:

- **Ctrl+T** / **Alt+Ctrl+F**: File search
- **Ctrl+R** / **Up Arrow**: Command history search
- **Alt+C**: Change directory
- **Alt+Ctrl+L**: Git log
- **Alt+Ctrl+T** / **Alt+Ctrl+S**: Git status
- **Alt+V**: Environment variables
- **Alt+Ctrl+B**: Git blame

## Configuration

You can customize the module by setting the following environment variables:

```powershell
$env:FZF_DEFAULT_OPTS = "--ansi"  # Default options for fzf
```

## Custom Preview Commands

You can customize the preview commands:

```powershell
$env:FZF_PREVIEW_CMD = "<custom-preview-command>"
$env:FZF_GIT_BLAME_PREVIEW_CMD = "<custom-git-blame-preview-command>"
$env:FZF_GIT_COMMIT_PREVIEW_CMD = "<custom-git-commit-preview-command>"
$env:FZF_GIT_LOG_PREVIEW_CMD = "<custom-git-log-preview-command>"
$env:FZF_GIT_STATUS_PREVIEW_CMD = "<custom-git-status-preview-command>"
$env:FZF_PACKAGE_PREVIEW_CMD = "<custom-package-preview-command>"
$env:FZF_DIFF_PREVIEW_CMD = "<custom-diff-preview-command>"
```

## Credits

This is a PowerShell port of the [fzf.zsh](https://github.com/scaryrawr/fzf.zsh) plugin mostly done by GitHub Copilot.

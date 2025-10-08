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
- [python](https://www.python.org/) - Improve performance of previews

## Installation

### PowerShell Gallery (Recommended)

```powershell
Install-Module -Name fzf.pwsh -Scope CurrentUser
```

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

- **Ctrl+T**: File search - Find files in the current directory tree
- **Ctrl+R**: Command history reverse search - Search backwards through command history
- **Ctrl+S**: Command history forward search - Search forwards through command history
- **Alt+C**: Change directory - Fuzzy find and change to a directory
- **Alt+G**: Git log - Browse git commit history
- **Alt+S**: Git status - View and select git modified files
- **Alt+V**: Environment variables - Browse and search environment variables
- **Alt+P**: Package search - Search for packages (winget on Windows, Homebrew on macOS, apt on Linux)

## Configuration

You can customize the module by setting environment variables in your PowerShell profile:

```powershell
# Default fzf options (set before importing the module or customize as needed)
$env:FZF_DEFAULT_OPTS = "--ansi --cycle --layout=reverse --border --height=90% --preview-window=wrap"
```

The module sets sensible defaults for `FZF_DEFAULT_OPTS` if not already configured.

## Custom Preview Commands

You can customize the preview commands:

```powershell
# File preview (used by Ctrl+T, Alt+C)
$env:FZF_PREVIEW_CMD = "<custom-preview-command>"

# Git blame preview (used by Alt+B - not currently bound)
$env:FZF_GIT_BLAME_PREVIEW_CMD = "<custom-git-blame-preview-command>"

# Git commit preview (used by Alt+G git log)
$env:FZF_GIT_COMMIT_PREVIEW_CMD = "<custom-git-commit-preview-command>"

# Git log preview (used by Alt+G)
$env:FZF_GIT_LOG_PREVIEW_CMD = "<custom-git-log-preview-command>"

# Git status preview (used by Alt+S)
$env:FZF_GIT_STATUS_PREVIEW_CMD = "<custom-git-status-preview-command>"

# Package preview (used by Alt+P)
$env:FZF_PACKAGE_PREVIEW_CMD = "<custom-package-preview-command>"

# Diff preview (used by git status - requires delta)
$env:FZF_DIFF_PREVIEW_CMD = "<custom-diff-preview-command>"
```

The module automatically selects Python preview scripts if Python is available (for better performance), otherwise falls back to PowerShell preview scripts.

## Verbose Output

The module supports PowerShell's standard `-Verbose` parameter for diagnostics. You can enable verbose output in two ways:

1. For a single command invocation, use the `-Verbose` parameter:

   ```powershell
   Invoke-FzfGitStatusWidget -Verbose
   ```

2. For the entire session, set the `$VerbosePreference` variable:

   ```powershell
   $VerbosePreference = "Continue"
   ```

3. When importing the module (affects all commands from this module):

   ```powershell
   Import-Module fzf.pwsh -Verbose
   ```

When verbose mode is enabled, the widget functions will display additional information, such as notifications about not being in a git repository or when there are no changes in a git repository. When verbose mode is disabled (the default), these notifications will not appear, keeping your prompt clean.

## Credits

This is a PowerShell port of the [fzf.zsh](https://github.com/scaryrawr/fzf.zsh) plugin mostly done by GitHub Copilot.

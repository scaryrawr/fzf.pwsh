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

- **Ctrl+T**: File search
- **Ctrl+R**: Command history reverse search
- **Ctrl+S**: Command history forward search
- **Alt+C**: Change directory
- **Alt+G**: Git log
- **Alt+S**: Git status
- **Alt+V**: Environment variables
- **Alt+P**: Package search

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

## Development and Testing

### Quick Testing

For rapid development validation:

```powershell
# Quick module test (loads module, checks functions, tests basic functionality)
.\tests\Quick-Test.ps1

# Validate test environment setup
.\tests\Validate-TestSetup.ps1
```

### Full Test Suite

The project includes comprehensive tests that run on Windows, Linux, and macOS:

```powershell
# Run all tests
.\tests\Test-Runner.ps1

# Run specific test suites
.\tests\Test-Runner.ps1 -TestSuite Module
.\tests\Test-Runner.ps1 -TestSuite Widgets
.\tests\Test-Runner.ps1 -TestSuite Integration

# Run in CI mode (exits with error code on failure)
.\tests\Test-Runner.ps1 -CI
```

### Test Philosophy

The tests focus on high-level functionality rather than internal implementation:

- **Environment Variable Injection** - Ensuring preview commands are set correctly
- **Cross-Platform Compatibility** - Path handling across Windows/Linux/macOS
- **Widget Behavior** - Testing user-facing functionality
- **Error Handling** - Graceful degradation when dependencies are missing
- **Real-World Scenarios** - Testing in actual git repos and file systems

### Prerequisites for Testing

Required:

- **Pester** - PowerShell testing framework (`Install-Module Pester`)
- **PSReadLine** - For key binding functionality

Optional (enhances test coverage):

- **fzf** - Tests will skip fzf-dependent features if not available
- **Python** - For testing Python preview script selection
- **Git** - For git-related widget testing
- **fd**, **bat**, **delta** - For enhanced tool integration testing

### GitHub Workflows

- **Tests** - Multi-platform testing on Windows, Ubuntu, macOS
- **Code Quality** - PSScriptAnalyzer, manifest validation, import testing

## Credits

This is a PowerShell port of the [fzf.zsh](https://github.com/scaryrawr/fzf.zsh) plugin mostly done by GitHub Copilot.

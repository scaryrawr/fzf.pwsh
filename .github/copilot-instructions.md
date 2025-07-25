# fzf.pwsh - AI Coding Instructions

This is a PowerShell module that provides fzf (fuzzy finder) integration with PSReadLine for enhanced terminal workflows. It's a port of the author's fzf.zsh plugin.

## Architecture Overview

The module follows a **widget-based architecture** with three main components:

- **Module Core** (`fzf.psm1`) - Handles initialization, dependency detection, and environment setup
- **Widgets** (`widgets/`) - Individual functions that integrate with PSReadLine key bindings
- **Previewers** (`previewers/`) - Scripts that generate content for fzf's preview window

### Key Design Patterns

**Dual-language preview system**: Each previewer exists in both PowerShell (`.ps1`) and Python (`.py`) versions. The module automatically selects Python if available for better performance, falling back to PowerShell.

**Environment-driven configuration**: Preview commands are set via environment variables (`$env:FZF_*_PREVIEW_CMD`) allowing user customization while maintaining defaults.

**Cross-platform compatibility**: Uses `Join-Path` throughout and detects Windows vs Unix environments for appropriate tool selection.

## Widget Development Patterns

All widgets follow this consistent structure:

```powershell
function Invoke-Fzf[Name]Widget {
  [CmdletBinding()]  # Always include for verbose support
  param()

  # 1. Validate context (e.g., git repo check)
  # 2. Generate input data for fzf
  # 3. Call fzf with appropriate preview
  # 4. Process selection and integrate with PSReadLine
}
```

**PSReadLine Integration**: Use `[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState()` to read current command line, and `Insert()` or `Replace()` to modify it. Call `Ding()` for user feedback on errors.

**Verbose Handling**: Use `Write-Verbose` for user notifications (e.g., "Not in git repository"). This respects PowerShell's standard verbose preference system.

## Preview Script Conventions

**Python previewers** should:

- Use `shutil.which()` to detect external tools
- Handle file type detection with multiple fallbacks (mimetypes → `file` command → extension)
- Accept `FZF_PREVIEW_COLUMNS` and `FZF_PREVIEW_LINES` environment variables

**PowerShell previewers** should:

- Use `Get-Command -ErrorAction SilentlyContinue` for tool detection
- Implement similar fallback patterns as Python versions
- Format output appropriately for terminal display

## Development Workflows

**Testing**: Use `Test-VerboseOutput.ps1` as a template for testing verbose behavior. Create temporary directories for isolated testing.

**Module Loading**: The module automatically calls `Set-PsFzfKeyBindings` on import. Key bindings can be dynamically reconfigured by calling this function again.

**Dependency Management**: The module includes auto-installation logic for `fzf` on Windows using `winget`. Other dependencies are detected and gracefully degraded.

## Project-Specific Conventions

**Tool Priority**: Always prefer modern alternatives when available:

- `fd` over PowerShell `Get-ChildItem` for file finding
- `bat` over `Get-Content` for syntax highlighting
- `eza`/`exa` over `ls` for directory listing
- `delta` over raw git diff output

**Error Handling**: Use `Write-Warning` for missing dependencies, `Write-Verbose` for state notifications, and `[Microsoft.PowerShell.PSConsoleReadLine]::Ding()` for user interaction feedback.

**Environment Variables**: Use PowerShell's null-conditional assignment (`??=`) for setting defaults while respecting user customizations.

## Git Integration Specifics

Git widgets check for `.git` directory existence before proceeding. Git status widget parses `git status -s` output and uses regex `'^.{3}(.*)$'` to extract filenames from status lines.

All git-related widgets respect git's color configuration using `-c color.status=always` and similar flags.

## Performance Considerations

Python previewers are preferred for performance. When adding new preview functionality, implement both PowerShell and Python versions, with Python handling the heavy lifting and PowerShell providing compatibility.

The module loads all widgets via dot-sourcing in the main module file rather than using nested modules for faster startup.

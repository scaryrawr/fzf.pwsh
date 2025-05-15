# PowerShell module for FZF
# Port of the fzf.zsh plugin

if (-not (Get-Command 'fzf' -ErrorAction SilentlyContinue)) {
  if ($IsWindows) {
    try {
      Write-Host 'Installing fzf using winget...'
      winget install fzf 2>&1
      if ($LASTEXITCODE -ne 0) {
        throw "Winget installation failed with exit code $LASTEXITCODE"
      }
    }
    catch {
      Write-Warning "Failed to install fzf using winget: $_"
      Write-Warning 'Please install fzf manually from https://github.com/junegunn/fzf'
      return
    }
  }
  else {
    Write-Warning 'fzf is not installed. Please install it from https://github.com/junegunn/fzf'
    return
  }
}

# Get the module directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set default options if not already set
$env:FZF_DEFAULT_OPTS ??= '--ansi'

# Initialize preview command variables

if (Get-Command 'python' -ErrorAction SilentlyContinue) {
  $env:FZF_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_preview.py')"
  $env:FZF_GIT_BLAME_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_blame_preview.py')"
  $env:FZF_GIT_COMMIT_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_commit_preview.py')"
  $env:FZF_GIT_LOG_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_commit_preview.py')"
  $env:FZF_GIT_STATUS_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_status_preview.py')"
  $env:FZF_PACKAGE_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_package_preview.py')"
}
elseif (Get-Command 'python3' -ErrorAction SilentlyContinue) {
  $env:FZF_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_preview.py')"
  $env:FZF_GIT_BLAME_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_blame_preview.py')"
  $env:FZF_GIT_COMMIT_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_commit_preview.py')"
  $env:FZF_GIT_LOG_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_commit_preview.py')"
  $env:FZF_GIT_STATUS_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_git_status_preview.py')"
  $env:FZF_PACKAGE_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR 'previewers\python\fzf_package_preview.py')"
}
else {
  $env:FZF_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR 'previewers\fzf_preview.ps1')"
  $env:FZF_GIT_BLAME_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR 'previewers\fzf_git_blame_preview.ps1')"
  $env:FZF_GIT_COMMIT_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR 'previewers\fzf_git_commit_preview.ps1')"
  $env:FZF_GIT_LOG_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR 'previewers\fzf_git_log_preview.ps1')"
  $env:FZF_GIT_STATUS_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR 'previewers\fzf_git_status_preview.ps1')"
  $env:FZF_PACKAGE_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR 'previewers\fzf_package_preview.ps1')"
}

# Set up diff preview command with delta if available
if (Get-Command 'delta' -ErrorAction SilentlyContinue) {
  $env:FZF_DIFF_PREVIEW_CMD ??= 'delta --paging never'
}

# Source all widget functions - using Join-Path for cross-platform compatibility
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-file-widget.ps1')
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-history-widget.ps1')
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-cd-widget.ps1')
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-git-log-widget.ps1')
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-git-status-widget.ps1')
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-variables-widget.ps1')
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-package-widget.ps1')
. (Join-Path $SCRIPT_DIR 'widgets' 'fzf-git-blame-widget.ps1')

# PSReadLine key binding function
function Set-PsFzfKeyBindings {
  # Check if PSReadLine is available
  if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
    Write-Warning "PSReadLine module is required for key bindings. Please install it with 'Install-Module PSReadLine -Force'"
    return
  }

  # Import PSReadLine if it's not already loaded
  if (-not (Get-Module -Name PSReadLine)) {
    Import-Module PSReadLine
  }
  
  # Helper function to unbind existing key and bind new handler
  function Set-PsFzfShortcut {
    param(
      [Parameter(Mandatory = $true)][string]$Key,
      [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
      [Parameter(Mandatory = $true)][string]$Description
    )
    
    try {
      # Try to unbind the key first
      Remove-PSReadLineKeyHandler -Key $Key -ViMode None -ErrorAction SilentlyContinue
      Write-Verbose "Removed existing binding for $Key"
    }
    catch {
      Write-Verbose "No prior binding found for $Key or could not remove: $_"
    }
    
    # Now set the new binding
    Set-PSReadLineKeyHandler -Key $Key -ScriptBlock $ScriptBlock -Description $Description
    Write-Verbose "Added binding for ${Key} - ${Description}"
  }
  
  # Set key bindings - matching the original fzf.zsh bindings
  # File widget (^T)
  Set-PsFzfShortcut -Key 'Ctrl+t' -ScriptBlock { 
    Invoke-FzfFileWidget
  } -Description 'FZF file search'
  
  # History widgets (^R for reverse search, ^S for forward search)
  Set-PsFzfShortcut -Key 'Ctrl+r' -ScriptBlock { 
    Invoke-FzfHistoryWidget
  } -Description 'FZF history reverse search'
  Set-PsFzfShortcut -Key 'Ctrl+s' -ScriptBlock { 
    Invoke-FzfHistoryWidget -ForwardSearch
  } -Description 'FZF history forward search'
  
  # CD widget (Alt+c)
  Set-PsFzfShortcut -Key 'Alt+c' -ScriptBlock { 
    Invoke-FzfCdWidget
  } -Description 'FZF change directory'
  
  # Git log widget (Alt+g)
  Set-PsFzfShortcut -Key 'Alt+g' -ScriptBlock { 
    Invoke-FzfGitLogWidget
  } -Description 'FZF git log'
  
  # Git status widget (Alt+s)
  Set-PsFzfShortcut -Key 'Alt+s' -ScriptBlock { 
    Invoke-FzfGitStatusWidget
  } -Description 'FZF git status'
  
  # Variables widget (Alt+V)
  Set-PsFzfShortcut -Key 'Alt+v' -ScriptBlock { 
    Invoke-FzfVariablesWidget
  } -Description 'FZF environment variables'
  
  # Package widget (Alt+P)
  Set-PsFzfShortcut -Key 'Alt+p' -ScriptBlock {
    Invoke-FzfPackageWidget
  } -Description 'FZF package search'
  
  # Git blame widget (Alt+b)
  #Set-PsFzfShortcut -Key 'Alt+b' -ScriptBlock {
  #  Invoke-FzfGitBlameWidget
  #} -Description 'FZF git blame'
}

# Export the key binding function and all the widget functions
Export-ModuleMember -Function Set-PsFzfKeyBindings, 
Invoke-FzfFileWidget, 
Invoke-FzfHistoryWidget, 
Invoke-FzfCdWidget, 
Invoke-FzfGitLogWidget, 
Invoke-FzfGitStatusWidget, 
Invoke-FzfVariablesWidget, 
Invoke-FzfPackageWidget, 
Invoke-FzfGitBlameWidget,
Find-FzfFiles

# Call the function to set up key bindings when the module is imported
Set-PsFzfKeyBindings

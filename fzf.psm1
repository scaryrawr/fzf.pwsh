# PowerShell module for FZF
# Port of the fzf.zsh plugin

# Get the module directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set default options if not already set
$env:FZF_DEFAULT_OPTS ??= "--ansi"

# Initialize preview command variables

if (Get-Command "python" -ErrorAction SilentlyContinue) {
  $env:FZF_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR "previewers\python\fzf_preview.py")"
  $env:FZF_GIT_BLAME_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_blame_preview.py")"
  $env:FZF_GIT_COMMIT_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_commit_preview.py")"
  $env:FZF_GIT_LOG_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_commit_preview.py")"
  $env:FZF_GIT_STATUS_PREVIEW_CMD ??= "python $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_status_preview.py")"
}
elseif (Get-Command "python3" -ErrorAction SilentlyContinue) {
  $env:FZF_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR "previewers\python\fzf_preview.py")"
  $env:FZF_GIT_BLAME_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_blame_preview.py")"
  $env:FZF_GIT_COMMIT_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_commit_preview.py")"
  $env:FZF_GIT_LOG_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_commit_preview.py")"
  $env:FZF_GIT_STATUS_PREVIEW_CMD ??= "python3 $(Join-Path $SCRIPT_DIR "previewers\python\fzf_git_status_preview.py")"
}
else {
  $env:FZF_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR "previewers\fzf_preview.ps1")"
  $env:FZF_GIT_BLAME_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR "previewers\fzf_git_blame_preview.ps1")"
  $env:FZF_GIT_COMMIT_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR "previewers\fzf_git_commit_preview.ps1")"
  $env:FZF_GIT_LOG_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR "previewers\fzf_git_log_preview.ps1")"
  $env:FZF_GIT_STATUS_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR "previewers\fzf_git_status_preview.ps1")"
}
#$env:FZF_PACKAGE_PREVIEW_CMD ??= "pwsh $(Join-Path $SCRIPT_DIR "previewers\fzf_package_preview.ps1")"

# Set up diff preview command with delta if available
if (Get-Command "delta" -ErrorAction SilentlyContinue) {
  $env:FZF_DIFF_PREVIEW_CMD ??= "delta --paging never"
}

# Source all widget functions
. "$SCRIPT_DIR\widgets\fzf-file-widget.ps1"
. "$SCRIPT_DIR\widgets\fzf-history-widget.ps1"
. "$SCRIPT_DIR\widgets\fzf-cd-widget.ps1"
. "$SCRIPT_DIR\widgets\fzf-git-log-widget.ps1"
. "$SCRIPT_DIR\widgets\fzf-git-status-widget.ps1"
. "$SCRIPT_DIR\widgets\fzf-variables-widget.ps1"
#. "$SCRIPT_DIR\widgets\fzf-package-widget.ps1"
. "$SCRIPT_DIR\widgets\fzf-git-blame-widget.ps1"

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
  # Set key bindings - matching the original fzf.zsh bindings
  # File widget (^T, ^[^F)
  Set-PSReadLineKeyHandler -Key "Ctrl+t" -ScriptBlock ${function:Invoke-FzfFileWidget} -Description "FZF file search"
  Set-PSReadLineKeyHandler -Key "Alt+Ctrl+f" -ScriptBlock ${function:Invoke-FzfFileWidget} -Description "FZF file search"
  
  # History widget (^R, Up Arrow)
  Set-PSReadLineKeyHandler -Key "Ctrl+r" -ScriptBlock ${function:Invoke-FzfHistoryWidget} -Description "FZF history search"
  Set-PSReadLineKeyHandler -Key "UpArrow" -ScriptBlock ${function:Invoke-FzfHistoryWidget} -Description "FZF history search"
  
  # CD widget (Alt+c)
  Set-PSReadLineKeyHandler -Key "Alt+c" -ScriptBlock ${function:Invoke-FzfCdWidget} -Description "FZF change directory"
  
  # Git log widget (Alt+Ctrl+L)
  Set-PSReadLineKeyHandler -Key "Alt+Ctrl+l" -ScriptBlock ${function:Invoke-FzfGitLogWidget} -Description "FZF git log"
  
  # Git status widget (Alt+Ctrl+T, Alt+Ctrl+S)
  Set-PSReadLineKeyHandler -Key "Alt+Ctrl+t" -ScriptBlock ${function:Invoke-FzfGitStatusWidget} -Description "FZF git status"
  Set-PSReadLineKeyHandler -Key "Alt+Ctrl+s" -ScriptBlock ${function:Invoke-FzfGitStatusWidget} -Description "FZF git status"
  
  # Variables widget (Alt+V)
  Set-PSReadLineKeyHandler -Key "Alt+v" -ScriptBlock ${function:Invoke-FzfVariablesWidget} -Description "FZF environment variables"
  
  # Package widget (Alt+Ctrl+P)
  #Set-PSReadLineKeyHandler -Key "Alt+Ctrl+p" -ScriptBlock ${function:Invoke-FzfPackageWidget} -Description "FZF package search"
  
  # Git blame widget (Alt+Ctrl+B)
  Set-PSReadLineKeyHandler -Key "Alt+Ctrl+b" -ScriptBlock ${function:Invoke-FzfGitBlameWidget} -Description "FZF git blame"
}

# Export the key binding function and all the widget functions
Export-ModuleMember -Function Set-PsFzfKeyBindings, 
Invoke-FzfFileWidget, 
Invoke-FzfHistoryWidget, 
Invoke-FzfCdWidget, 
Invoke-FzfGitLogWidget, 
Invoke-FzfGitStatusWidget, 
Invoke-FzfVariablesWidget, 
#Invoke-FzfPackageWidget, 
Invoke-FzfGitBlameWidget,
Find-FzfFiles

# Call the function to set up key bindings when the module is imported
Set-PsFzfKeyBindings

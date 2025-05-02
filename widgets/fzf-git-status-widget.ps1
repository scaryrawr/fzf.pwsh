# PowerShell port of fzf-git-status-widget.zsh

function Invoke-FzfGitStatusWidget {
  [CmdletBinding()]
  param()

  # Check if in a git repository
  if (-not (Test-Path -Path '.git')) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    Write-Verbose "`nNot in a git repository"
    return
  }

  # Get git status
  $gitStatus = git -c color.status=always status -s

  # If there's no changes, inform the user and exit
  if (-not $gitStatus) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    Write-Verbose "`nNo changes in git repository"
    return
  }

  # Run fzf to select files
  $selectedFiles = $gitStatus | fzf --ansi --multi --height 60% --preview="$env:FZF_GIT_STATUS_PREVIEW_CMD {2}"

  # If files were selected, extract the file paths and insert them
  if ($selectedFiles) {
    $filePaths = $selectedFiles | ForEach-Object {
      # Extract just the file path, removing the status indicators
      $_ -replace '^.{3}(.*)$', '$1'
    }

    # Join the file paths with spaces
    $filesToInsert = ($filePaths -join ' ').Trim()
        
    # Insert the file paths
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($filesToInsert)
  }
  
  [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

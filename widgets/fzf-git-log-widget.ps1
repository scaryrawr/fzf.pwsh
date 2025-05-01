# PowerShell port of fzf-git-log-widget.zsh

function Invoke-FzfGitLogWidget {
  # Check if in a git repository
  if (-not (Test-Path -Path ".git")) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    Write-Host "`nNot in a git repository" -ForegroundColor Red
    return
  }

  # Get git log
  $gitLog = git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr"

  # Run fzf to select a commit
  $selectedCommit = $gitLog | fzf --no-multi --ansi --height 60% --preview="$env:FZF_GIT_LOG_PREVIEW_CMD {1}"

  # If a commit was selected, insert the commit hash
  if ($selectedCommit) {
    # Extract commit hash
    $commitHash = $selectedCommit -replace '^([a-f0-9]+).*', '$1'
        
    # Get current command line
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($commitHash)
  }
  
  [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

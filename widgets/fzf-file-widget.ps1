# PowerShell port of fzf-file-widget.zsh

function Find-FzfFiles {
  # Try to use fd if available
  if (Get-Command "fd" -ErrorAction SilentlyContinue) {
    fd --type file --color=always
  }
  else {
    # Fall back to PowerShell
    if (Test-Path -Path ".git") {
      # If in a git repo, exclude git ignored files
      try {
        $gitFiles = (git ls-files --others --ignored --exclude-standard --directory) -join "`n"
        Get-ChildItem -File -Recurse -Force | Where-Object {
          $_.FullName -notmatch '\.git\\' -and
          $gitFiles -notcontains $_.FullName
        } | ForEach-Object { $_.FullName.Replace("$pwd\", "") }
      }
      catch {
        Get-ChildItem -File -Recurse -Force | Where-Object { $_.FullName -notmatch '\.git\\' } | 
        ForEach-Object { $_.FullName.Replace("$pwd\", "") }
      }
    }
    else {
      # Not in git repo, just get all files
      Get-ChildItem -File -Recurse -Force | Where-Object { $_.FullName -notmatch '\.git\\' } | 
      ForEach-Object { $_.FullName.Replace("$pwd\", "") }
    }
  }
}

function Invoke-FzfFileWidget {
  # Get current command line and cursor position
  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  # Extract hint from cursor position if there's any word at cursor
  $hint = ""
  if ($cursor -gt 0) {
    # Define word delimiters manually instead of using TokenizerHelper
    $wordDelimiters = " `t`n`r,;{}()[]'\`" | &><"
    $lastWordStart = $cursor - 1
    while ($lastWordStart -ge 0 -and -not $wordDelimiters.Contains($line[$lastWordStart])) {
      $lastWordStart--
    }
    if ($lastWordStart -lt $cursor - 1) {
      $hint = $line.Substring($lastWordStart + 1, $cursor - $lastWordStart - 1)
    }
  }
  # Run fzf to select files
  $selectedFiles = Find-FzfFiles | Out-String | fzf --preview "$env:FZF_PREVIEW_CMD {}" --height 60% --preview-window=right:60% --query="$hint" --multi
    
  # If files were selected, replace the hint with the selection
  if ($selectedFiles) {
    if ($hint) {
      $replacementPoint = $cursor - $hint.Length
      $newText = ($selectedFiles -replace "`r`n", " ").TrimEnd()
      [Microsoft.PowerShell.PSConsoleReadLine]::Replace($replacementPoint, $hint.Length, $newText)
    }
    else {
      $newText = ($selectedFiles -replace "`r`n", " ").TrimEnd()
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert($newText)
    }
  }
}

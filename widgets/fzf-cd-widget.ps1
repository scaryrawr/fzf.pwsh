# PowerShell port of fzf-cd-widget.zsh

function Invoke-FzfCdWidget {
  # Function to find directories
  function Find-Directories {
    if (Get-Command "fd" -ErrorAction SilentlyContinue) {
      fd --type directory --color=always
    }
    else {
      Get-ChildItem -Directory -Recurse -Force | Where-Object { $_.FullName -notmatch '\.git\\' } | 
      ForEach-Object { $_.FullName.Replace("$pwd\", "") }
    }
  }

  # Run fzf to select a directory
  $selectedDir = Find-Directories | Out-String | fzf --height 60% --preview "$env:FZF_PREVIEW_CMD {}"

  # If a directory was selected, navigate to it
  if ($selectedDir) {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cd '$($selectedDir.Trim())'")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }

  [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

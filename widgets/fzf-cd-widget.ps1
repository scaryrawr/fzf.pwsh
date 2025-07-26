# PowerShell port of fzf-cd-widget.zsh

function Invoke-FzfCdWidget {
  [CmdletBinding()]
  param()
  
  # Function to find directories
  function Find-Directories {
    if (Get-Command 'fd' -ErrorAction SilentlyContinue) {
      fd --type directory --color=always
    }
    else {
      Get-ChildItem -Directory -Recurse -Force | Where-Object { 
        $_.FullName -notmatch "\.git$([regex]::Escape([System.IO.Path]::DirectorySeparatorChar))"
      } | ForEach-Object { 
        [System.IO.Path]::GetRelativePath($PWD.Path, $_.FullName)
      }
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
}

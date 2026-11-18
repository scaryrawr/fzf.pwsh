# PowerShell port of fzf-history-widget.zsh

function Invoke-FzfHistoryWidget {
  [CmdletBinding()]
  param(
    [switch]$ForwardSearch
  )

  # Get current command line
  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  $history = @(Get-Content (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue)

  if (-not $ForwardSearch) {
    [array]::Reverse($history)
  }

  $selectedCommand = $history | Select-Object -Unique | fzf --height 60% --query="$line"

  # If a command was selected, replace the current line with it
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

  if ($selectedCommand) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selectedCommand)
  }
  else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line)
  }
}

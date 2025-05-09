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

  # Use PSReadLine's history as a source
  $history = Get-Content (Get-PSReadLineOption).HistorySavePath -ErrorAction SilentlyContinue

  # Use the current line as the query
  $query = $line

  # Run fzf to select command from history
  if ($ForwardSearch) {
    $selectedCommand = $history | fzf --height 60% --query="$query"
  }
  else {
    $selectedCommand = $history | fzf --tac --height 60% --query="$query"
  }

  # If a command was selected, replace the current line with it
  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()

  if ($selectedCommand) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selectedCommand)
  }
  else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line)
  }
}

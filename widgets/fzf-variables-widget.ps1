# PowerShell port of fzf-variables-widget.zsh

function Invoke-FzfVariablesWidget {
  [CmdletBinding()]
  param()
  
  # Get current command line
  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
  # Get all variables in the current session
  $variables = Get-Variable | 
  Where-Object { 
    -not $_.Name.StartsWith('?') -and 
    -not $_.Name.StartsWith('args') -and
    -not $_.Name.StartsWith('PSCommandPath')
  } |
  ForEach-Object {
    $_.Name
  }
    
  # Use fzf to select a variable
  $selectedVariable = $variables | fzf --height 60% --preview-window bottom:3:wrap
    
  if ($selectedVariable) {
    # Insert the variable name
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("`$$selectedVariable")
  }
  
  [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}

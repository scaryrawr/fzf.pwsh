# PowerShell port of fzf-git-blame-widget.zsh

function Invoke-FzfGitBlameWidget {
    [CmdletBinding()]
    param()

    # Check if in a git repository
    if (-not (Test-Path -Path '.git')) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
        Write-Verbose "`nNot in a git repository"
        return
    }

    # Get current file path from the command line or prompt the user
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
    $filePath = ''
    if ($line -match '([a-zA-Z0-9\.\-_\\\/]+\.[\w]+)') {
        $filePath = $matches[1]
    }
    
    if (-not $filePath -or -not (Test-Path $filePath)) {
        # Prompt for file if no valid file is in the command line
        $gitFiles = git ls-files
        $selectedFile = $gitFiles | fzf --height 60% --preview="$env:FZF_GIT_BLAME_PREVIEW_CMD {}"
        
        if (-not $selectedFile) {
            return
        }
        
        $filePath = $selectedFile
    }

    # Get git blame output for the file
    $gitBlame = git blame --abbrev=8 $filePath

    # Run fzf to select a blame line
    $selectedBlame = $gitBlame | fzf --height 60% --preview="$env:FZF_GIT_COMMIT_PREVIEW_CMD {1}"

    # If a blame line was selected, extract the commit hash
    if ($selectedBlame) {
        # Insert the commit line number
        $selectedBlame = $selectedBlame -split '\s+' | Select-Object -First 1
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("${selectedBlame}")
    }
}

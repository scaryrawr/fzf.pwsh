# PowerShell port of fzf_git_blame_preview

param(
    [Parameter(Position = 0)]
    [string]$filePath
)

if (-not $filePath) {
    Write-Output "Usage: fzf_git_blame_preview <file_path>"
    exit 1
}

git blame --abbrev=8 "$filePath"
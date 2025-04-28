# PowerShell port of fzf_git_log_preview

param(
    [Parameter(Position = 0)]
    [string]$commit
)

if (-not $commit) {
    Write-Output "Usage: fzf_git_log_preview <commit_hash>"
    exit 1
}

# Extract just the hash part if we have a full log line
if ($commit -match "^([a-f0-9]+)") {
    $commit = $matches[1]
}

# Show the commit details with diff
if ($env:FZF_DIFF_PREVIEW_CMD) {
    git show --color=always $commit | Invoke-Expression $env:FZF_DIFF_PREVIEW_CMD
}
else {
    git show --color=always $commit
}

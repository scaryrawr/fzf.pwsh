# PowerShell port of fzf_git_commit_preview

param(
    [Parameter(Position = 0)]
    [string]$commit
)

if (-not $commit) {
    Write-Output "Usage: fzf_git_commit_preview <commit_hash>"
    exit 1
}

# Show the commit details with diff
Write-Output "$commit"
git show --color=always $commit

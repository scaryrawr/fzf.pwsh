# PowerShell port of fzf_git_status_preview

param(
  [Parameter(Position = 0)]
  [string]$file
)

if (-not $file) {
  Write-Output "Usage: fzf_git_status_preview <file_path>"
  exit 1
}

# Get the git status of the file
$gitStatus = git status -s -- "$file"

# If the file is untracked, show its contents
if ($gitStatus -match "^\?\? ") {
  if (Get-Command "bat" -ErrorAction SilentlyContinue) {
    bat --style=numbers --color=always $file
  }
  else {
    Get-Content $file | Out-String
  }
}
# Otherwise show the diff
else {
  if ($env:FZF_DIFF_PREVIEW_CMD) {
    git diff --color=always -- $file | Invoke-Expression $env:FZF_DIFF_PREVIEW_CMD
  }
  else {
    git diff --color=always -- $file
  }
}

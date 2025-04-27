# PowerShell port of fzf_preview

param(
  [Parameter(Position = 0)]
  [string]$path
)

# Function to get terminal size
function Get-TerminalSize {
  $size = "$env:FZF_PREVIEW_COLUMNS" + "x" + "$env:FZF_PREVIEW_LINES"
  if ($size -eq "x") {
    # Default to a reasonable size if not provided
    $size = "80x24"
  }
  return $size
}

# Function to preview a file
function Preview-File {
  param([string]$FilePath)
    
  # Use bat if available, otherwise fall back to cat/Get-Content
  if (Get-Command "bat" -ErrorAction SilentlyContinue) {
    bat --style=numbers --color=always $FilePath
  }
  else {
    Get-Content $FilePath | Out-String
  }
}

# Function to preview an image
function Preview-Image {
  param([string]$ImagePath)
    
  # Use chafa if available, otherwise just show file info
  if (Get-Command "chafa" -ErrorAction SilentlyContinue) {
    $size = Get-TerminalSize
    chafa --size $size $ImagePath
  }
  else {
    Get-Item $ImagePath | Select-Object Name, Length, LastWriteTime | Format-List
  }
}

# Main logic
if (-not $path) {
  Write-Output "No path provided for preview"
  exit 1
}

if (Test-Path -Path $path -PathType Container) {
  # Directory preview
  if (Get-Command "eza" -ErrorAction SilentlyContinue) {
    eza -l --color=always $path
  }
  elseif (Get-Command "exa" -ErrorAction SilentlyContinue) {
    exa -l --color=always $path
  }
  else {
    Get-ChildItem -Path $path -Force | Format-Table -AutoSize
  }
}
elseif (Test-Path -Path $path -PathType Leaf) {
  # Check if we can determine the file type
  if (Get-Command "file" -ErrorAction SilentlyContinue) {
    $fileType = file --mime-type $path
        
    if ($fileType -match "image/") {
      Preview-Image -ImagePath $path
    }
    else {
      Preview-File -FilePath $path
    }
  }
  else {
    # Try to detect based on extension
    $extension = [System.IO.Path]::GetExtension($path)
    $imageExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico', '.tiff')
        
    if ($extension -in $imageExtensions) {
      Preview-Image -ImagePath $path
    }
    else {
      Preview-File -FilePath $path
    }
  }
}
else {
  Write-Output "Path not found: $path"
  exit 1
}

# PowerShell script to preview package information

param (
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$PackageName,
    
  [Parameter(Mandatory = $true, Position = 1)]
  [string]$CacheFile
)

# Function for colored output
function Write-ColorText {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Text,
        
    [Parameter(Mandatory = $true)]
    [string]$ForegroundColor
  )
    
  $originalColor = $host.UI.RawUI.ForegroundColor
  $host.UI.RawUI.ForegroundColor = $ForegroundColor
  Write-Output $Text
  $host.UI.RawUI.ForegroundColor = $originalColor
}

# Check if cache file exists
if (-not (Test-Path -Path $CacheFile)) {
  Write-ColorText "Error: Cache file not found: $CacheFile" 'Red'
  exit 1
}

# Load the cache file
try {
  $packagesData = Get-Content -Raw -Path $CacheFile | ConvertFrom-Json
}
catch {
  Write-ColorText "Error loading cache file: $_" 'Red'
  exit 1
}

# Find all matching package paths
$locations = $packagesData | 
Where-Object { $_.name -eq $PackageName } | 
Select-Object -ExpandProperty path

if ($null -eq $locations) {
  Write-ColorText "No package information found for $PackageName" 'Yellow'
  exit 0
}

# Check if multiple locations found
if ($locations -is [array] -and $locations.Count -gt 1) {
  Write-ColorText "Warning: More than one location found for $PackageName" 'Yellow'
}

# Process each location
foreach ($location in $locations) {
  Write-Output $location
    
  # Use FZF_PREVIEW_CMD if available
  if ($env:FZF_PREVIEW_CMD) {
    try {
      Invoke-Expression "$env:FZF_PREVIEW_CMD '$location'"
    }
    catch {
      Write-ColorText "Error previewing file: $_" 'Red'
    }
  }
  else {
    # Fallback preview
    if (Test-Path -Path $location) {
      if ($location.EndsWith('.json')) {
        try {
          $packageJson = Get-Content -Raw -Path $location | ConvertFrom-Json
          $packageJson | ConvertTo-Json -Depth 4
        }
        catch {
          Write-ColorText "Error parsing JSON: $_" 'Red'
        }
      }
      else {
        # Just show the file content
        Get-Content -Path $location -TotalCount 20
      }
    }
    else {
      Write-ColorText "File not found: $location" 'Red'
    }
  }
}

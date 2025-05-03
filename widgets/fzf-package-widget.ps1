# PowerShell port of fzf-package-widget.zsh

function Get-PackageHash {
  param(
    [string]$Hash = ''
  )
  
  $result = $Hash
  
  # Function to compute hash that works across platforms
  function Get-StringHash {
    param([string]$InputString)
    
    # Use .NET's SHA256 implementation for cross-platform compatibility
    try {
      $sha256 = [System.Security.Cryptography.SHA256]::Create()
      $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString))
      return [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
    }
    catch {
      Write-Verbose "Error computing hash: $_"
      return $null
    }
    finally {
      if ($sha256) { $sha256.Dispose() }
    }
  }
  
  # Check for package.json
  if (Test-Path -Path 'package.json') {
    if (Get-Command 'git' -ErrorAction SilentlyContinue) {
      try {
        # Use git to get file list, works on all platforms
        $packageJsonFiles = (git ls-files '*package.json' | Out-String).Trim()
        if ($packageJsonFiles) {
          $result = Get-StringHash -InputString $packageJsonFiles
        }
      }
      catch {
        Write-Verbose "Error getting package.json hash: $_"
      }
    }
    else {
      # Fallback if git is not available
      try {
        $packageJsonFiles = Get-ChildItem -Path '.' -Filter 'package.json' -Recurse | 
        Select-Object -ExpandProperty FullName | 
        ForEach-Object { $_.Replace($PWD.Path, '').TrimStart('/\') }
        
        if ($packageJsonFiles) {
          $result = Get-StringHash -InputString ($packageJsonFiles -join "`n")
        }
      }
      catch {
        Write-Verbose "Error getting package.json files without git: $_"
      }
    }
  }
  
  # Check for Cargo.toml
  if (Test-Path -Path 'Cargo.toml') {
    if (Get-Command 'git' -ErrorAction SilentlyContinue) {
      try {
        $cargoFiles = (git ls-files '*Cargo.toml' | Out-String).Trim()
        if ($cargoFiles) {
          $cargoHash = Get-StringHash -InputString $cargoFiles
          
          if ($result) {
            $combined = "$result-$cargoHash"
            $result = Get-StringHash -InputString $combined
          }
          else {
            $result = $cargoHash
          }
        }
      }
      catch {
        Write-Verbose "Error getting Cargo.toml hash: $_"
      }
    }
    else {
      # Fallback if git is not available
      try {
        $cargoFiles = Get-ChildItem -Path '.' -Filter 'Cargo.toml' -Recurse | 
        Select-Object -ExpandProperty FullName | 
        ForEach-Object { $_.Replace($PWD.Path, '').TrimStart('/\') }
        
        if ($cargoFiles) {
          $cargoHash = Get-StringHash -InputString ($cargoFiles -join "`n")
          
          if ($result) {
            $combined = "$result-$cargoHash"
            $result = Get-StringHash -InputString $combined
          }
          else {
            $result = $cargoHash
          }
        }
      }
      catch {
        Write-Verbose "Error getting Cargo.toml files without git: $_"
      }
    }
  }
  
  return $result
}

function Invoke-FzfPackageWidget {
  [CmdletBinding()]
  param()
  
  # Get current command line and cursor position
  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  
  # Extract hint from cursor position if there's any word at cursor
  $hint = ''
  if ($cursor -gt 0) {
    # Define word delimiters that work across all platforms
    # Avoid using special characters that might be interpreted differently
    $wordDelimiters = " `t`n`r,;{}()[]'`"" 
    
    # Add additional delimiters in a safe way
    $wordDelimiters += '|&><'
    
    $lastWordStart = $cursor - 1
    while ($lastWordStart -ge 0 -and -not $wordDelimiters.Contains($line[$lastWordStart])) {
      $lastWordStart--
    }
    if ($lastWordStart -lt $cursor - 1) {
      $hint = $line.Substring($lastWordStart + 1, $cursor - $lastWordStart - 1)
    }
  }
  
  # Create safe directory and cache paths
  $safeDirName = $PWD.Path -replace '[\\\/]', '_'
  
  # Use platform-appropriate temp directory
  $tempBase = if ($env:TEMP) { 
    # Windows
    $env:TEMP 
  }
  elseif ($env:TMPDIR) { 
    # macOS/Linux
    $env:TMPDIR 
  }
  else { 
    # Fallback
    '/tmp'
  }
  
  $cacheDir = Join-Path $tempBase 'fzf.pwsh' $safeDirName
  
  # Get hash of package files
  $hash = Get-PackageHash
  
  # Exit if no package files were found
  if (-not $hash) {
    Write-Verbose 'No package.json or Cargo.toml found'
    return
  }
  
  # Get or create cache file
  $cacheFile = Join-Path $cacheDir "$hash.json"
  $packagesInfo = $null
  
  if (Test-Path -Path $cacheFile) {
    $packagesInfo = Get-Content -Raw -Path $cacheFile | ConvertFrom-Json
  }
  else {
    # Create cache directory if it doesn't exist
    if (-not (Test-Path -Path $cacheDir)) {
      New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
    }
    
    # Initialize empty JSON array
    $packagesInfo = @()
    $packagesInfo | ConvertTo-Json | Set-Content -Path $cacheFile
    
    # Get Node.js workspace info
    if (Test-Path -Path 'package.json') {
      # Check for npm workspaces first (works cross-platform)
      if (Get-Content -Path 'package.json' -Raw | Select-String -Pattern '"workspaces"') {
        # First try yarn if available
        if (Get-Command 'yarn' -ErrorAction SilentlyContinue) {
          try {
            $yarnInfo = yarn --json workspaces info 2>$null
            if ($yarnInfo) {
              $workspaceInfo = $yarnInfo | ConvertFrom-Json
              if ($workspaceInfo.data) {
                $packagesInfo = $workspaceInfo.data.PSObject.Properties | Where-Object { $_.Value.location } | ForEach-Object {
                  [PSCustomObject]@{
                    name = $_.Name
                    path = "./$($_.Value.location)/package.json"
                  }
                }
                $packagesInfo | ConvertTo-Json | Set-Content -Path $cacheFile
              }
            }
          }
          catch {
            Write-Verbose "Error getting yarn workspace info: $_"
          }
        }
        # Fallback to npm list for workspace info
        elseif (Get-Command 'npm' -ErrorAction SilentlyContinue) {
          try {
            $npmInfo = npm list --json --all 2>$null
            if ($npmInfo) {
              $npmWorkspaces = $npmInfo | ConvertFrom-Json
              if ($npmWorkspaces.dependencies) {
                $packagesFromNpm = $npmWorkspaces.dependencies.PSObject.Properties | 
                Where-Object { $_.Value.resolved -and $_.Value.resolved.StartsWith('file:') } |
                ForEach-Object {
                  [PSCustomObject]@{
                    name = $_.Name
                    path = Join-Path $_.Value.resolved.Substring(5) 'package.json'
                  }
                }
                
                $packagesInfo = @($packagesInfo) + @($packagesFromNpm)
                $packagesInfo | ConvertTo-Json | Set-Content -Path $cacheFile
              }
            }
          }
          catch {
            Write-Verbose "Error getting npm workspace info: $_"
          }
        }
      }
      # If no workspaces, just add the main package
      else {
        try {
          $packageJson = Get-Content -Path 'package.json' -Raw | ConvertFrom-Json
          if ($packageJson.name) {
            $packagesInfo = @([PSCustomObject]@{
                name = $packageJson.name
                path = './package.json'
              })
            $packagesInfo | ConvertTo-Json | Set-Content -Path $cacheFile
          }
        }
        catch {
          Write-Verbose "Error parsing package.json: $_"
        }
      }
    }
    
    # Get Cargo workspace info
    if (Test-Path -Path 'Cargo.toml') {
      if (Get-Command 'cargo' -ErrorAction SilentlyContinue) {
        try {
          # Ensure stderr is properly redirected on all platforms
          $cargoOutput = if ($IsWindows) {
            cargo metadata --format-version 1 2>$null
          }
          else {
            cargo metadata --format-version 1 2>/dev/null
          }
          
          if ($cargoOutput) {
            $cargoInfo = $cargoOutput | ConvertFrom-Json
            if ($cargoInfo -and $cargoInfo.packages) {
              # Handle platform-specific path formats in Cargo output
              $cargoPackages = $cargoInfo.packages | 
              Where-Object { $_.id -like 'path+file*' } |
              ForEach-Object {
                # Normalize path - on Windows manifest paths might need cleaning
                $manifestPath = $_.manifest_path
                if ($IsWindows) {
                  # Remove leading file:/// if present and normalize slashes
                  $manifestPath = $manifestPath -replace '^file:///', 'C:/' -replace '/', '\'
                }
                  
                [PSCustomObject]@{
                  name = $_.name
                  path = $manifestPath
                }
              }
              
              # Combine with existing packages
              if ($packagesInfo) {
                $packagesInfo = @($packagesInfo) + @($cargoPackages)
              }
              else {
                $packagesInfo = $cargoPackages
              }
              
              $packagesInfo | ConvertTo-Json | Set-Content -Path $cacheFile
            }
          }
        }
        catch {
          Write-Verbose "Error getting cargo metadata: $_"
        }
      }
    }
    
    # Read updated cache file
    $packagesInfo = Get-Content -Raw -Path $cacheFile | ConvertFrom-Json
  }
  
  # Preview command for packages
  # FZF_PACKAGE_PREVIEW_CMD is now set in the module initialization
  
  # Use FZF to select packages
  $packageNames = $packagesInfo | ForEach-Object { $_.name } | Select-Object -Unique
  if ($packageNames) {
    # For cross-platform compatibility, ensure the path is properly quoted
    # Our preview commands now handle both parameters explicitly
    $escapedCacheFile = $cacheFile -replace '"', '\"'
    
    # Use Out-String -Stream to ensure proper line handling on all platforms
    $selectedPackages = $packageNames | Out-String -Stream | 
    fzf --height 60% --prompt="Select package(s): " --preview "$env:FZF_PACKAGE_PREVIEW_CMD {} $escapedCacheFile" --query="$hint" --multi
    
    if ($selectedPackages) {
      # Replace hint with selected packages
      if ($hint -and $line -match [regex]::Escape($hint)) {
        $line = $line.Substring(0, $lastWordStart + 1) + ($selectedPackages -join ' ')
      }
      else {
        $line = $line + ' ' + ($selectedPackages -join ' ')
      }
      
      # Update the command line
      try {
        # Get buffer width safely
        $bufferWidth = $host.UI.RawUI.BufferSize.Width
        if (-not $bufferWidth -or $bufferWidth -le 0) {
          # Use a reasonable default width if we can't get buffer width
          $bufferWidth = 120
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $bufferWidth, $line)
      }
      catch {
        # Fallback method
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($line)
      }
      finally {
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
      }
    }
  }
}
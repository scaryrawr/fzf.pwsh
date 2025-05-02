# Test script to demonstrate verbose output in fzf.pwsh module
# This script can be run from any directory

# Get the module directory (location of this script)
$moduleDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create a temp directory for testing
$tempDir = Join-Path '/tmp' "fzf-pwsh-test-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Switch to the temp directory for testing
Push-Location $tempDir

try {
  # Test 1: Run normally (no verbose output)
  Write-Host "`n## Test 1: Normal operation (no verbose)" -ForegroundColor Cyan
  Import-Module "$moduleDir/fzf.psm1" -Force
  Write-Host 'Simulating not in git repository:'
  if (-not (Test-Path -Path '.git')) {
    Write-Host '(This should NOT show verbose output)' -ForegroundColor Yellow
    Invoke-FzfGitStatusWidget
  }

  # Test 2: With explicit verbose parameter
  Write-Host "`n## Test 2: Using explicit -Verbose parameter" -ForegroundColor Cyan
  Write-Host 'Simulating not in git repository:'
  if (-not (Test-Path -Path '.git')) {
    Write-Host '(This should show verbose output)' -ForegroundColor Yellow
    Invoke-FzfGitStatusWidget -Verbose
  }

  # Test 3: With VerbosePreference variable
  Write-Host "`n## Test 3: Using VerbosePreference variable" -ForegroundColor Cyan
  $VerbosePreference = 'Continue'
  Write-Host 'Simulating not in git repository:'
  if (-not (Test-Path -Path '.git')) {
    Write-Host '(This should show verbose output)' -ForegroundColor Yellow
    Invoke-FzfGitStatusWidget
  }
  $VerbosePreference = 'SilentlyContinue'

  Write-Host "`nTesting complete!" -ForegroundColor Green
}
finally {
  # Clean up: Return to original directory and remove temp directory
  Pop-Location
  if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
  }
}

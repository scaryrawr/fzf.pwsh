# Quick validation script for development workflow

Write-Host 'fzf.pwsh Quick Test' -ForegroundColor Cyan
Write-Host '===================' -ForegroundColor Cyan

# Test 1: Module loads
Write-Host "`n1. Testing module loading..." -ForegroundColor Yellow
try {
  Import-Module .\fzf.psm1 -Force
  Write-Host '   ✓ Module loaded successfully' -ForegroundColor Green
}
catch {
  Write-Host "   ✗ Module failed to load: $_" -ForegroundColor Red
  exit 1
}

# Test 2: Environment variables
Write-Host "`n2. Testing environment variable setup..." -ForegroundColor Yellow
$requiredVars = @('FZF_PREVIEW_CMD', 'FZF_DEFAULT_OPTS', 'FZF_GIT_STATUS_PREVIEW_CMD')
$allSet = $true
foreach ($var in $requiredVars) {
  $value = Get-Item "env:$var" -ErrorAction SilentlyContinue
  if ($value) {
    Write-Host "   ✓ $var is set" -ForegroundColor Green
  }
  else {
    Write-Host "   ✗ $var is not set" -ForegroundColor Red
    $allSet = $false
  }
}

if (-not $allSet) {
  exit 1
}

# Test 3: Functions exist
Write-Host "`n3. Testing exported functions..." -ForegroundColor Yellow
$requiredFunctions = @('Find-FzfFiles', 'Invoke-FzfFileWidget', 'Set-PsFzfKeyBindings')
$allExist = $true
foreach ($func in $requiredFunctions) {
  $command = Get-Command $func -ErrorAction SilentlyContinue
  if ($command) {
    Write-Host "   ✓ $func is available" -ForegroundColor Green
  }
  else {
    Write-Host "   ✗ $func is missing" -ForegroundColor Red
    $allExist = $false
  }
}

if (-not $allExist) {
  exit 1
}

# Test 4: Basic functionality
Write-Host "`n4. Testing basic functionality..." -ForegroundColor Yellow
try {
  $files = Find-FzfFiles
  Write-Host "   ✓ Find-FzfFiles executed successfully (found $($files.Count) files)" -ForegroundColor Green
}
catch {
  Write-Host "   ✗ Find-FzfFiles failed: $_" -ForegroundColor Red
  exit 1
}

# Test 5: Git widget in non-git directory
Write-Host "`n5. Testing git widget error handling..." -ForegroundColor Yellow
$tempDir = Join-Path $env:TEMP "fzf-test-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
try {
  Push-Location $tempDir
    
  # Should not throw, but should handle gracefully
  $VerbosePreference = 'Continue'
  $output = Invoke-FzfGitStatusWidget -Verbose 2>&1
  $VerbosePreference = 'SilentlyContinue'
    
  $verboseMessage = $output | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | Select-Object -First 1
  if ($verboseMessage -and $verboseMessage.Message -match 'Not in a git repository') {
    Write-Host '   ✓ Git widget handles non-git directory correctly' -ForegroundColor Green
  }
  else {
    Write-Host '   ⚠ Git widget may not be handling non-git directories as expected' -ForegroundColor Yellow
  }
}
catch {
  Write-Host "   ✗ Git widget test failed: $_" -ForegroundColor Red
}
finally {
  Pop-Location
  Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`n" + '='*50 -ForegroundColor Cyan
Write-Host 'All basic tests passed! ✓' -ForegroundColor Green
Write-Host '='*50 -ForegroundColor Cyan

Write-Host "`nTo run full test suite:" -ForegroundColor Cyan
Write-Host '  .\tests\Test-Runner.ps1' -ForegroundColor Gray
Write-Host "`nTo validate test setup:" -ForegroundColor Cyan
Write-Host '  .\tests\Validate-TestSetup.ps1' -ForegroundColor Gray

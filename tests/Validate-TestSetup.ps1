# Validation script to verify test setup is working correctly

param(
  [switch]$InstallDependencies
)

Write-Host 'Validating fzf.pwsh test setup...' -ForegroundColor Cyan

# Check PowerShell version
Write-Host "`n1. PowerShell Version Check" -ForegroundColor Yellow
Write-Host "   PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
if ($PSVersionTable.PSVersion.Major -lt 5) {
  Write-Warning 'PowerShell 5.1 or higher is recommended'
}

# Check for Pester
Write-Host "`n2. Pester Module Check" -ForegroundColor Yellow
$pester = Get-Module -ListAvailable -Name Pester
if ($pester) {
  Write-Host "   ✓ Pester found (Version: $($pester.Version))" -ForegroundColor Green
}
else {
  Write-Host '   ✗ Pester not found' -ForegroundColor Red
  if ($InstallDependencies) {
    Write-Host '   Installing Pester...' -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    Write-Host '   ✓ Pester installed' -ForegroundColor Green
  }
  else {
    Write-Warning 'Install with: Install-Module Pester -Force'
  }
}

# Check for PSReadLine
Write-Host "`n3. PSReadLine Module Check" -ForegroundColor Yellow
$psreadline = Get-Module -ListAvailable -Name PSReadLine
if ($psreadline) {
  Write-Host "   ✓ PSReadLine found (Version: $($psreadline.Version))" -ForegroundColor Green
}
else {
  Write-Host '   ✗ PSReadLine not found' -ForegroundColor Red
  if ($InstallDependencies) {
    Write-Host '   Installing PSReadLine...' -ForegroundColor Yellow
    Install-Module -Name PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber
    Write-Host '   ✓ PSReadLine installed' -ForegroundColor Green
  }
  else {
    Write-Warning 'Install with: Install-Module PSReadLine -Force'
  }
}

# Check for fzf
Write-Host "`n4. fzf Tool Check" -ForegroundColor Yellow
$fzf = Get-Command 'fzf' -ErrorAction SilentlyContinue
if ($fzf) {
  $fzfVersion = try { & fzf --version } catch { 'Unknown' }
  Write-Host "   ✓ fzf found (Version: $fzfVersion)" -ForegroundColor Green
}
else {
  Write-Host '   ⚠ fzf not found (tests will skip fzf-dependent functionality)' -ForegroundColor Yellow
  if ($InstallDependencies -and $IsWindows) {
    Write-Host '   Attempting to install fzf...' -ForegroundColor Yellow
    try {
      winget install fzf --accept-source-agreements --accept-package-agreements
      Write-Host '   ✓ fzf installed' -ForegroundColor Green
    }
    catch {
      Write-Warning "Failed to install fzf: $_"
    }
  }
}

# Check for Python
Write-Host "`n5. Python Check" -ForegroundColor Yellow
$python = Get-Command 'python' -ErrorAction SilentlyContinue
if (-not $python) {
  $python = Get-Command 'python3' -ErrorAction SilentlyContinue
}
if ($python) {
  $pythonVersion = try { & $python.Source --version } catch { 'Unknown' }
  Write-Host "   ✓ Python found (Version: $pythonVersion)" -ForegroundColor Green
}
else {
  Write-Host '   ⚠ Python not found (will test PowerShell preview fallback)' -ForegroundColor Yellow
}

# Check for Git
Write-Host "`n6. Git Check" -ForegroundColor Yellow
$git = Get-Command 'git' -ErrorAction SilentlyContinue
if ($git) {
  $gitVersion = try { & git --version } catch { 'Unknown' }
  Write-Host "   ✓ Git found (Version: $gitVersion)" -ForegroundColor Green
}
else {
  Write-Host '   ⚠ Git not found (git widget tests will be skipped)' -ForegroundColor Yellow
}

# Check optional tools
Write-Host "`n7. Optional Tools Check" -ForegroundColor Yellow
$optionalTools = @('fd', 'bat', 'delta', 'exa', 'eza')
foreach ($tool in $optionalTools) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($cmd) {
    Write-Host "   ✓ $tool found" -ForegroundColor Green
  }
  else {
    Write-Host "   - $tool not found (will test fallback behavior)" -ForegroundColor Gray
  }
}

# Validate test files exist
Write-Host "`n8. Test Files Check" -ForegroundColor Yellow
$testFiles = @(
  'tests\TestHelpers.psm1',
  'tests\Module.Tests.ps1',
  'tests\Widgets.Tests.ps1',
  'tests\Integration.Tests.ps1',
  'tests\Test-Runner.ps1'
)

$allTestFilesExist = $true
foreach ($testFile in $testFiles) {
  if (Test-Path $testFile) {
    Write-Host "   ✓ $testFile" -ForegroundColor Green
  }
  else {
    Write-Host "   ✗ $testFile missing" -ForegroundColor Red
    $allTestFilesExist = $false
  }
}

# Try running a quick test
Write-Host "`n9. Quick Test Run" -ForegroundColor Yellow
if ($allTestFilesExist) {
  try {
    # Run just the module tests as a quick validation
    $quickTest = & .\tests\Test-Runner.ps1 -TestSuite Module 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host '   ✓ Quick test run successful' -ForegroundColor Green
    }
    else {
      Write-Host '   ⚠ Quick test run had failures' -ForegroundColor Yellow
    }
  }
  catch {
    Write-Host "   ✗ Quick test run failed: $_" -ForegroundColor Red
  }
}
else {
  Write-Host '   ✗ Cannot run tests - test files missing' -ForegroundColor Red
}

# Summary
Write-Host "`n" + '='*50 -ForegroundColor Cyan
Write-Host 'VALIDATION SUMMARY' -ForegroundColor Cyan
Write-Host '='*50 -ForegroundColor Cyan

$requiredOk = $pester -and $psreadline -and $allTestFilesExist
$optionalOk = $fzf -and $python -and $git

if ($requiredOk) {
  Write-Host '✓ Required components: OK' -ForegroundColor Green
}
else {
  Write-Host '✗ Required components: MISSING' -ForegroundColor Red
}

if ($optionalOk) {
  Write-Host '✓ Optional components: OK' -ForegroundColor Green
}
else {
  Write-Host '⚠ Optional components: PARTIAL' -ForegroundColor Yellow
}

Write-Host "`nTo run tests:" -ForegroundColor Cyan
Write-Host '  .\tests\Test-Runner.ps1' -ForegroundColor Gray

if (-not $requiredOk) {
  Write-Host "`nTo install missing dependencies:" -ForegroundColor Cyan
  Write-Host '  .\tests\Validate-TestSetup.ps1 -InstallDependencies' -ForegroundColor Gray
  exit 1
}

Write-Host "`nTest setup validation complete!" -ForegroundColor Green

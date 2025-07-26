# Test runner script for fzf.pwsh module
# This script runs all test suites and provides summary reporting

param(
  [string]$TestSuite = 'All',
  [switch]$CI,
  [string]$OutputFormat = 'NUnitXml',
  [string]$OutputFile = 'TestResults.xml'
)

# Ensure Pester is available
if (-not (Get-Module -ListAvailable -Name Pester)) {
  Write-Warning 'Pester module is required for testing. Install with: Install-Module Pester -Force'
  if ($CI) {
    exit 1
  }
  return
}

# Import Pester
Import-Module Pester -Force

# Define test suites
$testSuites = @{
  'Module'      = 'Module.Tests.ps1'
  'Widgets'     = 'Widgets.Tests.ps1' 
  'Integration' = 'Integration.Tests.ps1'
  'All'         = @('Module.Tests.ps1', 'Widgets.Tests.ps1', 'Integration.Tests.ps1')
}

# Get the tests directory
$testsDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine which tests to run
$testsToRun = if ($TestSuite -eq 'All') {
  $testSuites['All'] | ForEach-Object { Join-Path $testsDir $_ }
}
elseif ($testSuites.ContainsKey($TestSuite)) {
  if ($testSuites[$TestSuite] -is [array]) {
    $testSuites[$TestSuite] | ForEach-Object { Join-Path $testsDir $_ }
  }
  else {
    @(Join-Path $testsDir $testSuites[$TestSuite])
  }
}
else {
  Write-Error "Unknown test suite: $TestSuite. Available: $($testSuites.Keys -join ', ')"
  if ($CI) {
    exit 1
  }
  return
}

# Verify test files exist
foreach ($testFile in $testsToRun) {
  if (-not (Test-Path $testFile)) {
    Write-Error "Test file not found: $testFile"
    if ($CI) {
      exit 1
    }
    return
  }
}

Write-Host 'Running fzf.pwsh tests...' -ForegroundColor Cyan
Write-Host "Test suite: $TestSuite" -ForegroundColor Gray
Write-Host "Tests to run: $($testsToRun.Count)" -ForegroundColor Gray
Write-Host ''

# Check Pester version and configure accordingly
$pesterVersion = (Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1).Version

if ($pesterVersion.Major -ge 5) {
  # Pester v5+ configuration
  $pesterConfig = New-PesterConfiguration
  $pesterConfig.Run.Path = $testsToRun
  $pesterConfig.TestResult.Enabled = $true
  $pesterConfig.TestResult.OutputFormat = $OutputFormat
  $pesterConfig.TestResult.OutputPath = $OutputFile
  $pesterConfig.Output.Verbosity = if ($CI) { 'Detailed' } else { 'Normal' }
    
  # Run tests
  $testResult = Invoke-Pester -Configuration $pesterConfig
}
else {
  # Pester v4 configuration
  $pesterParams = @{
    Script       = $testsToRun
    OutputFile   = $OutputFile
    OutputFormat = $OutputFormat
    PassThru     = $true
  }
    
  if ($CI) {
    $pesterParams.Verbose = $true
  }
    
  # Run tests
  $testResult = Invoke-Pester @pesterParams
}

# Report results
Write-Host ''
Write-Host 'Test Results Summary:' -ForegroundColor Cyan

if ($pesterVersion.Major -ge 5) {
  # Pester v5+ result format
  Write-Host "  Total Tests: $($testResult.TotalCount)" -ForegroundColor Gray
  Write-Host "  Passed: $($testResult.PassedCount)" -ForegroundColor Green
  Write-Host "  Failed: $($testResult.FailedCount)" -ForegroundColor Red
  Write-Host "  Skipped: $($testResult.SkippedCount)" -ForegroundColor Yellow
  Write-Host "  Duration: $($testResult.Duration)" -ForegroundColor Gray
    
  $failedCount = $testResult.FailedCount
  $failedTests = $testResult.Failed
}
else {
  # Pester v4 result format
  Write-Host "  Total Tests: $($testResult.TotalCount)" -ForegroundColor Gray
  Write-Host "  Passed: $($testResult.PassedCount)" -ForegroundColor Green
  Write-Host "  Failed: $($testResult.FailedCount)" -ForegroundColor Red
  Write-Host "  Skipped: $($testResult.SkippedCount)" -ForegroundColor Yellow
  Write-Host "  Duration: $($testResult.Time)" -ForegroundColor Gray
    
  $failedCount = $testResult.FailedCount
  $failedTests = $testResult.TestResult | Where-Object { $_.Result -eq 'Failed' }
}

if ($failedCount -gt 0) {
  Write-Host ''
  Write-Host 'Failed Tests:' -ForegroundColor Red
  foreach ($failedTest in $failedTests) {
    if ($pesterVersion.Major -ge 5) {
      Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
      if ($failedTest.ErrorRecord) {
        Write-Host "    Error: $($failedTest.ErrorRecord.Exception.Message)" -ForegroundColor DarkRed
      }
    }
    else {
      Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
      if ($failedTest.FailureMessage) {
        Write-Host "    Error: $($failedTest.FailureMessage)" -ForegroundColor DarkRed
      }
    }
  }
}

if ($CI) {
  # In CI mode, exit with error code if tests failed
  exit $failedCount
}

return $testResult

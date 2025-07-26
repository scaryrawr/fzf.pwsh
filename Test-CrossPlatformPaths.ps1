# Test script to verify cross-platform path handling fixes

# Test the cross-platform directory separator regex
$testPath = "test\.git\subdir"
$crossPlatformPattern = "\.git$([regex]::Escape([System.IO.Path]::DirectorySeparatorChar))"
Write-Host "Testing directory separator pattern:"
Write-Host "Pattern: $crossPlatformPattern"
Write-Host "Test path: $testPath"
Write-Host "Matches: $($testPath -match $crossPlatformPattern)"

# Test relative path calculation
$currentDir = $PWD.Path
$testFilePath = Join-Path $currentDir "widgets" "fzf-file-widget.ps1"
if (Test-Path $testFilePath) {
    $relativePath = [System.IO.Path]::GetRelativePath($currentDir, $testFilePath)
    Write-Host "`nTesting relative path calculation:"
    Write-Host "Full path: $testFilePath"
    Write-Host "Relative path: $relativePath"
}

# Test temp directory detection
$tempBase = if ($env:TEMP -and (Test-Path $env:TEMP)) {
    $env:TEMP
} elseif ($env:TMPDIR -and (Test-Path $env:TMPDIR)) {
    $env:TMPDIR.TrimEnd('/')
} elseif (Test-Path '/tmp') {
    '/tmp'
} else {
    $PWD.Path
}
Write-Host "`nTesting temp directory detection:"
Write-Host "Detected temp directory: $tempBase"

# Test safe directory name creation
$safeDirName = $PWD.Path -replace '[\\/:]', '_'
Write-Host "`nTesting safe directory name creation:"
Write-Host "Original path: $($PWD.Path)"
Write-Host "Safe name: $safeDirName"

Write-Host "`n✓ All cross-platform path tests completed!"

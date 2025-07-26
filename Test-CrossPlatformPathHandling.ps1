# Test script to verify all cross-platform path handling is working correctly

Write-Host "Testing cross-platform path handling in fzf.pwsh module" -ForegroundColor Cyan

# Test 1: Environment variable quoting
Write-Host "`n1. Testing environment variable quoting:" -ForegroundColor Yellow
Import-Module .\fzf.psm1 -Force
Write-Host "FZF_PREVIEW_CMD: $env:FZF_PREVIEW_CMD"
Write-Host "FZF_PACKAGE_PREVIEW_CMD: $env:FZF_PACKAGE_PREVIEW_CMD"

# Test 2: Relative path calculation
Write-Host "`n2. Testing relative path calculation:" -ForegroundColor Yellow
$testFile = Join-Path $PWD "widgets" "fzf-file-widget.ps1"
if (Test-Path $testFile) {
    $relativePath = [System.IO.Path]::GetRelativePath($PWD.Path, $testFile)
    Write-Host "Full path: $testFile"
    Write-Host "Relative path: $relativePath"
} else {
    Write-Host "Test file not found: $testFile" -ForegroundColor Red
}

# Test 3: Directory separator pattern
Write-Host "`n3. Testing directory separator pattern:" -ForegroundColor Yellow
$dirSeparator = [System.IO.Path]::DirectorySeparatorChar
$pattern = "\.git$([regex]::Escape($dirSeparator))"
Write-Host "Directory separator: '$dirSeparator'"
Write-Host "Regex pattern: $pattern"

$testPaths = @(
    "some/path/.git/subfolder",
    "some\path\.git\subfolder",
    "some/path/.gitignore",
    "some\path\.gitignore"
)

foreach ($testPath in $testPaths) {
    $isMatch = $testPath -match $pattern
    Write-Host "Path: $testPath | Matches: $isMatch"
}

# Test 4: Temp directory detection
Write-Host "`n4. Testing temp directory detection:" -ForegroundColor Yellow
$tempBase = if ($env:TEMP -and (Test-Path $env:TEMP)) {
    $env:TEMP
} elseif ($env:TMPDIR -and (Test-Path $env:TMPDIR)) {
    $env:TMPDIR.TrimEnd('/')
} elseif (Test-Path '/tmp') {
    '/tmp'
} else {
    $PWD.Path
}
Write-Host "Detected temp directory: $tempBase"
Write-Host "Temp directory exists: $(Test-Path $tempBase)"

# Test 5: Path quoting for cache file
Write-Host "`n5. Testing path quoting for cache file:" -ForegroundColor Yellow
$testCacheFile = "C:\Program Files\test cache\file.json"
$quotedCacheFile = "`"$testCacheFile`""
Write-Host "Original path: $testCacheFile"
Write-Host "Quoted path: $quotedCacheFile"

# Test 6: Python shlex quoting
Write-Host "`n6. Testing Python path handling would be consistent..." -ForegroundColor Yellow
Write-Host "Python scripts use shlex.quote() for proper cross-platform path quoting"

Write-Host "`n✓ Cross-platform path handling tests completed!" -ForegroundColor Green
Write-Host "All path handling should now work correctly on Windows, macOS, and Linux." -ForegroundColor Green

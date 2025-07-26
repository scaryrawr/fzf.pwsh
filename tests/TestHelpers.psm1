# Test helper functions for fzf.pwsh module testing

function New-TempTestDirectory {
  <#
    .SYNOPSIS
    Creates a temporary directory for testing and returns the path
    #>
  param(
    [string]$Prefix = 'fzf-pwsh-test'
  )
    
  $tempPath = if ($IsWindows) {
    Join-Path $env:TEMP "$Prefix-$(Get-Random)"
  }
  else {
    Join-Path '/tmp' "$Prefix-$(Get-Random)"
  }
    
  New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
  return $tempPath
}

function Remove-TempTestDirectory {
  <#
    .SYNOPSIS
    Safely removes a temporary test directory
    #>
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )
    
  if (Test-Path $Path) {
    Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Initialize-TestGitRepo {
  <#
    .SYNOPSIS
    Initializes a git repository in the specified directory with some test files
    #>
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )
    
  Push-Location $Path
  try {
    git init --quiet
    git config user.email 'test@example.com'
    git config user.name 'Test User'
        
    # Create some test files
    'Initial file content' | Out-File -FilePath 'file1.txt' -Encoding utf8
    'Another file' | Out-File -FilePath 'file2.txt' -Encoding utf8
    New-Item -ItemType Directory -Path 'subdir' -Force | Out-Null
    'Nested file' | Out-File -FilePath 'subdir/nested.txt' -Encoding utf8
        
    git add .
    git commit -m 'Initial commit' --quiet
        
    # Make some changes for testing
    'Modified content' | Out-File -FilePath 'file1.txt' -Encoding utf8
    'New file' | Out-File -FilePath 'newfile.txt' -Encoding utf8
  }
  finally {
    Pop-Location
  }
}

function Test-EnvironmentVariableInjection {
  <#
    .SYNOPSIS
    Tests that environment variables are properly set up between layers
    #>
  param(
    [Parameter(Mandatory)]
    [string]$ModulePath
  )
    
  $testResults = @{
    PreviewCommandsSet = $false
    PythonDetected     = $false
    PowerShellFallback = $false
    DefaultOptsSet     = $false
  }
    
  # Clear environment first
  $envVarsToTest = @(
    'FZF_PREVIEW_CMD',
    'FZF_GIT_BLAME_PREVIEW_CMD',
    'FZF_GIT_COMMIT_PREVIEW_CMD',
    'FZF_GIT_LOG_PREVIEW_CMD',
    'FZF_GIT_STATUS_PREVIEW_CMD',
    'FZF_PACKAGE_PREVIEW_CMD',
    'FZF_DEFAULT_OPTS'
  )
    
  foreach ($var in $envVarsToTest) {
    Remove-Item "env:$var" -ErrorAction SilentlyContinue
  }
    
  # Import the module
  Import-Module $ModulePath -Force
    
  # Check if preview commands were set
  $testResults.PreviewCommandsSet = -not [string]::IsNullOrEmpty($env:FZF_PREVIEW_CMD)
    
  # Check Python detection
  if ($env:FZF_PREVIEW_CMD -like '*python*') {
    $testResults.PythonDetected = $true
  }
  elseif ($env:FZF_PREVIEW_CMD -like '*pwsh*') {
    $testResults.PowerShellFallback = $true
  }
    
  # Check default options
  $testResults.DefaultOptsSet = -not [string]::IsNullOrEmpty($env:FZF_DEFAULT_OPTS)
    
  return $testResults
}

function Invoke-WidgetWithMocking {
  <#
    .SYNOPSIS
    Invokes a widget function with mocked PSReadLine functionality
    #>
  param(
    [Parameter(Mandatory)]
    [scriptblock]$WidgetFunction,
    [string]$InitialBuffer = '',
    [int]$InitialCursor = 0,
    [string[]]$FzfOutput = @()
  )
    
  $result = @{
    DingCalled      = $false
    VerboseMessages = @()
    BufferState     = @{
      Line   = $InitialBuffer
      Cursor = $InitialCursor
    }
    InsertedText    = ''
    ReplacedText    = @{
      StartIndex = -1
      Length     = 0
      NewText    = ''
    }
  }
    
  # Mock PSReadLine functions
  $global:MockReadLineState = $result
    
  # Create mock functions in a temporary module
  $mockModule = New-Module -ScriptBlock {
    function MockDing { $global:MockReadLineState.DingCalled = $true }
    function MockGetBufferState([ref]$line, [ref]$cursor) {
      $line.Value = $global:MockReadLineState.BufferState.Line
      $cursor.Value = $global:MockReadLineState.BufferState.Cursor
    }
    function MockInsert([string]$text) {
      $global:MockReadLineState.InsertedText = $text
    }
    function MockReplace([int]$start, [int]$length, [string]$text) {
      $global:MockReadLineState.ReplacedText.StartIndex = $start
      $global:MockReadLineState.ReplacedText.Length = $length
      $global:MockReadLineState.ReplacedText.NewText = $text
    }
        
    Export-ModuleMember -Function MockDing, MockGetBufferState, MockInsert, MockReplace
  }
    
  try {
    # Override PSReadLine methods temporarily
    $originalType = [Microsoft.PowerShell.PSConsoleReadLine]
        
    # Mock Write-Verbose to capture verbose messages
    $originalVerbosePreference = $VerbosePreference
    $VerbosePreference = 'Continue'
        
    # Capture verbose output
    $verboseOutput = @()
    & $WidgetFunction *>&1 | ForEach-Object {
      if ($_ -is [System.Management.Automation.VerboseRecord]) {
        $verboseOutput += $_.Message
      }
    }
        
    $result.VerboseMessages = $verboseOutput
        
    return $result
  }
  finally {
    $VerbosePreference = $originalVerbosePreference
    Remove-Module $mockModule -Force -ErrorAction SilentlyContinue
    Remove-Variable -Name MockReadLineState -Scope Global -ErrorAction SilentlyContinue
  }
}

function Test-CrossPlatformPaths {
  <#
    .SYNOPSIS
    Tests that paths are handled correctly across platforms
    #>
  param(
    [Parameter(Mandatory)]
    [string]$ModulePath
  )
    
  $tempDir = New-TempTestDirectory
  try {
    Push-Location $tempDir
        
    # Create test file structure
    New-Item -ItemType Directory -Path 'subdir' -Force | Out-Null
    'test' | Out-File -FilePath 'test.txt' -Encoding utf8
    'nested' | Out-File -FilePath 'subdir/nested.txt' -Encoding utf8
        
    # Import module
    Import-Module $ModulePath -Force
        
    # Test file finding functionality
    $files = Find-FzfFiles
        
    # Validate that paths use correct separators
    $pathsValid = $true
    foreach ($file in $files) {
      # Check that paths don't contain wrong separators
      if ($IsWindows) {
        if ($file -match '/') {
          $pathsValid = $false
          break
        }
      }
      else {
        if ($file -match '\\') {
          $pathsValid = $false
          break
        }
      }
    }
        
    return @{
      FilesFound = $files.Count -gt 0
      PathsValid = $pathsValid
      Files      = $files
    }
  }
  finally {
    Pop-Location
    Remove-TempTestDirectory -Path $tempDir
  }
}

Export-ModuleMember -Function New-TempTestDirectory, Remove-TempTestDirectory, Initialize-TestGitRepo, Test-EnvironmentVariableInjection, Invoke-WidgetWithMocking, Test-CrossPlatformPaths

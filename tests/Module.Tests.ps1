# Unit Tests for fzf.pwsh Module - Environment Variables and Module Loading

BeforeAll {
  # Import test helpers
  Import-Module "$PSScriptRoot\TestHelpers.psm1" -Force
    
  # Store original environment state
  $script:OriginalEnvVars = @{}
  $envVarsToBackup = @(
    'FZF_PREVIEW_CMD',
    'FZF_GIT_BLAME_PREVIEW_CMD', 
    'FZF_GIT_COMMIT_PREVIEW_CMD',
    'FZF_GIT_LOG_PREVIEW_CMD',
    'FZF_GIT_STATUS_PREVIEW_CMD',
    'FZF_PACKAGE_PREVIEW_CMD',
    'FZF_DEFAULT_OPTS'
  )
    
  foreach ($var in $envVarsToBackup) {
    $script:OriginalEnvVars[$var] = Get-Item "env:$var" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
  }
    
  $script:ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'fzf.psm1'
}

AfterAll {
  # Restore original environment state
  foreach ($var in $script:OriginalEnvVars.Keys) {
    if ($script:OriginalEnvVars[$var]) {
      Set-Item "env:$var" $script:OriginalEnvVars[$var]
    }
    else {
      Remove-Item "env:$var" -ErrorAction SilentlyContinue
    }
  }
}

Describe 'Module Environment Variable Setup' {
  Context 'Environment variable setup' {
    BeforeEach {
      # Clear environment variables before each test
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
    }
    
    It 'Sets preview command environment variables when module is imported' {
      $testResults = Test-EnvironmentVariableInjection -ModulePath $script:ModulePath
        
      $testResults.PreviewCommandsSet | Should -Be $true
      $testResults.DefaultOptsSet | Should -Be $true
    }
    
    It 'Prefers Python previewers when Python is available' {
      # Only test if Python is actually available
      if (Get-Command 'python' -ErrorAction SilentlyContinue) {
        $testResults = Test-EnvironmentVariableInjection -ModulePath $script:ModulePath
        $testResults.PythonDetected | Should -Be $true
      }
      else {
        Set-ItResult -Skipped -Because 'Python not available on this system'
      }
    }
    
    It 'Falls back to PowerShell previewers when Python is not available' {
      # Temporarily hide Python from PATH
      $originalPath = $env:PATH
      try {
        # Remove Python from PATH for this test
        $pathParts = $env:PATH -split [System.IO.Path]::PathSeparator
        $filteredPath = $pathParts | Where-Object { $_ -notlike '*python*' }
        $env:PATH = $filteredPath -join [System.IO.Path]::PathSeparator
            
        $testResults = Test-EnvironmentVariableInjection -ModulePath $script:ModulePath
        $testResults.PowerShellFallback | Should -Be $true
      }
      finally {
        $env:PATH = $originalPath
      }
    }
    
    It "Respects existing environment variables (doesn't override)" {
      # Pre-set an environment variable
      $env:FZF_PREVIEW_CMD = 'custom-preview-command'
        
      Import-Module $script:ModulePath -Force
        
      $env:FZF_PREVIEW_CMD | Should -Be 'custom-preview-command'
    }
    
    It 'Sets FZF_DEFAULT_OPTS when not already set' {
      Import-Module $script:ModulePath -Force
        
      $env:FZF_DEFAULT_OPTS | Should -Not -BeNullOrEmpty
      $env:FZF_DEFAULT_OPTS | Should -Match '--ansi'
    }
    
    It 'All required preview commands are set' {
      Import-Module $script:ModulePath -Force
        
      $requiredVars = @(
        'FZF_PREVIEW_CMD',
        'FZF_GIT_BLAME_PREVIEW_CMD',
        'FZF_GIT_COMMIT_PREVIEW_CMD',
        'FZF_GIT_LOG_PREVIEW_CMD', 
        'FZF_GIT_STATUS_PREVIEW_CMD',
        'FZF_PACKAGE_PREVIEW_CMD'
      )
        
      foreach ($var in $requiredVars) {
        Get-Item "env:$var" -ErrorAction SilentlyContinue | Should -Not -BeNull -Because "$var should be set"
      }
    }
  }

  Describe 'Module Function Export' {
    BeforeAll {
      Import-Module $script:ModulePath -Force
    }
    
    It 'Exports all required functions' {
      $expectedFunctions = @(
        'Set-PsFzfKeyBindings',
        'Invoke-FzfFileWidget',
        'Invoke-FzfHistoryWidget', 
        'Invoke-FzfCdWidget',
        'Invoke-FzfGitLogWidget',
        'Invoke-FzfGitStatusWidget',
        'Invoke-FzfVariablesWidget',
        'Invoke-FzfGitBlameWidget',
        'Find-FzfFiles'
      )
        
      $module = Get-Module -name 'fzf'
      foreach ($func in $expectedFunctions) {
        $module.ExportedFunctions.Keys | Should -Contain $func
      }
    }
    
    It 'Find-FzfFiles function exists and is callable' {
      { Find-FzfFiles } | Should -Not -Throw
    }
  }

  Describe 'Cross-Platform Path Handling' {
    It 'Handles paths correctly on current platform' {
      $testResults = Test-CrossPlatformPaths -ModulePath $script:ModulePath
        
      $testResults.FilesFound | Should -Be $true
      $testResults.PathsValid | Should -Be $true
    }
    
    It 'Uses correct path separators for the platform' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
        New-Item -ItemType Directory -Path 'subdir' -Force | Out-Null
        'test' | Out-File -FilePath 'subdir/test.txt' -Encoding utf8
            
        Import-Module $script:ModulePath -Force
        $files = Find-FzfFiles
            
        # Check that relative paths are generated correctly
        $nestedFile = $files | Where-Object { $_ -like '*test.txt' }
        $nestedFile | Should -Not -BeNullOrEmpty
            
        if ($IsWindows) {
          $nestedFile | Should -Match 'subdir\\test\.txt'
        }
        else {
          $nestedFile | Should -Match 'subdir/test\.txt'
        }
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }

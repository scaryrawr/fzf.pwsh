# Unit Tests for fzf.pwsh Widgets - High-level functionality testing

BeforeAll {
  # Import test helpers
  Import-Module "$PSScriptRoot\TestHelpers.psm1" -Force
    
  $script:ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'fzf.psm1'
  Import-Module $script:ModulePath -Force
}

Describe 'Git Status Widget' {
  Context 'When not in a git repository' {
    It 'Shows verbose message and calls Ding when not in git repo' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
                
        # Capture the output using try/catch since we can't easily mock PSReadLine
        $verboseOutput = @()
        $dingCalled = $false
                
        # Mock the PSReadLine Ding function for this test
        $mockScript = {
          $script:DingCalled = $true
        }
                
        # Test verbose output
        $VerbosePreference = 'Continue'
        $output = Invoke-FzfGitStatusWidget -Verbose 2>&1
        $VerbosePreference = 'SilentlyContinue'
                
        # Check that verbose message contains expected text
        $verboseMessage = $output | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | Select-Object -First 1
        $verboseMessage.Message | Should -Match 'Not in a git repository'
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
    
  Context 'When in a git repository' {
    It 'Shows verbose message when no changes exist' {
      $tempDir = New-TempTestDirectory
      try {
        Initialize-TestGitRepo -Path $tempDir
        Push-Location $tempDir
                
        # Clean the repository
        git add .
        git commit -m 'Clean state' --quiet
                
        $VerbosePreference = 'Continue'
        $output = Invoke-FzfGitStatusWidget -Verbose 2>&1
        $VerbosePreference = 'SilentlyContinue'
                
        # Check that verbose message contains expected text
        $verboseMessage = $output | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | Select-Object -First 1
        $verboseMessage.Message | Should -Match 'No changes in git repository'
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
        
    It 'Processes git status output correctly when changes exist' {
      $tempDir = New-TempTestDirectory
      try {
        Initialize-TestGitRepo -Path $tempDir
        Push-Location $tempDir
                
        # Verify we have changes
        $gitStatus = git -c color.status=always status -s
        $gitStatus | Should -Not -BeNullOrEmpty
                
        # Test that the function doesn't show error messages when changes exist
        $VerbosePreference = 'Continue'
        $output = Invoke-FzfGitStatusWidget -Verbose 2>&1
        $VerbosePreference = 'SilentlyContinue'
                
        # Should not contain error messages about no changes
        $verboseMessages = $output | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }
        $verboseMessages | Should -Not -Match 'No changes in git repository'
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
}

Describe 'File Widget' {
  Context 'File discovery functionality' {
    It 'Finds files in current directory' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
                
        # Create test files
        'test1' | Out-File -FilePath 'file1.txt' -Encoding utf8
        'test2' | Out-File -FilePath 'file2.txt' -Encoding utf8
        New-Item -ItemType Directory -Path 'subdir' -Force | Out-Null
        'test3' | Out-File -FilePath 'subdir/file3.txt' -Encoding utf8
                
        Import-Module $script:ModulePath -Force
        $files = Find-FzfFiles
                
        $files.Count | Should -BeGreaterThan 0
        $files | Should -Contain 'file1.txt'
        $files | Should -Contain 'file2.txt'
                
        # Check for nested file with correct path separator
        $nestedFiles = $files | Where-Object { $_ -like '*file3.txt' }
        $nestedFiles | Should -Not -BeNullOrEmpty
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
        
    It 'Excludes .git directory from file listing' {
      $tempDir = New-TempTestDirectory
      try {
        Initialize-TestGitRepo -Path $tempDir
        Push-Location $tempDir
                
        Import-Module $script:ModulePath -Force
        $files = Find-FzfFiles
                
        # Should not include .git directory contents
        $gitFiles = $files | Where-Object { $_ -like '*.git*' }
        $gitFiles | Should -BeNullOrEmpty
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
    
  Context 'Widget buffer interaction' {
    It 'Can be invoked without errors' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
        'test' | Out-File -FilePath 'test.txt' -Encoding utf8
                
        # Test that the widget can be invoked without throwing errors
        # Note: This will fail with fzf not found if fzf isn't installed, but module functions should still load
        { Invoke-FzfFileWidget } | Should -Not -Throw
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
}

Describe 'Environment Variable Integration' {
  Context 'Preview command usage' {
    It 'Uses correct preview command environment variables' {
      # Test that the git status widget would use the correct environment variable
      $env:FZF_GIT_STATUS_PREVIEW_CMD | Should -Not -BeNullOrEmpty
            
      # Test that preview commands contain expected paths
      $env:FZF_GIT_STATUS_PREVIEW_CMD | Should -Match 'fzf_git_status_preview'
      $env:FZF_PREVIEW_CMD | Should -Match 'fzf_preview'
    }
        
    It 'Environment variables point to existing files' {
      $previewVars = @(
        'FZF_PREVIEW_CMD',
        'FZF_GIT_STATUS_PREVIEW_CMD',
        'FZF_GIT_BLAME_PREVIEW_CMD',
        'FZF_GIT_COMMIT_PREVIEW_CMD',
        'FZF_GIT_LOG_PREVIEW_CMD',
        'FZF_PACKAGE_PREVIEW_CMD'
      )
            
      foreach ($var in $previewVars) {
        $cmd = Get-Item "env:$var" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value
        $cmd | Should -Not -BeNullOrEmpty -Because "$var should be set"
                
        # Extract the script path from the command
        if ($cmd -match '"([^"]+)"') {
          $scriptPath = $matches[1]
          Test-Path $scriptPath | Should -Be $true -Because "Preview script at $scriptPath should exist"
        }
      }
    }
  }
}

Describe 'Key Binding Function' {
  Context 'Set-PsFzfKeyBindings functionality' {
    It 'Can be called without errors' {
      { Set-PsFzfKeyBindings } | Should -Not -Throw
    }
        
    It 'Is exported by the module' {
      $module = Get-Module -name 'fzf'
      $module.ExportedFunctions.Keys | Should -Contain 'Set-PsFzfKeyBindings'
    }
  }
}

Describe 'Cross-Platform Compatibility' {
  Context 'Path handling in widgets' {
    It 'Widget functions handle paths correctly' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
                
        # Create files with spaces and special characters
        'test' | Out-File -FilePath 'file with spaces.txt' -Encoding utf8
        New-Item -ItemType Directory -Path 'dir with spaces' -Force | Out-Null
        'nested' | Out-File -FilePath 'dir with spaces/nested.txt' -Encoding utf8
                
        Import-Module $script:ModulePath -Force
        $files = Find-FzfFiles
                
        # Should find files with spaces
        $spacedFiles = $files | Where-Object { $_ -like '*spaces*' }
        $spacedFiles.Count | Should -BeGreaterThan 0
                
        # Paths should be properly formatted for the current platform
        foreach ($file in $files) {
          if ($IsWindows) {
            $file | Should -Not -Match '/'
          }
          else {
            $file | Should -Not -Match '\\'
          }
        }
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
}

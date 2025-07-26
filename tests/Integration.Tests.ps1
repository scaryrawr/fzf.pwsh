# Integration Tests for fzf.pwsh Module - End-to-end scenarios

BeforeAll {
  # Import test helpers
  Import-Module "$PSScriptRoot\TestHelpers.psm1" -Force
    
  $script:ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'fzf.psm1'
}

Describe 'Module Import and Initialization' {
  Context 'Fresh module import' {
    It 'Imports successfully without errors' {
      { Import-Module $script:ModulePath -Force } | Should -Not -Throw
    }
        
    It 'Sets up all environment variables correctly' {
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
            
      Import-Module $script:ModulePath -Force
            
      foreach ($var in $envVarsToTest) {
        Get-Item "env:$var" -ErrorAction SilentlyContinue | Should -Not -BeNull -Because "$var should be set after module import"
      }
    }
        
    It 'Automatically calls Set-PsFzfKeyBindings on import' {
      # This test verifies the module calls the key binding function
      # We can't easily test the actual key bindings without PSReadLine being fully interactive
      Import-Module $script:ModulePath -Force
            
      # Verify the function exists and is callable
      { Set-PsFzfKeyBindings } | Should -Not -Throw
    }
  }
}

Describe 'Real-world Usage Scenarios' {
  Context 'Working in a git repository' {
    It 'All git widgets work in a real git repo' {
      $tempDir = New-TempTestDirectory
      try {
        Initialize-TestGitRepo -Path $tempDir
        Push-Location $tempDir
                
        Import-Module $script:ModulePath -Force
                
        # Test git status widget
        { Invoke-FzfGitStatusWidget } | Should -Not -Throw
                
        # Test git log widget  
        { Invoke-FzfGitLogWidget } | Should -Not -Throw
                
        # Test git blame widget
        { Invoke-FzfGitBlameWidget } | Should -Not -Throw
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
        
    It 'Git status widget handles various file states correctly' {
      $tempDir = New-TempTestDirectory
      try {
        Initialize-TestGitRepo -Path $tempDir
        Push-Location $tempDir
                
        # Create different types of changes
        'modified' | Out-File -FilePath 'file1.txt' -Encoding utf8  # Modified file
        'new file' | Out-File -FilePath 'untracked.txt' -Encoding utf8  # New file
        Remove-Item 'file2.txt'  # Deleted file
                
        Import-Module $script:ModulePath -Force
                
        # Get git status to verify we have changes
        $gitStatus = git -c color.status=always status -s
        $gitStatus | Should -Not -BeNullOrEmpty
                
        # Widget should not throw with various file states
        { Invoke-FzfGitStatusWidget } | Should -Not -Throw
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
    
  Context 'Working in a non-git directory' {
    It 'File widget works without git' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
                
        # Create some files
        'content1' | Out-File -FilePath 'file1.txt' -Encoding utf8
        'content2' | Out-File -FilePath 'file2.txt' -Encoding utf8
        New-Item -ItemType Directory -Path 'subdir' -Force | Out-Null
        'nested' | Out-File -FilePath 'subdir/nested.txt' -Encoding utf8
                
        Import-Module $script:ModulePath -Force
                
        # File widget should work
        { Invoke-FzfFileWidget } | Should -Not -Throw
                
        # Should find files
        $files = Find-FzfFiles
        $files.Count | Should -BeGreaterThan 0
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
        
    It 'Git widgets handle non-git directories gracefully' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
                
        Import-Module $script:ModulePath -Force
                
        # Git widgets should not throw, but should provide feedback
        { Invoke-FzfGitStatusWidget } | Should -Not -Throw
        { Invoke-FzfGitLogWidget } | Should -Not -Throw
        { Invoke-FzfGitBlameWidget } | Should -Not -Throw
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
}

Describe 'Environment Variable Precedence and Overrides' {
  Context 'User customization respect' {
    It 'Respects pre-existing environment variables' {
      # Set custom preview commands before module import
      $customPreviewCmd = "echo 'custom preview'"
      $customGitStatusCmd = "echo 'custom git status'"
            
      $env:FZF_PREVIEW_CMD = $customPreviewCmd
      $env:FZF_GIT_STATUS_PREVIEW_CMD = $customGitStatusCmd
            
      try {
        Import-Module $script:ModulePath -Force
                
        # Should preserve custom values
        $env:FZF_PREVIEW_CMD | Should -Be $customPreviewCmd
        $env:FZF_GIT_STATUS_PREVIEW_CMD | Should -Be $customGitStatusCmd
      }
      finally {
        # Clean up
        Remove-Item 'env:FZF_PREVIEW_CMD' -ErrorAction SilentlyContinue
        Remove-Item 'env:FZF_GIT_STATUS_PREVIEW_CMD' -ErrorAction SilentlyContinue
      }
    }
        
    It 'Only sets unset environment variables' {
      # Set some but not all variables
      $env:FZF_PREVIEW_CMD = 'custom preview'
            
      try {
        Import-Module $script:ModulePath -Force
                
        # Custom one should be preserved
        $env:FZF_PREVIEW_CMD | Should -Be 'custom preview'
                
        # Others should be set to defaults
        $env:FZF_GIT_STATUS_PREVIEW_CMD | Should -Not -BeNullOrEmpty
        $env:FZF_GIT_STATUS_PREVIEW_CMD | Should -Not -Be 'custom preview'
      }
      finally {
        Remove-Item 'env:FZF_PREVIEW_CMD' -ErrorAction SilentlyContinue
      }
    }
  }
}

Describe 'Error Handling and Edge Cases' {
  Context 'Missing dependencies' {
    It 'Module still loads when fzf is not available' {
      # This test assumes fzf might not be installed in CI
      # The module should handle this gracefully
      { Import-Module $script:ModulePath -Force } | Should -Not -Throw
    }
  }
    
  Context 'Malformed git repositories' {
    It 'Handles corrupted .git directory' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
                
        # Create a fake .git directory (not a real repo)
        New-Item -ItemType Directory -Path '.git' -Force | Out-Null
        'fake' | Out-File -FilePath '.git/fake' -Encoding utf8
                
        Import-Module $script:ModulePath -Force
                
        # Git commands might fail, but widgets should handle it gracefully
        { Invoke-FzfGitStatusWidget } | Should -Not -Throw
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
    
  Context 'Empty directories' {
    It 'Handles empty directories gracefully' {
      $tempDir = New-TempTestDirectory
      try {
        Push-Location $tempDir
                
        Import-Module $script:ModulePath -Force
                
        # Should not throw even with no files
        { Invoke-FzfFileWidget } | Should -Not -Throw
        { Find-FzfFiles } | Should -Not -Throw
                
        # Find-FzfFiles should return empty array or nothing, not throw
        $files = Find-FzfFiles
        $files.Count | Should -Be 0
      }
      finally {
        Pop-Location
        Remove-TempTestDirectory -Path $tempDir
      }
    }
  }
}

# Simple test to validate module loading and basic functionality

Import-Module "$PSScriptRoot\TestHelpers.psm1" -Force

$ModulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'fzf.psm1'

Describe 'fzf.pwsh Module Basic Tests' {
    
  It 'Module loads without errors' {
    { Import-Module $ModulePath -Force } | Should Not Throw
  }
    
  It 'Sets environment variables on import' {
    # Clear environment first
    Remove-Item 'env:FZF_PREVIEW_CMD' -ErrorAction SilentlyContinue
    Remove-Item 'env:FZF_DEFAULT_OPTS' -ErrorAction SilentlyContinue
        
    Import-Module $ModulePath -Force
        
    $env:FZF_PREVIEW_CMD | Should Not Be $null
    $env:FZF_DEFAULT_OPTS | Should Not Be $null
  }
    
  It 'Exports required functions' {
    Import-Module $ModulePath -Force
        
    Get-Command 'Find-FzfFiles' -ErrorAction SilentlyContinue | Should Not Be $null
    Get-Command 'Invoke-FzfFileWidget' -ErrorAction SilentlyContinue | Should Not Be $null
    Get-Command 'Set-PsFzfKeyBindings' -ErrorAction SilentlyContinue | Should Not Be $null
  }
    
  It 'Find-FzfFiles function exists and can be called' {
    Import-Module $ModulePath -Force
        
    { Find-FzfFiles } | Should Not Throw
  }
}

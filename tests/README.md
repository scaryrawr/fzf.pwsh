# Testing Documentation

This directory contains the test suite for the fzf.pwsh module. The tests are designed to validate high-level functionality and integration between components rather than testing internal implementation details.

## Test Structure

### Test Files

- **`Module.Tests.ps1`** - Tests module loading, environment variable setup, and exported functions
- **`Widgets.Tests.ps1`** - Tests widget functionality, git integration, and cross-platform compatibility  
- **`Integration.Tests.ps1`** - End-to-end scenarios and real-world usage patterns
- **`TestHelpers.psm1`** - Shared utility functions for creating test environments and mocking

### Test Runner

- **`Test-Runner.ps1`** - Main test runner script with options for different test suites

## Running Tests

### Local Development

```powershell
# Run all tests
.\tests\Test-Runner.ps1

# Run specific test suite
.\tests\Test-Runner.ps1 -TestSuite Module
.\tests\Test-Runner.ps1 -TestSuite Widgets
.\tests\Test-Runner.ps1 -TestSuite Integration

# Run in CI mode (exits with error code on failure)
.\tests\Test-Runner.ps1 -CI
```

### Prerequisites

The tests require:
- **Pester** - PowerShell testing framework
- **PSReadLine** - For key binding functionality
- **fzf** - The fuzzy finder tool (tests will skip if not available)

Optional dependencies that enhance test coverage:
- **Python** - For testing Python preview script selection
- **Git** - For git-related widget testing
- **fd**, **bat**, **delta** - For enhanced tool integration testing

### Test Philosophy

These tests focus on:

1. **Environment Variable Injection** - Ensuring preview commands and settings are properly configured
2. **Cross-Platform Compatibility** - Validating path handling works on Windows, Linux, and macOS
3. **Widget Behavior** - Testing high-level widget functionality without mocking internal implementation
4. **Error Handling** - Ensuring graceful degradation when dependencies are missing
5. **Real-World Scenarios** - Testing actual usage patterns in git repos and file systems

### Test Environment Management

Tests create temporary directories for isolated testing:

- Each test creates its own temp directory using `New-TempTestDirectory`
- Git repositories are initialized with `Initialize-TestGitRepo` when needed
- All temp directories are cleaned up automatically after tests complete
- Tests never modify the actual workspace or user environment

### GitHub Workflows

The project includes two GitHub Actions workflows:

#### **test.yml** - Multi-platform Testing
- Runs on Windows, Ubuntu, and macOS
- Installs all dependencies including fzf, Python, and optional tools
- Executes full test suite
- Uploads test results as artifacts
- Publishes test reports

#### **code-quality.yml** - Code Analysis
- Runs PSScriptAnalyzer for PowerShell best practices
- Validates module manifest
- Tests module import functionality
- Checks for common issues like hardcoded paths

## Writing New Tests

### Guidelines

1. **Use temporary directories** - Never test in the actual workspace
2. **Test behavior, not implementation** - Focus on what the module does, not how
3. **Handle missing dependencies gracefully** - Skip tests if optional tools aren't available
4. **Cross-platform awareness** - Use path helpers and test on multiple platforms
5. **Descriptive test names** - Clearly describe what scenario is being tested

### Example Test Pattern

```powershell
Describe "Widget Name" {
    Context "When in specific scenario" {
        It "Should behave in expected way" {
            $tempDir = New-TempTestDirectory
            try {
                Push-Location $tempDir
                # Set up test scenario
                # Execute function
                # Assert expected behavior
            }
            finally {
                Pop-Location
                Remove-TempTestDirectory -Path $tempDir
            }
        }
    }
}
```

### Test Helpers

The `TestHelpers.psm1` module provides utilities for:

- **`New-TempTestDirectory`** - Create isolated test directory
- **`Remove-TempTestDirectory`** - Clean up test directory
- **`Initialize-TestGitRepo`** - Set up git repo with test files
- **`Test-EnvironmentVariableInjection`** - Validate environment setup
- **`Test-CrossPlatformPaths`** - Validate path handling

## Continuous Integration

The tests run automatically on:
- Push to main or develop branches
- Pull requests to main or develop branches
- Multiple operating systems (Windows, Ubuntu, macOS)

Test failures will block PR merging, ensuring code quality and compatibility.

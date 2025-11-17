# Contributing to PSFFmpeg

Thank you for your interest in contributing to PSFFmpeg! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check the [issue tracker](https://github.com/adilio/psffmpeg/issues) to see if it's already reported
2. If not, create a new issue with:
   - Clear, descriptive title
   - Detailed description of the problem or feature
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - PowerShell version and FFmpeg version
   - Example code (if applicable)

### Submitting Changes

1. **Fork the Repository**
   ```bash
   git clone https://github.com/adilio/psffmpeg.git
   cd psffmpeg
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow the coding standards (see below)
   - Add tests for new functionality
   - Update documentation as needed

4. **Test Your Changes**
   ```powershell
   # Run all tests
   Invoke-Pester -Path ./Tests/

   # Test your specific changes
   Invoke-Pester -Path ./Tests/PSFFmpeg.Tests.ps1 -Tag YourFeature
   ```

5. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```

6. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill out the PR template with:
     - Description of changes
     - Related issue numbers
     - Testing performed
     - Breaking changes (if any)

## Coding Standards

### PowerShell Style Guidelines

1. **Function Names**
   - Use approved PowerShell verbs (Get, Set, New, Remove, etc.)
   - Use PascalCase for function names
   - Be descriptive: `Get-MediaInfo` not `GetInfo`

2. **Parameter Names**
   - Use PascalCase for parameter names
   - Use singular nouns for single values
   - Use plural nouns for arrays/collections
   - Add proper parameter validation

3. **Comment-Based Help**
   - All public functions must have complete comment-based help
   - Include: Synopsis, Description, Parameters, Examples, Outputs
   - Example:
     ```powershell
     <#
     .SYNOPSIS
         Brief description of the function

     .DESCRIPTION
         Detailed description of what the function does

     .PARAMETER ParameterName
         Description of the parameter

     .EXAMPLE
         Example-Function -Parameter "value"
         Description of what this example does

     .OUTPUTS
         Type of output returned
     #>
     ```

4. **Code Formatting**
   - Use 4 spaces for indentation (no tabs)
   - Place opening braces on the same line
   - Use meaningful variable names
   - Keep functions focused and concise
   - Limit line length to 120 characters when possible

5. **Error Handling**
   - Use proper error handling with try/catch blocks
   - Provide meaningful error messages
   - Use `Write-Error` for errors
   - Use `Write-Warning` for warnings
   - Use `Write-Verbose` for detailed operation info

6. **Example Function Template**
   ```powershell
   function Verb-Noun {
       <#
       .SYNOPSIS
           Brief description

       .DESCRIPTION
           Detailed description

       .PARAMETER InputPath
           Description of input path

       .EXAMPLE
           Verb-Noun -InputPath "file.mp4"
           Description of example

       .OUTPUTS
           System.IO.FileInfo
       #>
       [CmdletBinding(SupportsShouldProcess = $true)]
       [OutputType([System.IO.FileInfo])]
       param(
           [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
           [ValidateScript({ Test-Path $_ })]
           [string]$InputPath,

           [Parameter()]
           [switch]$Force
       )

       begin {
           if (-not (Test-FFmpegInstalled)) {
               throw "FFmpeg is not installed"
           }
       }

       process {
           try {
               # Function logic here
               Write-Verbose "Processing: $InputPath"

               if ($PSCmdlet.ShouldProcess($InputPath, "Perform action")) {
                   # Perform action
               }
           }
           catch {
               Write-Error "Failed to process '$InputPath': $_"
           }
       }
   }
   ```

## Testing Requirements

### Unit Tests

All new functions must have corresponding Pester tests:

1. **Test Structure**
   ```powershell
   Describe 'Function-Name' {
       Context 'Scenario 1' {
           It 'Should do something' {
               # Test code
               $result = Function-Name -Parameter "value"
               $result | Should -Not -BeNullOrEmpty
           }
       }
   }
   ```

2. **Test Coverage**
   - Test happy path (normal execution)
   - Test error conditions
   - Test edge cases
   - Test parameter validation
   - Test pipeline input
   - Mock external dependencies (FFmpeg calls)

3. **Test File Location**
   - Unit tests: `Tests/PSFFmpeg.Tests.ps1`
   - Integration tests: `Tests/Integration.Tests.ps1`

### Integration Tests

For features that interact with FFmpeg:

1. Create integration tests that use real FFmpeg operations
2. Mark them with `-Tag 'Integration'`
3. Ensure they can be skipped if FFmpeg is not installed
4. Clean up any generated files after tests

## Documentation

### When to Update Documentation

Update documentation when:
- Adding new cmdlets
- Changing cmdlet parameters
- Modifying behavior
- Adding new features
- Fixing bugs that affect usage

### What to Update

1. **README.md**
   - Add new cmdlets to the cmdlet list
   - Add usage examples
   - Update feature list if needed

2. **Comment-Based Help**
   - Update function documentation
   - Add new examples
   - Document new parameters

3. **Examples**
   - Add examples to `Examples/BasicUsage.ps1`
   - Create new example files for complex scenarios

4. **CHANGELOG.md**
   - Add entry under "Unreleased" section
   - Follow the format: `- [Added/Changed/Fixed] Description`

## Pull Request Guidelines

### Before Submitting

- [ ] All tests pass locally
- [ ] New tests added for new functionality
- [ ] Documentation updated
- [ ] Code follows style guidelines
- [ ] Commit messages are clear and descriptive
- [ ] No unnecessary changes (whitespace, formatting)

### PR Description Template

```markdown
## Description
Brief description of what this PR does

## Related Issue
Fixes #123

## Changes Made
- Added new cmdlet: `Verb-Noun`
- Updated documentation
- Added tests

## Testing Performed
- Unit tests: Pass
- Integration tests: Pass
- Manual testing: Describe what you tested

## Breaking Changes
None / List any breaking changes

## Screenshots (if applicable)
Add screenshots of new features or changes
```

## Development Setup

### Prerequisites

```powershell
# Install Pester (testing framework)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Install PSScriptAnalyzer (linting)
Install-Module -Name PSScriptAnalyzer -Force
```

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path ./Tests/

# Run with coverage
Invoke-Pester -Path ./Tests/ -CodeCoverage ./PSFFmpeg/**/*.ps1

# Run specific test
Invoke-Pester -Path ./Tests/PSFFmpeg.Tests.ps1 -Tag 'Get-MediaInfo'
```

### Code Analysis

```powershell
# Analyze code for issues
Invoke-ScriptAnalyzer -Path ./PSFFmpeg/ -Recurse
```

## Release Process

Releases are managed by project maintainers:

1. Update version in `PSFFmpeg.psd1`
2. Update `CHANGELOG.md` with version number and date
3. Create git tag: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. Create GitHub release with release notes

## Questions?

If you have questions about contributing:

- Open an issue with the "question" label
- Check existing issues and discussions
- Review the README and documentation

## License

By contributing to PSFFmpeg, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing to PSFFmpeg!

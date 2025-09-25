# Copilot Instructions — PowerShell Scripts Repository

## Repository Overview
This repository contains a collection of useful PowerShell scripts designed for Windows environments. The scripts are intended to be placed in `%userprofile%\Documents\PowerShell\Scripts` which is automatically included in the PATH for PowerShell sessions.

## Key Architecture and Patterns

### Script Location and Execution
- **Default installation path**: `%userprofile%\Documents\PowerShell\Scripts` (automatically in PATH)
- **Execution**: Scripts can be run directly by name without path qualification
- **PowerShell version**: Scripts are designed for PowerShell 7+ but maintain compatibility where possible

### Script Metadata Standards
All scripts should include proper PSScriptInfo headers with:
- Version information
- Author and company details
- Tags for categorization
- License URI
- Project URI linking to this repository
- Comprehensive help documentation with examples

### Common Patterns in This Repository
- **Parameter validation**: Use `[ValidateSet()]`, `[ValidateScript()]`, and proper parameter types
- **Help documentation**: Comprehensive `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, and `.NOTES` sections
- **Digital signatures**: Many scripts are code-signed (see `AuthenticodeSignature_Notes.md`)
- **Modularity**: Functions are designed to be reusable and pipeable
- **Error handling**: Proper error handling with meaningful messages

## Development Guidelines

### When Creating New Scripts
1. **Follow naming conventions**: Use verb-noun pattern (e.g., `Install-VSCode.ps1`, `Invoke-LinkChecker.ps1`)
2. **Include comprehensive help**: Use comment-based help with all sections
3. **Add PSScriptInfo**: Include proper metadata header
4. **Validate parameters**: Use appropriate validation attributes
5. **Support pipeline**: Where applicable, support pipeline input
6. **Handle errors gracefully**: Implement proper error handling
7. **Use approved verbs**: Follow PowerShell approved verb guidelines

### Code Style and Conventions
- Use 4-space indentation
- Follow PowerShell naming conventions (PascalCase for functions, camelCase for variables)
- Include comprehensive parameter help messages
- Use consistent comment formatting
- Prefer explicit parameter names over positional parameters in examples

### Testing and Validation
- Test scripts in both Windows PowerShell 5.1 and PowerShell 7+
- Validate parameter sets and input validation
- Test error conditions and edge cases
- Ensure scripts work from the default installation path

## Script Categories and Patterns

### Installation Scripts
- Pattern: `Install-*.ps1`
- Purpose: Automate software installation and updates
- Examples: `Install-VSCode.ps1`, `Install-WTCanary.ps1`
- Common features: Version checking, download automation, silent installation

### Utility Scripts
- Pattern: Various naming conventions
- Purpose: Provide useful functionality for development and system administration
- Examples: `FolderLens.ps1`, `Invoke-LinkChecker.ps1`
- Common features: Rich parameter sets, pipeline support, object output

### GitHub Copilot Integration Scripts
- Pattern: `ghcs.ps1` (GitHub Copilot Suggest)
- Purpose: Enhance GitHub CLI with Copilot functionality
- Common features: Target selection, prompt handling, command execution

### Helper Scripts
- Pattern: Short names for frequent use
- Purpose: Quick access to common tasks
- Examples: `ask.ps1`
- Common features: Simple interface, integration with external services

## Environment Considerations

### Windows-Specific Features
- Scripts assume Windows environment
- Use Windows-specific paths and commands
- Leverage Windows PowerShell modules where appropriate
- Handle Windows security features (execution policy, code signing)

### External Dependencies
- GitHub CLI (`gh`) for Copilot integration scripts
- Web browsers for redirect-based scripts
- .NET Framework features for encoding and web utilities
- Windows package managers and installers

## File Organization

### Core Scripts
All PowerShell scripts (`.ps1`) should be in the repository root for easy discovery and installation.

### Documentation
- `README.md`: Comprehensive script documentation and usage examples
- `AuthenticodeSignature_Notes.md`: Code signing procedures and examples
- `.github/copilot-instructions.md`: This file - guidance for AI assistants

### Maintenance and Updates
- Keep script versions updated in PSScriptInfo headers
- Update README.md when adding new scripts
- Maintain code signatures when scripts are modified
- Test scripts after PowerShell version updates

## Common Troubleshooting

### Execution Policy Issues
- Scripts may require execution policy changes: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Code-signed scripts can bypass some execution policy restrictions

### Path Issues
- Ensure scripts are in `%userprofile%\Documents\PowerShell\Scripts`
- Restart PowerShell session after adding new scripts
- Use `Get-Command <scriptname>` to verify script is accessible

### Module Dependencies
- Some scripts may require specific modules (e.g., `Appx` for Windows Store apps)
- Use `Import-Module` with appropriate parameters as shown in script examples

## Best Practices for AI Assistance

### When Modifying Existing Scripts
- Preserve existing PSScriptInfo headers and update version numbers
- Maintain existing parameter patterns and validation
- Keep existing code signatures valid (may require re-signing)
- Update help documentation to reflect changes

### When Creating New Scripts
- Follow the established patterns in existing scripts
- Use similar parameter naming and validation approaches
- Include comprehensive help with multiple examples
- Consider pipeline support and object-oriented output

### Code Quality Considerations
- Prefer PowerShell cmdlets over external executables where possible
- Use proper error handling with try/catch blocks
- Include progress indicators for long-running operations
- Support common parameters like `-Verbose` and `-WhatIf` where appropriate
# Contributing to Microsoft Teams Rooms Deployment Guide

Thank you for your interest in contributing to this project! This document provides guidelines for contributions.

## How to Contribute

### Reporting Issues

If you find an error, outdated information, or have a suggestion:

1. Check if the issue already exists in the Issues tab
2. Create a new issue with a clear title and description
3. Include relevant details:
   - Which document or script is affected
   - What the current content says
   - What you believe it should say
   - Any relevant Microsoft documentation links

### Submitting Changes

1. **Fork the repository**
2. **Create a branch** for your changes (`git checkout -b feature/improvement-description`)
3. **Make your changes** following the style guidelines below
4. **Test your changes** (especially for scripts)
5. **Submit a pull request** with a clear description of changes

## Style Guidelines

### Documentation

- Use clear, concise language
- Follow the existing document structure
- Include practical examples where helpful
- Link to official Microsoft documentation for authoritative references
- Use tables for comparison and reference data
- Include "Related Topics" sections to help navigation

### PowerShell Scripts

- Include comment-based help (Synopsis, Description, Parameters, Examples)
- Support `-WhatIf` for commands that make changes
- Use proper error handling with try/catch
- Include `-Verbose` output for debugging
- Follow PowerShell naming conventions (Verb-Noun)
- Use modern Microsoft Graph SDK instead of deprecated modules

Example script header:
```powershell
<#
.SYNOPSIS
    Brief description of what the script does.

.DESCRIPTION
    Detailed description of functionality.

.PARAMETER ParameterName
    Description of the parameter.

.EXAMPLE
    .\Script-Name.ps1 -Parameter Value

    Description of what this example does.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
#>
```

### Markdown

- Use ATX-style headers (`#`, `##`, etc.)
- Include a table of contents for long documents
- Use fenced code blocks with language specification
- Use tables for structured data
- Include alt text for images

## Content Guidelines

### Do Include

- Practical, actionable guidance
- Real-world examples and scenarios
- Troubleshooting tips
- Links to official documentation
- PowerShell examples using current modules

### Don't Include

- Vendor-specific promotional content
- Outdated information (always verify against current Microsoft docs)
- Hardcoded credentials or sensitive information
- Untested scripts or commands
- Content copied directly from Microsoft docs (link instead)

## Testing

### Scripts

Before submitting script changes:

1. Test syntax: `pwsh -c "& { . ./script.ps1 }"`
2. Test with `-WhatIf` if applicable
3. Verify error handling works
4. Test with different parameter combinations
5. Verify help content displays correctly: `Get-Help .\script.ps1 -Full`

### Documentation

Before submitting documentation changes:

1. Verify all internal links work
2. Check that code examples are correct
3. Verify accuracy against current Microsoft documentation
4. Preview markdown rendering

## Pull Request Process

1. Ensure your changes follow the style guidelines
2. Update relevant documentation if adding new features
3. Add your changes to the appropriate section
4. Reference any related issues in your PR description
5. Be responsive to review feedback

### PR Title Format

- `docs: Update conditional access documentation`
- `scripts: Add bulk license assignment script`
- `fix: Correct typo in deployment guide`
- `feat: Add Surface Hub deployment guide`

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and improve
- Respect different perspectives and experience levels

## Questions?

If you have questions about contributing, feel free to open an issue with the "question" label.

## Recognition

Contributors will be recognized in the project. Thank you for helping improve this resource for the community!

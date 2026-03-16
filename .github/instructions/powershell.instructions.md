---
applyTo: "**/*.ps1,**/*.psm1,**/*.psd1"
---
# PowerShell Guidelines

- Use approved verbs from `Get-Verb` (e.g., `New-`, `Set-`, `Get-`, `Remove-`).
- Use PascalCase for function names, parameters, and variables.
- Use `[CmdletBinding()]` and `param()` blocks for all functions.
- Handle errors explicitly with `try`/`catch` or `-ErrorAction Stop`.
- Use `Write-Verbose` for diagnostic output, not `Write-Host`.
- Validate parameters with `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, etc.
- Use splatting (`@params`) for commands with many parameters.
- Include comment-based help (`<# .SYNOPSIS #>`) for all exported functions.
- Target PowerShell 7.0+ for cross-platform compatibility when possible.
- For Azure operations, use the Az module (e.g., `Az.PostgreSql`).
- Reference `CreatePostgreSQLFlexibleServer.ps1` for existing patterns.

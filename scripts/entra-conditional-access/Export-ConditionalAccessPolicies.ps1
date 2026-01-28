<#
.SYNOPSIS
    Exports Conditional Access policies for backup or documentation.

.DESCRIPTION
    This script exports all Conditional Access policies to JSON files
    for backup, documentation, or migration purposes.

.PARAMETER OutputPath
    Directory to save policy exports.

.EXAMPLE
    .\Export-ConditionalAccessPolicies.ps1 -OutputPath ".\CA-Backup"

    Exports all CA policies to the specified directory.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\CA-Policies-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

#Requires -Modules Microsoft.Graph.Identity.SignIns

$ErrorActionPreference = 'Stop'

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph."
    }

    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath | Out-Null
    }

    # Get all policies
    $policies = Get-MgIdentityConditionalAccessPolicy -All

    Write-Information "Exporting $($policies.Count) Conditional Access policies..."

    foreach ($policy in $policies) {
        $safeName = $policy.DisplayName -replace '[\\/:*?"<>|]', '_'
        $fileName = "$safeName.json"
        $filePath = Join-Path $OutputPath $fileName

        $policy | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath
        Write-Verbose "Exported: $fileName"
    }

    # Create summary file
    $summary = $policies | Select-Object Id, DisplayName, State, CreatedDateTime, ModifiedDateTime
    $summary | Export-Csv -Path (Join-Path $OutputPath "_PolicySummary.csv") -NoTypeInformation

    Write-Information "Export complete: $OutputPath"
    Write-Information "  Policies exported: $($policies.Count)"

    return $OutputPath
}
catch {
    Write-Error "Export failed: $_"
    throw
}

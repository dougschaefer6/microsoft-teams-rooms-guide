<#
.SYNOPSIS
    Reports Teams Rooms license assignments across resource accounts.

.DESCRIPTION
    This script audits license assignments for Microsoft Teams Rooms resource
    accounts, identifying accounts with proper licensing, missing licenses,
    or incorrect license types.

.PARAMETER Filter
    Filter for specific accounts. Uses Get-MgUser filter syntax.

.PARAMETER ExportCsv
    Path to export results as CSV.

.EXAMPLE
    .\Get-MTRLicenseStatus.ps1

    Reports license status for all users with MTR-prefixed UPNs.

.EXAMPLE
    .\Get-MTRLicenseStatus.ps1 -ExportCsv ".\license-report.csv"

    Exports license report to CSV.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Filter = "startswith(userPrincipalName, 'mtr-')",

    [Parameter(Mandatory = $false)]
    [string]$ExportCsv
)

#Requires -Modules Microsoft.Graph.Users

$ErrorActionPreference = 'Stop'

try {
    # Check connection
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph first."
    }

    # Get MTR-related SKU IDs
    $skus = Get-MgSubscribedSku | Where-Object {
        $_.SkuPartNumber -like "*MTR*" -or
        $_.SkuPartNumber -like "*Teams_Rooms*"
    }

    Write-Information "Teams Rooms SKUs in tenant:"
    foreach ($sku in $skus) {
        Write-Information "  $($sku.SkuPartNumber): $($sku.ConsumedUnits)/$($sku.PrepaidUnits.Enabled) used"
    }
    Write-Information ""

    # Get users
    $users = Get-MgUser -Filter $Filter -Property Id, UserPrincipalName, DisplayName, AssignedLicenses -All
    Write-Information "Found $($users.Count) user(s) matching filter"

    $results = @()

    foreach ($user in $users) {
        $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue

        $mtrLicense = $licenseDetails | Where-Object {
            $_.SkuPartNumber -like "*MTR*" -or
            $_.SkuPartNumber -like "*Teams_Rooms*"
        }

        $result = [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName       = $user.DisplayName
            HasMTRLicense     = ($null -ne $mtrLicense)
            LicenseType       = if ($mtrLicense) { $mtrLicense.SkuPartNumber -join ", " } else { "None" }
            AllLicenses       = ($licenseDetails.SkuPartNumber -join ", ")
        }

        $results += $result

        if (-not $mtrLicense) {
            Write-Warning "No MTR license: $($user.UserPrincipalName)"
        }
    }

    # Summary
    $licensed = ($results | Where-Object { $_.HasMTRLicense }).Count
    $unlicensed = ($results | Where-Object { -not $_.HasMTRLicense }).Count

    Write-Information ""
    Write-Information "License Summary"
    Write-Information "==============="
    Write-Information "Total Accounts: $($results.Count)"
    Write-Information "With MTR License: $licensed"
    Write-Information "Without MTR License: $unlicensed"

    # Export if requested
    if ($ExportCsv) {
        $results | Export-Csv -Path $ExportCsv -NoTypeInformation
        Write-Information "Exported to: $ExportCsv"
    }

    return $results
}
catch {
    Write-Error "Failed to get license status: $_"
    throw
}

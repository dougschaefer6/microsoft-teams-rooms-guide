<#
.SYNOPSIS
    Assigns Teams Rooms license to a resource account.

.DESCRIPTION
    This script assigns Microsoft Teams Rooms Pro or Basic license to a
    resource account. It verifies the account exists and has a usage location
    set before assigning the license.

.PARAMETER UserPrincipalName
    The UPN of the resource account.

.PARAMETER LicenseType
    The license type to assign: "Pro" or "Basic".

.PARAMETER UsageLocation
    Usage location for the account if not already set.

.EXAMPLE
    .\Set-MTRLicense.ps1 -UserPrincipalName "mtr-hq-101@contoso.com" -LicenseType "Pro"

    Assigns Teams Rooms Pro license.

.EXAMPLE
    .\Set-MTRLicense.ps1 -UserPrincipalName "mtr-hq-101@contoso.com" -LicenseType "Basic" -UsageLocation "US"

    Assigns Basic license and sets usage location.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Pro", "Basic")]
    [string]$LicenseType,

    [Parameter(Mandatory = $false)]
    [string]$UsageLocation
)

#Requires -Modules Microsoft.Graph.Users

$ErrorActionPreference = 'Stop'

# SKU mappings
$skuMapping = @{
    "Pro"   = "MTR_PREM"
    "Basic" = "Microsoft_Teams_Rooms_Basic"
}

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph first."
    }

    # Get user
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -Property Id, UserPrincipalName, UsageLocation, AssignedLicenses
    if (-not $user) {
        throw "User not found: $UserPrincipalName"
    }

    # Set usage location if needed
    if (-not $user.UsageLocation) {
        if (-not $UsageLocation) {
            throw "User has no usage location and none was provided. Use -UsageLocation parameter."
        }
        Write-Information "Setting usage location to: $UsageLocation"
        Update-MgUser -UserId $user.Id -UsageLocation $UsageLocation
    }

    # Get SKU
    $targetSkuName = $skuMapping[$LicenseType]
    $sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq $targetSkuName }

    if (-not $sku) {
        throw "SKU not found in tenant: $targetSkuName. Ensure Teams Rooms $LicenseType licenses are available."
    }

    # Check availability
    $available = $sku.PrepaidUnits.Enabled - $sku.ConsumedUnits
    if ($available -le 0) {
        throw "No available licenses. $($sku.ConsumedUnits)/$($sku.PrepaidUnits.Enabled) used."
    }

    Write-Information "Assigning $LicenseType license ($targetSkuName) to $UserPrincipalName"
    Write-Information "Available licenses: $available"

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Assign $LicenseType license")) {
        $licenseParams = @{
            AddLicenses = @(
                @{
                    SkuId = $sku.SkuId
                }
            )
            RemoveLicenses = @()
        }

        Set-MgUserLicense -UserId $user.Id -BodyParameter $licenseParams
        Write-Information "License assigned successfully."

        # Verify
        $updated = Get-MgUserLicenseDetail -UserId $user.Id
        $assigned = $updated | Where-Object { $_.SkuPartNumber -eq $targetSkuName }

        if ($assigned) {
            Write-Information "Verified: $($assigned.SkuPartNumber) is now assigned."
        }
    }
}
catch {
    Write-Error "Failed to assign license: $_"
    throw
}

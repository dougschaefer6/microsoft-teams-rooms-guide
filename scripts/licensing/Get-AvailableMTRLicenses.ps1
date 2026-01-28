<#
.SYNOPSIS
    Reports available Microsoft Teams Rooms licenses in the tenant.

.DESCRIPTION
    This script displays the current inventory of Teams Rooms licenses,
    including total purchased, consumed, and available counts.

.EXAMPLE
    .\Get-AvailableMTRLicenses.ps1

    Shows Teams Rooms license inventory.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
#>

[CmdletBinding()]
param()

#Requires -Modules Microsoft.Graph.Identity.DirectoryManagement

$ErrorActionPreference = 'Stop'

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph first."
    }

    $skus = Get-MgSubscribedSku | Where-Object {
        $_.SkuPartNumber -like "*MTR*" -or
        $_.SkuPartNumber -like "*Teams_Rooms*"
    }

    if ($skus.Count -eq 0) {
        Write-Warning "No Teams Rooms licenses found in tenant."
        return
    }

    Write-Information "Teams Rooms License Inventory"
    Write-Information "=============================="
    Write-Information ""

    $results = @()

    foreach ($sku in $skus) {
        $enabled = $sku.PrepaidUnits.Enabled
        $consumed = $sku.ConsumedUnits
        $available = $enabled - $consumed
        $percentUsed = if ($enabled -gt 0) { [math]::Round(($consumed / $enabled) * 100, 1) } else { 0 }

        $result = [PSCustomObject]@{
            LicenseName  = $sku.SkuPartNumber
            Total        = $enabled
            Consumed     = $consumed
            Available    = $available
            PercentUsed  = "$percentUsed%"
        }

        $results += $result

        $statusColor = if ($available -le 5) { "Yellow" } elseif ($available -le 0) { "Red" } else { "Green" }

        Write-Information "$($sku.SkuPartNumber)"
        Write-Information "  Total: $enabled | Used: $consumed | Available: $available ($percentUsed% used)"

        if ($available -le 5) {
            Write-Warning "  Low license warning!"
        }
        Write-Information ""
    }

    return $results
}
catch {
    Write-Error "Failed to get license inventory: $_"
    throw
}

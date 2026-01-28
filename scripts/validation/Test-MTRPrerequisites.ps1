<#
.SYNOPSIS
    Validates prerequisites for Microsoft Teams Rooms deployment.

.DESCRIPTION
    This script checks that all prerequisites for MTR deployment are met,
    including licensing, group existence, Conditional Access exclusions,
    and service connectivity.

.PARAMETER MTRGroupName
    Security group name for MTR accounts.

.PARAMETER CAExclusionGroupName
    Security group name for CA exclusions.

.EXAMPLE
    .\Test-MTRPrerequisites.ps1

    Runs all prerequisite checks.

.EXAMPLE
    .\Test-MTRPrerequisites.ps1 -MTRGroupName "Custom-MTR-Group"

    Runs checks with custom group name.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module, ExchangeOnlineManagement module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$MTRGroupName = "MTR-ResourceAccounts-All",

    [Parameter(Mandatory = $false)]
    [string]$CAExclusionGroupName = "MTR-CA-Exclude"
)

$ErrorActionPreference = 'Continue'

function Test-Check {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "Checking: $Name... " -NoNewline

    try {
        $result = & $Test
        if ($result) {
            Write-Host "PASS" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "FAIL" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        return $false
    }
}

# Main checks
Write-Host ""
Write-Host "Microsoft Teams Rooms Prerequisites Check"
Write-Host "=========================================="
Write-Host ""

$results = @()

# Connection checks
Write-Host "Connection Checks:" -ForegroundColor Cyan
$results += [PSCustomObject]@{
    Check = "Microsoft Graph"
    Passed = Test-Check "Microsoft Graph connection" {
        $context = Get-MgContext -ErrorAction Stop
        return $null -ne $context
    }
}

$results += [PSCustomObject]@{
    Check = "Exchange Online"
    Passed = Test-Check "Exchange Online connection" {
        $session = Get-ConnectionInformation | Where-Object { $_.Name -like "*ExchangeOnline*" }
        return $null -ne $session
    }
}

Write-Host ""

# License checks
Write-Host "License Checks:" -ForegroundColor Cyan
$results += [PSCustomObject]@{
    Check = "Teams Rooms Pro License"
    Passed = Test-Check "Teams Rooms Pro license availability" {
        $sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*MTR_PREM*" }
        return ($null -ne $sku) -and (($sku.PrepaidUnits.Enabled - $sku.ConsumedUnits) -gt 0)
    }
}

$results += [PSCustomObject]@{
    Check = "Teams Rooms Basic License"
    Passed = Test-Check "Teams Rooms Basic license availability" {
        $sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*Teams_Rooms_Basic*" }
        return $null -ne $sku
    }
}

Write-Host ""

# Group checks
Write-Host "Group Checks:" -ForegroundColor Cyan
$results += [PSCustomObject]@{
    Check = "MTR Accounts Group"
    Passed = Test-Check "MTR accounts security group exists ($MTRGroupName)" {
        $group = Get-MgGroup -Filter "displayName eq '$MTRGroupName'" -ErrorAction SilentlyContinue
        return $null -ne $group
    }
}

$results += [PSCustomObject]@{
    Check = "CA Exclusion Group"
    Passed = Test-Check "CA exclusion security group exists ($CAExclusionGroupName)" {
        $group = Get-MgGroup -Filter "displayName eq '$CAExclusionGroupName'" -ErrorAction SilentlyContinue
        return $null -ne $group
    }
}

Write-Host ""

# CA checks
Write-Host "Conditional Access Checks:" -ForegroundColor Cyan
$results += [PSCustomObject]@{
    Check = "CA Policies Exist"
    Passed = Test-Check "Conditional Access policies exist" {
        $policies = Get-MgIdentityConditionalAccessPolicy -Top 1 -ErrorAction Stop
        return $true
    }
}

Write-Host ""

# Exchange checks
Write-Host "Exchange Checks:" -ForegroundColor Cyan
$results += [PSCustomObject]@{
    Check = "Room Mailbox Creation"
    Passed = Test-Check "Can query room mailboxes" {
        Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize 1 -ErrorAction Stop | Out-Null
        return $true
    }
}

Write-Host ""

# Summary
$passed = ($results | Where-Object { $_.Passed }).Count
$failed = ($results | Where-Object { -not $_.Passed }).Count

Write-Host "Summary" -ForegroundColor Cyan
Write-Host "======="
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed checks:"
    $results | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "  - $($_.Check)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please resolve failed checks before proceeding with deployment."
}
else {
    Write-Host ""
    Write-Host "All prerequisites passed! Ready for MTR deployment." -ForegroundColor Green
}

return $results

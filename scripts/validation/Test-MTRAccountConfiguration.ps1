<#
.SYNOPSIS
    Validates configuration of a Teams Rooms resource account.

.DESCRIPTION
    This script performs comprehensive validation of a resource account
    to ensure it's properly configured for Teams Rooms deployment.

.PARAMETER UserPrincipalName
    UPN of the resource account to validate.

.EXAMPLE
    .\Test-MTRAccountConfiguration.ps1 -UserPrincipalName "mtr-hq-101@contoso.com"

    Validates the specified account.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module, ExchangeOnlineManagement module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Continue'

function Test-Check {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FailureMessage
    )

    Write-Host "  $Name... " -NoNewline

    try {
        $result = & $Test
        if ($result) {
            Write-Host "PASS" -ForegroundColor Green
            return [PSCustomObject]@{ Check = $Name; Passed = $true; Message = $null }
        }
        else {
            Write-Host "FAIL" -ForegroundColor Red
            if ($FailureMessage) { Write-Host "    $FailureMessage" -ForegroundColor Yellow }
            return [PSCustomObject]@{ Check = $Name; Passed = $false; Message = $FailureMessage }
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        return [PSCustomObject]@{ Check = $Name; Passed = $false; Message = $_.Exception.Message }
    }
}

Write-Host ""
Write-Host "Validating: $UserPrincipalName"
Write-Host "================================"
Write-Host ""

$results = @()

# Mailbox checks
Write-Host "Mailbox Configuration:" -ForegroundColor Cyan
$mailbox = $null
try {
    $mailbox = Get-Mailbox -Identity $UserPrincipalName -ErrorAction Stop
}
catch {
    Write-Host "  CRITICAL: Mailbox not found" -ForegroundColor Red
    return
}

$results += Test-Check "Mailbox exists" { $null -ne $mailbox }
$results += Test-Check "Is room mailbox" { $mailbox.RecipientTypeDetails -eq "RoomMailbox" } "Type: $($mailbox.RecipientTypeDetails)"
$results += Test-Check "Room account enabled" { $mailbox.RoomMailboxAccountEnabled } "Account is disabled"

Write-Host ""

# Calendar processing checks
Write-Host "Calendar Processing:" -ForegroundColor Cyan
$calProc = Get-CalendarProcessing -Identity $UserPrincipalName

$results += Test-Check "AutoAccept enabled" { $calProc.AutomateProcessing -eq "AutoAccept" } "Currently: $($calProc.AutomateProcessing)"
$results += Test-Check "External meetings allowed" { $calProc.ProcessExternalMeetingMessages } "External invites won't be processed"
$results += Test-Check "Subject preserved" { -not $calProc.DeleteSubject } "Meeting subjects will be hidden"
$results += Test-Check "No conflicts allowed" { -not $calProc.AllowConflicts } "Double-booking is possible"

Write-Host ""

# Entra ID checks
Write-Host "Entra ID Configuration:" -ForegroundColor Cyan
$user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -Property Id, AccountEnabled, PasswordPolicies, UsageLocation, AssignedLicenses -ErrorAction SilentlyContinue

if ($user) {
    $results += Test-Check "Account enabled" { $user.AccountEnabled } "Account is disabled in Entra ID"
    $results += Test-Check "Password never expires" { $user.PasswordPolicies -contains "DisablePasswordExpiration" } "Password may expire"
    $results += Test-Check "Usage location set" { $null -ne $user.UsageLocation } "Required for licensing"

    # License check
    Write-Host ""
    Write-Host "Licensing:" -ForegroundColor Cyan
    $licenses = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue
    $mtrLicense = $licenses | Where-Object { $_.SkuPartNumber -like "*MTR*" -or $_.SkuPartNumber -like "*Teams_Rooms*" }

    $results += Test-Check "Has MTR license" { $null -ne $mtrLicense } "No Teams Rooms license assigned"
    if ($mtrLicense) {
        Write-Host "    License: $($mtrLicense.SkuPartNumber)" -ForegroundColor Gray
    }
}
else {
    Write-Host "  WARNING: User not found in Entra ID (may be sync delay)" -ForegroundColor Yellow
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
    Write-Host "Issues to resolve:" -ForegroundColor Yellow
    $results | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "  - $($_.Check)" -ForegroundColor Red
        if ($_.Message) { Write-Host "    $($_.Message)" -ForegroundColor Yellow }
    }
}
else {
    Write-Host ""
    Write-Host "Account is properly configured for Teams Rooms!" -ForegroundColor Green
}

return $results

<#
.SYNOPSIS
    Generates a comprehensive deployment status report for Teams Rooms.

.DESCRIPTION
    This script generates a detailed report on the current state of Teams
    Rooms deployment, including accounts, licensing, enrollment, and health.

.PARAMETER OutputPath
    Path for the HTML report output.

.PARAMETER AccountFilter
    Filter for resource accounts. Default: "mtr-*"

.EXAMPLE
    .\Get-MTRDeploymentReport.ps1

    Generates report with default settings.

.EXAMPLE
    .\Get-MTRDeploymentReport.ps1 -OutputPath "C:\Reports\mtr-report.html"

    Generates report to specified path.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module, ExchangeOnlineManagement module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\MTR-Deployment-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html",

    [Parameter(Mandatory = $false)]
    [string]$AccountFilter = "mtr-"
)

$ErrorActionPreference = 'Continue'

Write-Host "Generating MTR Deployment Report..."
Write-Host ""

# Collect data
$data = @{
    GeneratedAt = Get-Date
    Accounts = @()
    Devices = @()
    Summary = @{}
}

# Get room mailboxes
Write-Host "Collecting account data..."
$mailboxes = Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited |
    Where-Object { $_.Alias -like "$AccountFilter*" }

foreach ($mailbox in $mailboxes) {
    $calProc = Get-CalendarProcessing -Identity $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue
    $user = Get-MgUser -Filter "userPrincipalName eq '$($mailbox.UserPrincipalName)'" -Property Id, AccountEnabled, PasswordPolicies, UsageLocation, AssignedLicenses -ErrorAction SilentlyContinue

    $license = "None"
    if ($user) {
        $licenses = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue
        $mtrLicense = $licenses | Where-Object { $_.SkuPartNumber -like "*MTR*" -or $_.SkuPartNumber -like "*Teams_Rooms*" }
        if ($mtrLicense) { $license = $mtrLicense.SkuPartNumber -join ", " }
    }

    $data.Accounts += [PSCustomObject]@{
        DisplayName = $mailbox.DisplayName
        Email = $mailbox.PrimarySmtpAddress
        AccountEnabled = if ($user) { $user.AccountEnabled } else { "Unknown" }
        License = $license
        AutoAccept = if ($calProc) { $calProc.AutomateProcessing -eq "AutoAccept" } else { "Unknown" }
        PasswordNeverExpires = if ($user) { $user.PasswordPolicies -contains "DisablePasswordExpiration" } else { "Unknown" }
    }
}

# Get enrolled devices
Write-Host "Collecting device data..."
try {
    $devices = Get-MgDeviceManagementManagedDevice -Filter "startswith(deviceName, '$AccountFilter')" -All -ErrorAction SilentlyContinue

    foreach ($device in $devices) {
        $data.Devices += [PSCustomObject]@{
            DeviceName = $device.DeviceName
            SerialNumber = $device.SerialNumber
            OS = $device.OperatingSystem
            OSVersion = $device.OsVersion
            ComplianceState = $device.ComplianceState
            LastSync = $device.LastSyncDateTime
            Model = $device.Model
        }
    }
}
catch {
    Write-Warning "Could not collect device data: $_"
}

# Calculate summary
$data.Summary = @{
    TotalAccounts = $data.Accounts.Count
    LicensedAccounts = ($data.Accounts | Where-Object { $_.License -ne "None" }).Count
    UnlicensedAccounts = ($data.Accounts | Where-Object { $_.License -eq "None" }).Count
    TotalDevices = $data.Devices.Count
    CompliantDevices = ($data.Devices | Where-Object { $_.ComplianceState -eq "compliant" }).Count
    NonCompliantDevices = ($data.Devices | Where-Object { $_.ComplianceState -ne "compliant" -and $_.ComplianceState }).Count
}

# Generate HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>MTR Deployment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; border-bottom: 1px solid #ccc; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4472C4; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .summary-box { background-color: #f0f0f0; padding: 15px; margin-bottom: 20px; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        .warn { color: orange; }
    </style>
</head>
<body>
    <h1>Microsoft Teams Rooms Deployment Report</h1>
    <p>Generated: $($data.GeneratedAt)</p>

    <div class="summary-box">
        <h2>Summary</h2>
        <p><strong>Total Resource Accounts:</strong> $($data.Summary.TotalAccounts)</p>
        <p><strong>Licensed:</strong> <span class="pass">$($data.Summary.LicensedAccounts)</span> | <strong>Unlicensed:</strong> <span class="$(if ($data.Summary.UnlicensedAccounts -gt 0) { 'fail' } else { 'pass' })">$($data.Summary.UnlicensedAccounts)</span></p>
        <p><strong>Total Enrolled Devices:</strong> $($data.Summary.TotalDevices)</p>
        <p><strong>Compliant:</strong> <span class="pass">$($data.Summary.CompliantDevices)</span> | <strong>Non-Compliant:</strong> <span class="$(if ($data.Summary.NonCompliantDevices -gt 0) { 'fail' } else { 'pass' })">$($data.Summary.NonCompliantDevices)</span></p>
    </div>

    <h2>Resource Accounts</h2>
    <table>
        <tr>
            <th>Display Name</th>
            <th>Email</th>
            <th>Account Enabled</th>
            <th>License</th>
            <th>AutoAccept</th>
            <th>Password Never Expires</th>
        </tr>
"@

foreach ($account in $data.Accounts) {
    $html += @"
        <tr>
            <td>$($account.DisplayName)</td>
            <td>$($account.Email)</td>
            <td class="$(if ($account.AccountEnabled -eq $true) { 'pass' } else { 'fail' })">$($account.AccountEnabled)</td>
            <td class="$(if ($account.License -ne 'None') { 'pass' } else { 'fail' })">$($account.License)</td>
            <td class="$(if ($account.AutoAccept -eq $true) { 'pass' } else { 'warn' })">$($account.AutoAccept)</td>
            <td class="$(if ($account.PasswordNeverExpires -eq $true) { 'pass' } else { 'warn' })">$($account.PasswordNeverExpires)</td>
        </tr>
"@
}

$html += @"
    </table>

    <h2>Enrolled Devices</h2>
    <table>
        <tr>
            <th>Device Name</th>
            <th>Serial Number</th>
            <th>OS</th>
            <th>OS Version</th>
            <th>Compliance</th>
            <th>Last Sync</th>
            <th>Model</th>
        </tr>
"@

foreach ($device in $data.Devices) {
    $html += @"
        <tr>
            <td>$($device.DeviceName)</td>
            <td>$($device.SerialNumber)</td>
            <td>$($device.OS)</td>
            <td>$($device.OSVersion)</td>
            <td class="$(if ($device.ComplianceState -eq 'compliant') { 'pass' } else { 'fail' })">$($device.ComplianceState)</td>
            <td>$($device.LastSync)</td>
            <td>$($device.Model)</td>
        </tr>
"@
}

$html += @"
    </table>

    <footer>
        <p><em>Report generated by MTR Deployment Guide scripts</em></p>
    </footer>
</body>
</html>
"@

# Save report
$html | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "Report generated: $OutputPath" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:"
Write-Host "  Accounts: $($data.Summary.TotalAccounts) ($($data.Summary.LicensedAccounts) licensed)"
Write-Host "  Devices: $($data.Summary.TotalDevices) ($($data.Summary.CompliantDevices) compliant)"

return $data

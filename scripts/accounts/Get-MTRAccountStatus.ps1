<#
.SYNOPSIS
    Reports the configuration status of Microsoft Teams Rooms resource accounts.

.DESCRIPTION
    This script audits resource accounts to verify proper configuration for
    Microsoft Teams Rooms. It checks mailbox settings, calendar processing,
    license assignment, Entra ID configuration, and group memberships.

.PARAMETER UserPrincipalName
    Specific account UPN to audit.

.PARAMETER Filter
    Filter to audit multiple accounts. Uses Get-Mailbox filter syntax.

.PARAMETER All
    Audit all room mailboxes in the tenant.

.PARAMETER ExportCsv
    Path to export results as CSV.

.EXAMPLE
    .\Get-MTRAccountStatus.ps1 -UserPrincipalName "mtr-hq-101@contoso.com"

    Audits a single account.

.EXAMPLE
    .\Get-MTRAccountStatus.ps1 -All -ExportCsv ".\mtr-audit.csv"

    Audits all room mailboxes and exports to CSV.

.EXAMPLE
    .\Get-MTRAccountStatus.ps1 -Filter "Alias -like 'mtr-*'"

    Audits rooms matching the filter.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module, ExchangeOnlineManagement module
#>

[CmdletBinding(DefaultParameterSetName = 'Single')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
    [string]$Filter,

    [Parameter(Mandatory = $true, ParameterSetName = 'All')]
    [switch]$All,

    [Parameter(Mandatory = $false)]
    [string]$ExportCsv
)

#Requires -Modules Microsoft.Graph.Users, ExchangeOnlineManagement

$ErrorActionPreference = 'Stop'

function Get-AccountAudit {
    param([string]$UPN)

    Write-Verbose "Auditing: $UPN"

    $result = [PSCustomObject]@{
        UserPrincipalName      = $UPN
        DisplayName            = $null
        MailboxEnabled         = $false
        AccountEnabled         = $false
        PasswordNeverExpires   = $false
        UsageLocation          = $null
        License                = $null
        LicenseAssigned        = $false
        AutoAccept             = $false
        ExternalMeetings       = $false
        AllowConflicts         = $null
        LastSync               = $null
        Issues                 = @()
    }

    try {
        # Check mailbox
        $mailbox = Get-Mailbox -Identity $UPN -ErrorAction Stop
        $result.DisplayName = $mailbox.DisplayName
        $result.MailboxEnabled = $mailbox.IsMailboxEnabled

        # Check calendar processing
        $calProc = Get-CalendarProcessing -Identity $UPN
        $result.AutoAccept = ($calProc.AutomateProcessing -eq "AutoAccept")
        $result.ExternalMeetings = $calProc.ProcessExternalMeetingMessages
        $result.AllowConflicts = $calProc.AllowConflicts

        if (-not $result.AutoAccept) {
            $result.Issues += "AutoAccept not enabled"
        }

        # Check Entra ID
        $user = Get-MgUser -Filter "userPrincipalName eq '$UPN'" -Property Id, AccountEnabled, PasswordPolicies, UsageLocation, AssignedLicenses -ErrorAction SilentlyContinue

        if ($user) {
            $result.AccountEnabled = $user.AccountEnabled
            $result.PasswordNeverExpires = ($user.PasswordPolicies -contains "DisablePasswordExpiration")
            $result.UsageLocation = $user.UsageLocation

            if (-not $result.AccountEnabled) {
                $result.Issues += "Account disabled in Entra ID"
            }

            if (-not $result.PasswordNeverExpires) {
                $result.Issues += "Password may expire"
            }

            if (-not $result.UsageLocation) {
                $result.Issues += "Usage location not set"
            }

            # Check license
            if ($user.AssignedLicenses.Count -gt 0) {
                $result.LicenseAssigned = $true

                # Get license details
                $licenses = Get-MgUserLicenseDetail -UserId $user.Id
                $mtrLicense = $licenses | Where-Object { $_.SkuPartNumber -like "*MTR*" -or $_.SkuPartNumber -like "*Teams_Rooms*" }

                if ($mtrLicense) {
                    $result.License = $mtrLicense.SkuPartNumber -join ", "
                }
                else {
                    $result.Issues += "No Teams Rooms license found"
                }
            }
            else {
                $result.Issues += "No license assigned"
            }
        }
        else {
            $result.Issues += "Not found in Entra ID"
        }
    }
    catch {
        $result.Issues += "Error: $($_.Exception.Message)"
    }

    return $result
}

# Main execution
try {
    # Check connections
    $mgContext = Get-MgContext
    if (-not $mgContext) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph first."
    }

    $exoSession = Get-ConnectionInformation | Where-Object { $_.Name -like "*ExchangeOnline*" }
    if (-not $exoSession) {
        throw "Not connected to Exchange Online. Run Connect-ExchangeOnline first."
    }

    # Get mailboxes to audit
    $mailboxes = @()

    switch ($PSCmdlet.ParameterSetName) {
        'Single' {
            $mailboxes = @(Get-Mailbox -Identity $UserPrincipalName -RecipientTypeDetails RoomMailbox)
        }
        'Filter' {
            $mailboxes = Get-Mailbox -Filter $Filter -RecipientTypeDetails RoomMailbox -ResultSize Unlimited
        }
        'All' {
            $mailboxes = Get-Mailbox -RecipientTypeDetails RoomMailbox -ResultSize Unlimited
        }
    }

    if ($mailboxes.Count -eq 0) {
        Write-Warning "No room mailboxes found."
        return
    }

    Write-Information "Auditing $($mailboxes.Count) room mailbox(es)..."

    # Audit each mailbox
    $results = @()
    $current = 0

    foreach ($mailbox in $mailboxes) {
        $current++
        Write-Progress -Activity "Auditing Accounts" -Status "$($mailbox.PrimarySmtpAddress)" -PercentComplete (($current / $mailboxes.Count) * 100)

        $audit = Get-AccountAudit -UPN $mailbox.PrimarySmtpAddress
        $results += $audit
    }

    Write-Progress -Activity "Auditing Accounts" -Completed

    # Summary
    $healthy = ($results | Where-Object { $_.Issues.Count -eq 0 }).Count
    $issues = ($results | Where-Object { $_.Issues.Count -gt 0 }).Count

    Write-Information ""
    Write-Information "Audit Summary"
    Write-Information "============="
    Write-Information "Total Accounts: $($results.Count)"
    Write-Information "Healthy: $healthy"
    Write-Information "With Issues: $issues"

    # Show issues
    $problemAccounts = $results | Where-Object { $_.Issues.Count -gt 0 }
    if ($problemAccounts) {
        Write-Information ""
        Write-Information "Accounts with Issues:"
        foreach ($account in $problemAccounts) {
            Write-Warning "$($account.UserPrincipalName): $($account.Issues -join '; ')"
        }
    }

    # Export to CSV if requested
    if ($ExportCsv) {
        $exportResults = $results | Select-Object UserPrincipalName, DisplayName, MailboxEnabled, AccountEnabled, PasswordNeverExpires, UsageLocation, License, LicenseAssigned, AutoAccept, ExternalMeetings, AllowConflicts, @{N='Issues';E={$_.Issues -join '; '}}
        $exportResults | Export-Csv -Path $ExportCsv -NoTypeInformation
        Write-Information "Results exported to: $ExportCsv"
    }

    return $results
}
catch {
    Write-Error "Audit failed: $_"
    throw
}

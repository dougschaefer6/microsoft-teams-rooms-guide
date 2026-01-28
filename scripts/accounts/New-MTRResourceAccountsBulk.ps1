<#
.SYNOPSIS
    Creates multiple Microsoft Teams Rooms resource accounts from a CSV file.

.DESCRIPTION
    This script bulk creates resource accounts for Microsoft Teams Rooms deployments.
    It reads room information from a CSV file and creates each account with proper
    configuration for Exchange calendars and Entra ID.

    The script uses modern Microsoft Graph PowerShell SDK and Exchange Online Management
    module. It includes progress indicators, error handling, and detailed logging.

.PARAMETER CsvPath
    Path to the CSV file containing room definitions.

    Required columns:
    - DisplayName: Room display name (e.g., "HQ-Conf-101")
    - UserPrincipalName: UPN for the account (e.g., "mtr-hq-101@contoso.com")

    Optional columns:
    - Password: Account password (generated if not provided)
    - UsageLocation: Two-letter country code (defaults to "US")
    - Building: Building name for documentation
    - Capacity: Room capacity for Exchange

.PARAMETER ConfigureCalendarProcessing
    If specified, configures recommended calendar processing settings for all rooms.

.PARAMETER AddToGroup
    Security group name to add all accounts to.

.PARAMETER LogPath
    Path for the log file. Defaults to current directory with timestamp.

.EXAMPLE
    .\New-MTRResourceAccountsBulk.ps1 -CsvPath ".\rooms.csv"

    Creates accounts from CSV with default settings.

.EXAMPLE
    .\New-MTRResourceAccountsBulk.ps1 -CsvPath ".\rooms.csv" -ConfigureCalendarProcessing -AddToGroup "MTR-ResourceAccounts-All" -WhatIf

    Preview what would be created without making changes.

.EXAMPLE
    .\New-MTRResourceAccountsBulk.ps1 -CsvPath ".\rooms.csv" -LogPath "C:\Logs\mtr-creation.log"

    Creates accounts with custom log file location.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module, ExchangeOnlineManagement module
    Permissions: User Administrator, Exchange Administrator

.LINK
    https://learn.microsoft.com/microsoftteams/rooms/
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to CSV file with room definitions")]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [Parameter(Mandatory = $false, HelpMessage = "Configure calendar processing for all rooms")]
    [switch]$ConfigureCalendarProcessing,

    [Parameter(Mandatory = $false, HelpMessage = "Security group to add accounts to")]
    [string]$AddToGroup,

    [Parameter(Mandatory = $false, HelpMessage = "Log file path")]
    [string]$LogPath = ".\MTR-BulkCreation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Groups, ExchangeOnlineManagement

# Script configuration
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to console with appropriate color
    switch ($Level) {
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
        'WARNING' { Write-Host $logMessage -ForegroundColor Yellow }
        'SUCCESS' { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage }
    }

    # Write to log file
    $logMessage | Out-File -FilePath $LogPath -Append
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."

    # Check Microsoft Graph connection
    try {
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Run Connect-MgGraph first."
        }
        Write-Log "Connected to Microsoft Graph as: $($context.Account)"
    }
    catch {
        throw "Microsoft Graph connection check failed: $_"
    }

    # Check Exchange Online connection
    try {
        $exoSession = Get-ConnectionInformation | Where-Object { $_.Name -like "*ExchangeOnline*" }
        if (-not $exoSession) {
            throw "Not connected to Exchange Online. Run Connect-ExchangeOnline first."
        }
        Write-Log "Connected to Exchange Online"
    }
    catch {
        throw "Exchange Online connection check failed: $_"
    }
}

function Test-CsvFormat {
    param([array]$Rooms)

    Write-Log "Validating CSV format..."

    $requiredColumns = @('DisplayName', 'UserPrincipalName')
    $csvColumns = $Rooms[0].PSObject.Properties.Name

    foreach ($column in $requiredColumns) {
        if ($column -notin $csvColumns) {
            throw "CSV is missing required column: $column"
        }
    }

    # Validate UPN format for all rows
    $invalidUpns = @()
    foreach ($room in $Rooms) {
        if ($room.UserPrincipalName -notmatch '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
            $invalidUpns += $room.UserPrincipalName
        }
    }

    if ($invalidUpns.Count -gt 0) {
        throw "Invalid UPN format found: $($invalidUpns -join ', ')"
    }

    Write-Log "CSV validation passed. Found $($Rooms.Count) room(s) to create." 'SUCCESS'
}

function New-SecurePassword {
    param([int]$Length = 20)

    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
    $password = -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return $password
}

function New-SingleRoomAccount {
    param(
        [PSCustomObject]$Room,
        [bool]$ConfigureCalendar,
        [string]$GroupName
    )

    $displayName = $Room.DisplayName
    $upn = $Room.UserPrincipalName
    $alias = ($upn -split '@')[0]
    $usageLocation = if ($Room.UsageLocation) { $Room.UsageLocation } else { "US" }

    Write-Log "Creating account: $displayName ($upn)"

    # Check if already exists
    $existing = Get-Mailbox -Identity $upn -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Log "Account already exists: $upn" 'WARNING'
        return [PSCustomObject]@{
            DisplayName       = $displayName
            UserPrincipalName = $upn
            Status            = "AlreadyExists"
            Password          = $null
            Error             = $null
        }
    }

    try {
        # Generate or use provided password
        $password = if ($Room.Password) { $Room.Password } else { New-SecurePassword }
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

        # Create room mailbox
        $mailboxParams = @{
            Name                      = $displayName
            Room                      = $true
            Alias                     = $alias
            EnableRoomMailboxAccount  = $true
            RoomMailboxPassword       = $securePassword
        }

        $mailbox = New-Mailbox @mailboxParams
        Write-Log "  Mailbox created" 'SUCCESS'

        # Wait for Entra ID sync (brief delay)
        Start-Sleep -Seconds 5

        # Set password to never expire
        $maxWait = 60
        $waited = 0
        $user = $null

        while (-not $user -and $waited -lt $maxWait) {
            $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
            if (-not $user) {
                Start-Sleep -Seconds 5
                $waited += 5
            }
        }

        if ($user) {
            Update-MgUser -UserId $user.Id -PasswordPolicies "DisablePasswordExpiration" -UsageLocation $usageLocation
            Write-Log "  Password policy and usage location configured" 'SUCCESS'
        }
        else {
            Write-Log "  Warning: Could not configure Entra ID settings (sync delay)" 'WARNING'
        }

        # Configure calendar processing
        if ($ConfigureCalendar) {
            $calendarParams = @{
                Identity                        = $upn
                AutomateProcessing              = "AutoAccept"
                AddOrganizerToSubject           = $false
                AllowConflicts                  = $false
                DeleteAttachments               = $true
                DeleteComments                  = $false
                DeleteNonCalendarItems          = $true
                DeleteSubject                   = $false
                ProcessExternalMeetingMessages  = $true
                RemovePrivateProperty           = $false
            }
            Set-CalendarProcessing @calendarParams
            Write-Log "  Calendar processing configured" 'SUCCESS'
        }

        # Add to security group
        if ($GroupName -and $user) {
            $group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
            if ($group) {
                try {
                    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id -ErrorAction SilentlyContinue
                    Write-Log "  Added to group: $GroupName" 'SUCCESS'
                }
                catch {
                    # May already be a member
                }
            }
        }

        # Set room capacity if provided
        if ($Room.Capacity) {
            Set-Place -Identity $upn -Capacity ([int]$Room.Capacity) -ErrorAction SilentlyContinue
        }

        return [PSCustomObject]@{
            DisplayName       = $displayName
            UserPrincipalName = $upn
            Status            = "Created"
            Password          = $password
            Error             = $null
        }
    }
    catch {
        Write-Log "  Failed: $_" 'ERROR'
        return [PSCustomObject]@{
            DisplayName       = $displayName
            UserPrincipalName = $upn
            Status            = "Failed"
            Password          = $null
            Error             = $_.Exception.Message
        }
    }
}

# Main execution
try {
    Write-Log "=============================================="
    Write-Log "MTR Resource Account Bulk Creation"
    Write-Log "=============================================="
    Write-Log "CSV File: $CsvPath"
    Write-Log "Log File: $LogPath"
    Write-Log ""

    # Check prerequisites
    Test-Prerequisites

    # Import and validate CSV
    $rooms = Import-Csv -Path $CsvPath
    Test-CsvFormat -Rooms $rooms

    Write-Log ""
    Write-Log "Rooms to process:"
    foreach ($room in $rooms) {
        Write-Log "  - $($room.DisplayName) ($($room.UserPrincipalName))"
    }
    Write-Log ""

    # Confirm if not using -WhatIf
    if (-not $WhatIfPreference) {
        Write-Log "Ready to create $($rooms.Count) resource account(s)."
    }

    # Process each room
    $results = @()
    $successCount = 0
    $failCount = 0
    $skipCount = 0

    $totalRooms = $rooms.Count
    $currentRoom = 0

    foreach ($room in $rooms) {
        $currentRoom++
        $percentComplete = [math]::Round(($currentRoom / $totalRooms) * 100)

        Write-Progress -Activity "Creating Resource Accounts" `
            -Status "Processing $($room.DisplayName) ($currentRoom of $totalRooms)" `
            -PercentComplete $percentComplete

        if ($PSCmdlet.ShouldProcess($room.UserPrincipalName, "Create resource account")) {
            $result = New-SingleRoomAccount -Room $room -ConfigureCalendar $ConfigureCalendarProcessing -GroupName $AddToGroup
            $results += $result

            switch ($result.Status) {
                "Created"       { $successCount++ }
                "AlreadyExists" { $skipCount++ }
                "Failed"        { $failCount++ }
            }
        }
        else {
            # WhatIf mode
            Write-Log "Would create: $($room.DisplayName) ($($room.UserPrincipalName))" 'INFO'
            $results += [PSCustomObject]@{
                DisplayName       = $room.DisplayName
                UserPrincipalName = $room.UserPrincipalName
                Status            = "WhatIf"
                Password          = $null
                Error             = $null
            }
        }
    }

    Write-Progress -Activity "Creating Resource Accounts" -Completed

    # Summary
    Write-Log ""
    Write-Log "=============================================="
    Write-Log "Bulk Creation Complete"
    Write-Log "=============================================="
    Write-Log "Total Processed: $totalRooms"
    Write-Log "  Created: $successCount" 'SUCCESS'
    Write-Log "  Skipped (existing): $skipCount" 'WARNING'
    Write-Log "  Failed: $failCount" 'ERROR'
    Write-Log ""

    # Export results to CSV
    $resultsPath = $LogPath -replace '\.log$', '-Results.csv'
    $results | Export-Csv -Path $resultsPath -NoTypeInformation
    Write-Log "Results exported to: $resultsPath"

    # Show passwords for created accounts
    $createdAccounts = $results | Where-Object { $_.Status -eq "Created" -and $_.Password }
    if ($createdAccounts) {
        Write-Log ""
        Write-Log "IMPORTANT: Save these passwords securely!"
        Write-Log "=============================================="
        foreach ($account in $createdAccounts) {
            Write-Log "  $($account.UserPrincipalName): $($account.Password)"
        }
    }

    Write-Log ""
    Write-Log "Next steps:"
    Write-Log "  1. Assign Teams Rooms Pro or Basic licenses"
    Write-Log "  2. Wait 15-30 minutes for full sync"
    Write-Log "  3. Deploy devices with saved credentials"

    # Return results
    return $results
}
catch {
    Write-Log "Bulk creation failed: $_" 'ERROR'
    throw
}

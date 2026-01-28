<#
.SYNOPSIS
    Configures calendar processing settings for Microsoft Teams Rooms resource accounts.

.DESCRIPTION
    This script configures Exchange calendar processing settings optimized for
    Microsoft Teams Rooms. It can apply settings to a single account or multiple
    accounts matching a filter.

.PARAMETER Identity
    The identity (UPN or email) of the resource account to configure.

.PARAMETER Filter
    Filter to apply settings to multiple accounts. Uses Get-Mailbox filter syntax.
    Example: "Alias -like 'mtr-*'"

.PARAMETER AllowExternalMeetings
    Whether to process external meeting requests. Default: $true

.PARAMETER AllowConflicts
    Whether to allow double-booking. Default: $false

.PARAMETER AdditionalResponse
    Custom response message to include in booking confirmations.

.PARAMETER BookingWindowDays
    Maximum days in advance for booking. Default: 180

.EXAMPLE
    .\Set-MTRCalendarProcessing.ps1 -Identity "mtr-hq-101@contoso.com"

    Configures recommended settings for a single room.

.EXAMPLE
    .\Set-MTRCalendarProcessing.ps1 -Filter "Alias -like 'mtr-*'" -WhatIf

    Preview changes for all rooms with alias starting with "mtr-".

.EXAMPLE
    .\Set-MTRCalendarProcessing.ps1 -Identity "mtr-hq-101@contoso.com" -BookingWindowDays 365 -AdditionalResponse "This room has video conferencing."

    Configures with custom settings.

.NOTES
    Author: MTR Deployment Guide
    Requires: ExchangeOnlineManagement module
    Permissions: Exchange Administrator
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Single')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Single', HelpMessage = "Resource account identity")]
    [string]$Identity,

    [Parameter(Mandatory = $true, ParameterSetName = 'Bulk', HelpMessage = "Filter for multiple accounts")]
    [string]$Filter,

    [Parameter(Mandatory = $false, HelpMessage = "Process external meeting requests")]
    [bool]$AllowExternalMeetings = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Allow double-booking")]
    [bool]$AllowConflicts = $false,

    [Parameter(Mandatory = $false, HelpMessage = "Custom booking response message")]
    [string]$AdditionalResponse = "This is a Microsoft Teams Room. Please use the room's Teams device for your meeting.",

    [Parameter(Mandatory = $false, HelpMessage = "Maximum booking window in days")]
    [ValidateRange(1, 1080)]
    [int]$BookingWindowDays = 180
)

#Requires -Modules ExchangeOnlineManagement

$ErrorActionPreference = 'Stop'

function Set-RoomCalendarProcessing {
    param(
        [string]$RoomIdentity,
        [hashtable]$Settings
    )

    Write-Verbose "Configuring calendar processing for: $RoomIdentity"

    $calendarParams = @{
        Identity                        = $RoomIdentity
        AutomateProcessing              = "AutoAccept"
        AddOrganizerToSubject           = $false
        AllowConflicts                  = $Settings.AllowConflicts
        DeleteAttachments               = $true
        DeleteComments                  = $false
        DeleteNonCalendarItems          = $true
        DeleteSubject                   = $false
        ProcessExternalMeetingMessages  = $Settings.AllowExternalMeetings
        RemovePrivateProperty           = $false
        BookingWindowInDays             = $Settings.BookingWindowDays
        AddAdditionalResponse           = $true
        AdditionalResponse              = $Settings.AdditionalResponse
    }

    Set-CalendarProcessing @calendarParams

    Write-Information "Configured: $RoomIdentity"
}

# Main execution
try {
    # Check Exchange Online connection
    $exoSession = Get-ConnectionInformation | Where-Object { $_.Name -like "*ExchangeOnline*" }
    if (-not $exoSession) {
        throw "Not connected to Exchange Online. Run Connect-ExchangeOnline first."
    }

    $settings = @{
        AllowExternalMeetings = $AllowExternalMeetings
        AllowConflicts        = $AllowConflicts
        AdditionalResponse    = $AdditionalResponse
        BookingWindowDays     = $BookingWindowDays
    }

    $rooms = @()

    if ($PSCmdlet.ParameterSetName -eq 'Single') {
        $room = Get-Mailbox -Identity $Identity -RecipientTypeDetails RoomMailbox -ErrorAction Stop
        $rooms = @($room)
    }
    else {
        $rooms = Get-Mailbox -Filter $Filter -RecipientTypeDetails RoomMailbox
        if ($rooms.Count -eq 0) {
            Write-Warning "No room mailboxes found matching filter: $Filter"
            return
        }
    }

    Write-Information "Found $($rooms.Count) room(s) to configure"

    foreach ($room in $rooms) {
        if ($PSCmdlet.ShouldProcess($room.PrimarySmtpAddress, "Configure calendar processing")) {
            Set-RoomCalendarProcessing -RoomIdentity $room.PrimarySmtpAddress -Settings $settings
        }
    }

    Write-Information ""
    Write-Information "Calendar processing configuration complete."
    Write-Information "Settings applied:"
    Write-Information "  - AutoAccept: Yes"
    Write-Information "  - Allow External: $AllowExternalMeetings"
    Write-Information "  - Allow Conflicts: $AllowConflicts"
    Write-Information "  - Booking Window: $BookingWindowDays days"
}
catch {
    Write-Error "Failed to configure calendar processing: $_"
    throw
}

<#
.SYNOPSIS
    Creates a single Microsoft Teams Rooms resource account.

.DESCRIPTION
    This script creates a new resource account (room mailbox) for Microsoft Teams Rooms.
    It creates the Exchange room mailbox, configures the account in Entra ID, and
    optionally configures calendar processing settings.

    The script uses modern Microsoft Graph PowerShell SDK and Exchange Online Management
    module for all operations.

.PARAMETER DisplayName
    The display name for the room (e.g., "HQ-Conference-Room-101").

.PARAMETER UserPrincipalName
    The UPN for the resource account (e.g., "mtr-hq-101@contoso.com").

.PARAMETER Password
    The password for the resource account. If not provided, a secure random password
    will be generated.

.PARAMETER UsageLocation
    The usage location for license assignment (e.g., "US"). Required for licensing.

.PARAMETER ConfigureCalendarProcessing
    If specified, configures recommended calendar processing settings.

.PARAMETER AddToGroup
    Security group to add the account to (e.g., "MTR-ResourceAccounts-All").

.EXAMPLE
    .\New-MTRResourceAccount.ps1 -DisplayName "HQ-Conf-101" -UserPrincipalName "mtr-hq-101@contoso.com"

    Creates a resource account with generated password.

.EXAMPLE
    .\New-MTRResourceAccount.ps1 -DisplayName "HQ-Conf-101" -UserPrincipalName "mtr-hq-101@contoso.com" -ConfigureCalendarProcessing -AddToGroup "MTR-ResourceAccounts-All"

    Creates account with calendar processing and adds to security group.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module, ExchangeOnlineManagement module
    Permissions: User Administrator, Exchange Administrator

.LINK
    https://learn.microsoft.com/microsoftteams/rooms/
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Display name for the room")]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [Parameter(Mandatory = $true, HelpMessage = "UPN for the resource account")]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $false, HelpMessage = "Password for the account")]
    [SecureString]$Password,

    [Parameter(Mandatory = $false, HelpMessage = "Usage location for licensing")]
    [ValidateLength(2, 2)]
    [string]$UsageLocation = "US",

    [Parameter(Mandatory = $false, HelpMessage = "Configure calendar processing settings")]
    [switch]$ConfigureCalendarProcessing,

    [Parameter(Mandatory = $false, HelpMessage = "Security group to add account to")]
    [string]$AddToGroup
)

#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Groups, ExchangeOnlineManagement

# Script configuration
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

function Test-Prerequisites {
    Write-Verbose "Checking prerequisites..."

    # Check Microsoft Graph connection
    try {
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Run Connect-MgGraph first."
        }
        Write-Verbose "Connected to Microsoft Graph as: $($context.Account)"
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
        Write-Verbose "Connected to Exchange Online"
    }
    catch {
        throw "Exchange Online connection check failed: $_"
    }
}

function New-SecurePassword {
    param([int]$Length = 20)

    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
    $password = -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return ConvertTo-SecureString -String $password -AsPlainText -Force
}

function New-RoomMailbox {
    param(
        [string]$DisplayName,
        [string]$UserPrincipalName,
        [SecureString]$Password
    )

    $alias = ($UserPrincipalName -split '@')[0]

    Write-Information "Creating room mailbox: $DisplayName ($UserPrincipalName)"

    $mailboxParams = @{
        Name                      = $DisplayName
        Room                      = $true
        Alias                     = $alias
        EnableRoomMailboxAccount  = $true
        RoomMailboxPassword       = $Password
    }

    $mailbox = New-Mailbox @mailboxParams
    Write-Verbose "Room mailbox created: $($mailbox.PrimarySmtpAddress)"

    return $mailbox
}

function Set-AccountPasswordPolicy {
    param([string]$UserPrincipalName)

    Write-Information "Setting password to never expire..."

    # Wait for Entra ID sync
    $maxWait = 120
    $waited = 0
    $user = $null

    while (-not $user -and $waited -lt $maxWait) {
        try {
            $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ErrorAction SilentlyContinue
        }
        catch {
            # User not synced yet
        }

        if (-not $user) {
            Write-Verbose "Waiting for user to sync to Entra ID... ($waited seconds)"
            Start-Sleep -Seconds 10
            $waited += 10
        }
    }

    if (-not $user) {
        Write-Warning "User not found in Entra ID after $maxWait seconds. Password policy may need manual configuration."
        return
    }

    # Set password to never expire
    Update-MgUser -UserId $user.Id -PasswordPolicies "DisablePasswordExpiration"
    Write-Verbose "Password policy updated"
}

function Set-AccountUsageLocation {
    param(
        [string]$UserPrincipalName,
        [string]$UsageLocation
    )

    Write-Information "Setting usage location to: $UsageLocation"

    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    Update-MgUser -UserId $user.Id -UsageLocation $UsageLocation
    Write-Verbose "Usage location set"
}

function Set-RecommendedCalendarProcessing {
    param([string]$Identity)

    Write-Information "Configuring calendar processing settings..."

    $calendarParams = @{
        Identity                        = $Identity
        AutomateProcessing              = "AutoAccept"
        AddOrganizerToSubject           = $false
        AllowConflicts                  = $false
        DeleteAttachments               = $true
        DeleteComments                  = $false
        DeleteNonCalendarItems          = $true
        DeleteSubject                   = $false
        ProcessExternalMeetingMessages  = $true
        RemovePrivateProperty           = $false
        AddAdditionalResponse           = $true
        AdditionalResponse              = "This is a Microsoft Teams Room. Please use the room's Teams device for your meeting."
    }

    Set-CalendarProcessing @calendarParams
    Write-Verbose "Calendar processing configured"
}

function Add-ToSecurityGroup {
    param(
        [string]$UserPrincipalName,
        [string]$GroupName
    )

    Write-Information "Adding account to group: $GroupName"

    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    $group = Get-MgGroup -Filter "displayName eq '$GroupName'"

    if (-not $group) {
        Write-Warning "Group '$GroupName' not found. Skipping group membership."
        return
    }

    try {
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
        Write-Verbose "Added to group successfully"
    }
    catch {
        if ($_.Exception.Message -like "*already exist*") {
            Write-Verbose "User already a member of the group"
        }
        else {
            throw $_
        }
    }
}

# Main execution
try {
    Write-Information "Starting resource account creation for: $DisplayName"
    Write-Information "=============================================="

    # Check prerequisites
    Test-Prerequisites

    # Check if account already exists
    $existingMailbox = Get-Mailbox -Identity $UserPrincipalName -ErrorAction SilentlyContinue
    if ($existingMailbox) {
        throw "A mailbox with UPN '$UserPrincipalName' already exists."
    }

    # Generate password if not provided
    if (-not $Password) {
        Write-Information "Generating secure password..."
        $Password = New-SecurePassword
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )
        Write-Warning "Generated password (save this securely): $plainPassword"
    }

    # Create the room mailbox
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Create room mailbox")) {
        $mailbox = New-RoomMailbox -DisplayName $DisplayName -UserPrincipalName $UserPrincipalName -Password $Password

        # Set password policy
        Set-AccountPasswordPolicy -UserPrincipalName $UserPrincipalName

        # Set usage location
        Set-AccountUsageLocation -UserPrincipalName $UserPrincipalName -UsageLocation $UsageLocation

        # Configure calendar processing if requested
        if ($ConfigureCalendarProcessing) {
            Set-RecommendedCalendarProcessing -Identity $UserPrincipalName
        }

        # Add to security group if specified
        if ($AddToGroup) {
            Add-ToSecurityGroup -UserPrincipalName $UserPrincipalName -GroupName $AddToGroup
        }

        Write-Information "=============================================="
        Write-Information "Resource account created successfully!"
        Write-Information "  Display Name: $DisplayName"
        Write-Information "  UPN: $UserPrincipalName"
        Write-Information "  Usage Location: $UsageLocation"
        Write-Information ""
        Write-Information "Next steps:"
        Write-Information "  1. Assign Teams Rooms Pro or Basic license"
        Write-Information "  2. Wait 15-30 minutes for full sync"
        Write-Information "  3. Configure device with these credentials"

        # Return account info
        return [PSCustomObject]@{
            DisplayName       = $DisplayName
            UserPrincipalName = $UserPrincipalName
            UsageLocation     = $UsageLocation
            CalendarProcessing = $ConfigureCalendarProcessing
            GroupMembership   = $AddToGroup
            Status            = "Created"
        }
    }
}
catch {
    Write-Error "Failed to create resource account: $_"
    throw
}

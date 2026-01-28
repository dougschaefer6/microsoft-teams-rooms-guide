<#
.SYNOPSIS
    Configures Teams policies for Teams Rooms resource accounts.

.DESCRIPTION
    This script configures Teams meeting policies and other settings
    appropriate for Microsoft Teams Rooms resource accounts.

.PARAMETER UserPrincipalName
    UPN of the resource account to configure.

.PARAMETER MeetingPolicyName
    Meeting policy to assign. If not specified, uses default.

.EXAMPLE
    .\Set-MTRTeamsPolicy.ps1 -UserPrincipalName "mtr-hq-101@contoso.com"

    Applies default Teams policies to the account.

.NOTES
    Author: MTR Deployment Guide
    Requires: MicrosoftTeams module
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $false)]
    [string]$MeetingPolicyName,

    [Parameter(Mandatory = $false)]
    [string]$MessagingPolicyName
)

#Requires -Modules MicrosoftTeams

$ErrorActionPreference = 'Stop'

try {
    # Check Teams connection
    try {
        Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Not connected to Microsoft Teams or user not found. Run Connect-MicrosoftTeams first."
    }

    Write-Information "Configuring Teams policies for: $UserPrincipalName"

    # Assign meeting policy if specified
    if ($MeetingPolicyName) {
        Write-Information "  Assigning meeting policy: $MeetingPolicyName"
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Assign meeting policy $MeetingPolicyName")) {
            Grant-CsTeamsMeetingPolicy -Identity $UserPrincipalName -PolicyName $MeetingPolicyName
        }
    }

    # Assign messaging policy if specified
    if ($MessagingPolicyName) {
        Write-Information "  Assigning messaging policy: $MessagingPolicyName"
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Assign messaging policy $MessagingPolicyName")) {
            Grant-CsTeamsMessagingPolicy -Identity $UserPrincipalName -PolicyName $MessagingPolicyName
        }
    }

    # Get current policy assignments
    $user = Get-CsOnlineUser -Identity $UserPrincipalName

    Write-Information ""
    Write-Information "Current policy assignments:"
    Write-Information "  Meeting Policy: $($user.TeamsMeetingPolicy)"
    Write-Information "  Messaging Policy: $($user.TeamsMessagingPolicy)"
    Write-Information "  Calling Policy: $($user.TeamsCallingPolicy)"
    Write-Information "  App Setup Policy: $($user.TeamsAppSetupPolicy)"

    return $user
}
catch {
    Write-Error "Failed to configure Teams policy: $_"
    throw
}

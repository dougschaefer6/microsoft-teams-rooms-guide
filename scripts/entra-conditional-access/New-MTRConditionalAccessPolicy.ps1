<#
.SYNOPSIS
    Creates a Conditional Access policy optimized for Microsoft Teams Rooms.

.DESCRIPTION
    This script creates a Conditional Access policy with settings appropriate
    for Teams Rooms devices, including compliant device requirement and
    extended sign-in frequency.

.PARAMETER PolicyName
    Name for the policy. Default: "MTR-Access-Policy"

.PARAMETER IncludeGroupName
    Security group containing MTR resource accounts to include.

.PARAMETER RequireCompliantDevice
    Require devices to be marked compliant. Default: $true

.PARAMETER SignInFrequencyDays
    Sign-in frequency in days. Default: 90

.PARAMETER State
    Policy state: enabled, disabled, or enabledForReportingButNotEnforced.

.EXAMPLE
    .\New-MTRConditionalAccessPolicy.ps1 -IncludeGroupName "MTR-ResourceAccounts-All"

    Creates enabled policy for MTR accounts.

.EXAMPLE
    .\New-MTRConditionalAccessPolicy.ps1 -IncludeGroupName "MTR-ResourceAccounts-All" -State "enabledForReportingButNotEnforced"

    Creates policy in report-only mode for testing.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
    Permissions: Conditional Access Administrator
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$PolicyName = "MTR-Access-Policy",

    [Parameter(Mandatory = $true)]
    [string]$IncludeGroupName,

    [Parameter(Mandatory = $false)]
    [bool]$RequireCompliantDevice = $true,

    [Parameter(Mandatory = $false)]
    [int]$SignInFrequencyDays = 90,

    [Parameter(Mandatory = $false)]
    [ValidateSet("enabled", "disabled", "enabledForReportingButNotEnforced")]
    [string]$State = "enabled"
)

#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Groups

$ErrorActionPreference = 'Stop'

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph with scope 'Policy.ReadWrite.ConditionalAccess'."
    }

    # Get the group
    $group = Get-MgGroup -Filter "displayName eq '$IncludeGroupName'"
    if (-not $group) {
        throw "Group not found: $IncludeGroupName"
    }

    Write-Information "Creating Conditional Access policy: $PolicyName"
    Write-Information "  Include group: $IncludeGroupName ($($group.Id))"
    Write-Information "  Require compliant device: $RequireCompliantDevice"
    Write-Information "  Sign-in frequency: $SignInFrequencyDays days"
    Write-Information "  State: $State"

    # Build policy parameters
    $grantControls = @{
        Operator = "OR"
        BuiltInControls = @()
    }

    if ($RequireCompliantDevice) {
        $grantControls.BuiltInControls += "compliantDevice"
    }
    $grantControls.BuiltInControls += "approvedApplication"

    $policyParams = @{
        DisplayName = $PolicyName
        State = $State
        Conditions = @{
            Users = @{
                IncludeGroups = @($group.Id)
            }
            Applications = @{
                IncludeApplications = @("All")
            }
            ClientAppTypes = @("all")
        }
        GrantControls = $grantControls
        SessionControls = @{
            SignInFrequency = @{
                Value = $SignInFrequencyDays
                Type = "days"
                IsEnabled = $true
            }
        }
    }

    if ($PSCmdlet.ShouldProcess($PolicyName, "Create Conditional Access policy")) {
        $policy = New-MgIdentityConditionalAccessPolicy -BodyParameter $policyParams
        Write-Information "Policy created successfully!"
        Write-Information "  Policy ID: $($policy.Id)"
        Write-Information "  State: $($policy.State)"

        return $policy
    }
}
catch {
    Write-Error "Failed to create CA policy: $_"
    throw
}

<#
.SYNOPSIS
    Creates a Windows Autopilot deployment profile for Teams Rooms.

.DESCRIPTION
    This script creates an Autopilot deployment profile configured for
    Teams Rooms self-deploying mode deployment.

.PARAMETER ProfileName
    Name for the Autopilot profile.

.PARAMETER DeviceNameTemplate
    Template for device naming. Use %SERIAL% for serial number.

.EXAMPLE
    .\New-MTRAutopilotProfile.ps1 -ProfileName "MTR-Autopilot-Profile"

    Creates Autopilot profile with default settings.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
    Permissions: Intune Administrator
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProfileName = "MTR-Autopilot-Profile",

    [Parameter(Mandatory = $false)]
    [string]$Description = "Autopilot profile for Microsoft Teams Rooms zero-touch deployment",

    [Parameter(Mandatory = $false)]
    [string]$DeviceNameTemplate = "MTR-%SERIAL%"
)

#Requires -Modules Microsoft.Graph.DeviceManagement.Enrollment

$ErrorActionPreference = 'Stop'

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph."
    }

    Write-Information "Creating Autopilot deployment profile: $ProfileName"

    $profileParams = @{
        "@odata.type" = "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"
        displayName = $ProfileName
        description = $Description
        deviceNameTemplate = $DeviceNameTemplate
        language = "en-US"
        extractHardwareHash = $true
        enableWhiteGlove = $false
        deviceType = "windowsPc"
        outOfBoxExperienceSettings = @{
            "@odata.type" = "microsoft.graph.outOfBoxExperienceSettings"
            hidePrivacySettings = $true
            hideEULA = $true
            userType = "standard"
            deviceUsageType = "shared"
            skipKeyboardSelectionPage = $true
            hideEscapeLink = $true
        }
    }

    if ($PSCmdlet.ShouldProcess($ProfileName, "Create Autopilot profile")) {
        $profile = Invoke-MgGraphRequest -Method POST `
            -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles" `
            -Body ($profileParams | ConvertTo-Json -Depth 5) `
            -ContentType "application/json"

        Write-Information "Profile created successfully!"
        Write-Information "  Profile ID: $($profile.id)"
        Write-Information "  Name: $($profile.displayName)"
        Write-Information ""
        Write-Information "Next steps:"
        Write-Information "  1. Create dynamic device group with rule: (device.devicePhysicalIds -any (_ -contains ""[OrderID]:MTR""))"
        Write-Information "  2. Assign this profile to the group"
        Write-Information "  3. Register devices with Group Tag 'MTR'"

        return $profile
    }
}
catch {
    Write-Error "Failed to create Autopilot profile: $_"
    throw
}

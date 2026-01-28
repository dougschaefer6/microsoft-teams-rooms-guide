<#
.SYNOPSIS
    Reports Intune enrollment status for Teams Rooms devices.

.DESCRIPTION
    This script checks the enrollment and compliance status of Teams Rooms
    devices in Microsoft Intune.

.PARAMETER DeviceNameFilter
    Filter for device names. Default: "MTR-*"

.PARAMETER ExportCsv
    Path to export results as CSV.

.EXAMPLE
    .\Get-MTRDeviceEnrollmentStatus.ps1

    Shows enrollment status for MTR devices.

.EXAMPLE
    .\Get-MTRDeviceEnrollmentStatus.ps1 -ExportCsv ".\enrollment-report.csv"

    Exports enrollment status to CSV.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DeviceNameFilter = "MTR-",

    [Parameter(Mandatory = $false)]
    [string]$ExportCsv
)

#Requires -Modules Microsoft.Graph.DeviceManagement

$ErrorActionPreference = 'Stop'

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph."
    }

    # Get managed devices
    $devices = Get-MgDeviceManagementManagedDevice -Filter "startswith(deviceName, '$DeviceNameFilter')" -All

    if ($devices.Count -eq 0) {
        Write-Warning "No devices found matching filter: $DeviceNameFilter*"
        return
    }

    Write-Information "Found $($devices.Count) device(s)"

    $results = @()

    foreach ($device in $devices) {
        $result = [PSCustomObject]@{
            DeviceName         = $device.DeviceName
            SerialNumber       = $device.SerialNumber
            EnrollmentState    = $device.ManagedDeviceOwnerType
            ComplianceState    = $device.ComplianceState
            OSVersion          = $device.OsVersion
            LastSyncDateTime   = $device.LastSyncDateTime
            Model              = $device.Model
            Manufacturer       = $device.Manufacturer
            EnrolledDateTime   = $device.EnrolledDateTime
            UserPrincipalName  = $device.UserPrincipalName
        }

        $results += $result

        # Report non-compliant
        if ($device.ComplianceState -ne "compliant") {
            Write-Warning "$($device.DeviceName): $($device.ComplianceState)"
        }
    }

    # Summary
    $compliant = ($results | Where-Object { $_.ComplianceState -eq "compliant" }).Count
    $nonCompliant = ($results | Where-Object { $_.ComplianceState -ne "compliant" }).Count

    Write-Information ""
    Write-Information "Summary"
    Write-Information "======="
    Write-Information "Total Devices: $($results.Count)"
    Write-Information "Compliant: $compliant"
    Write-Information "Non-Compliant: $nonCompliant"

    # Export if requested
    if ($ExportCsv) {
        $results | Export-Csv -Path $ExportCsv -NoTypeInformation
        Write-Information "Exported to: $ExportCsv"
    }

    return $results
}
catch {
    Write-Error "Failed to get enrollment status: $_"
    throw
}

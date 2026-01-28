<#
.SYNOPSIS
    Imports devices to Windows Autopilot from a CSV file.

.DESCRIPTION
    This script imports device hardware IDs to Windows Autopilot. The CSV
    must contain serial numbers and hardware hashes.

.PARAMETER CsvPath
    Path to CSV file with device information.

.PARAMETER GroupTag
    Group tag to assign to all devices. Default: "MTR"

.EXAMPLE
    .\Import-AutopilotDevices.ps1 -CsvPath ".\devices.csv"

    Imports devices from CSV with default MTR group tag.

.EXAMPLE
    .\Import-AutopilotDevices.ps1 -CsvPath ".\devices.csv" -GroupTag "MTR-Building1"

    Imports with custom group tag.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module

    CSV format:
    Device Serial Number,Windows Product ID,Hardware Hash
    SERIAL001,,BASE64HASH==
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [string]$GroupTag = "MTR"
)

#Requires -Modules Microsoft.Graph.DeviceManagement.Enrollment

$ErrorActionPreference = 'Stop'

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph."
    }

    # Import CSV
    $devices = Import-Csv -Path $CsvPath
    Write-Information "Found $($devices.Count) device(s) to import"

    $results = @()

    foreach ($device in $devices) {
        $serialNumber = $device.'Device Serial Number'
        $hardwareHash = $device.'Hardware Hash'

        if (-not $serialNumber -or -not $hardwareHash) {
            Write-Warning "Skipping device with missing data"
            continue
        }

        Write-Information "Importing: $serialNumber"

        $deviceParams = @{
            "@odata.type" = "#microsoft.graph.importedWindowsAutopilotDeviceIdentity"
            serialNumber = $serialNumber
            hardwareIdentifier = $hardwareHash
            groupTag = $GroupTag
        }

        if ($PSCmdlet.ShouldProcess($serialNumber, "Import to Autopilot")) {
            try {
                $imported = Invoke-MgGraphRequest -Method POST `
                    -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" `
                    -Body ($deviceParams | ConvertTo-Json) `
                    -ContentType "application/json"

                $results += [PSCustomObject]@{
                    SerialNumber = $serialNumber
                    Status = "Imported"
                    Id = $imported.id
                }
            }
            catch {
                $results += [PSCustomObject]@{
                    SerialNumber = $serialNumber
                    Status = "Failed"
                    Error = $_.Exception.Message
                }
                Write-Warning "Failed to import $serialNumber: $_"
            }
        }
    }

    Write-Information ""
    Write-Information "Import complete"
    Write-Information "  Successful: $(($results | Where-Object {$_.Status -eq 'Imported'}).Count)"
    Write-Information "  Failed: $(($results | Where-Object {$_.Status -eq 'Failed'}).Count)"
    Write-Information ""
    Write-Information "Note: Device sync may take 15+ minutes to complete."

    return $results
}
catch {
    Write-Error "Import failed: $_"
    throw
}

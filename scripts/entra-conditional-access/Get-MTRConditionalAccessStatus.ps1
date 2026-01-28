<#
.SYNOPSIS
    Audits Conditional Access policies affecting Teams Rooms accounts.

.DESCRIPTION
    This script analyzes CA policies to identify which affect MTR resource
    accounts, whether directly targeted or through "All users" policies.

.PARAMETER MTRGroupName
    Security group name for MTR accounts.

.EXAMPLE
    .\Get-MTRConditionalAccessStatus.ps1 -MTRGroupName "MTR-ResourceAccounts-All"

    Analyzes CA policies for MTR coverage.

.NOTES
    Author: MTR Deployment Guide
    Requires: Microsoft.Graph module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$MTRGroupName = "MTR-ResourceAccounts-All"
)

#Requires -Modules Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Groups

$ErrorActionPreference = 'Stop'

try {
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph."
    }

    # Get MTR group
    $mtrGroup = Get-MgGroup -Filter "displayName eq '$MTRGroupName'" -ErrorAction SilentlyContinue

    # Get all CA policies
    $policies = Get-MgIdentityConditionalAccessPolicy -All

    Write-Information "Analyzing $($policies.Count) Conditional Access policies..."
    Write-Information ""

    $results = @()

    foreach ($policy in $policies) {
        $affectsMTR = $false
        $mtrExcluded = $false
        $requiresMFA = $false
        $requiresCompliant = $false
        $concerns = @()

        # Check if targets all users
        if ("All" -in $policy.Conditions.Users.IncludeUsers) {
            $affectsMTR = $true
        }

        # Check if MTR group is included
        if ($mtrGroup -and $mtrGroup.Id -in $policy.Conditions.Users.IncludeGroups) {
            $affectsMTR = $true
        }

        # Check if MTR group is excluded
        if ($mtrGroup -and $mtrGroup.Id -in $policy.Conditions.Users.ExcludeGroups) {
            $mtrExcluded = $true
        }

        # Check grant controls
        if ("mfa" -in $policy.GrantControls.BuiltInControls) {
            $requiresMFA = $true
            if ($affectsMTR -and -not $mtrExcluded) {
                $concerns += "Requires MFA (will block MTR)"
            }
        }

        if ("compliantDevice" -in $policy.GrantControls.BuiltInControls) {
            $requiresCompliant = $true
        }

        $result = [PSCustomObject]@{
            PolicyName        = $policy.DisplayName
            State             = $policy.State
            AffectsMTR        = $affectsMTR -and -not $mtrExcluded
            MTRExcluded       = $mtrExcluded
            RequiresMFA       = $requiresMFA
            RequiresCompliant = $requiresCompliant
            Concerns          = $concerns -join "; "
        }

        $results += $result

        # Report concerning policies
        if ($result.Concerns) {
            Write-Warning "$($policy.DisplayName): $($result.Concerns)"
        }
    }

    # Summary
    $affecting = ($results | Where-Object { $_.AffectsMTR }).Count
    $excluded = ($results | Where-Object { $_.MTRExcluded }).Count
    $mfaBlocking = ($results | Where-Object { $_.AffectsMTR -and $_.RequiresMFA }).Count

    Write-Information ""
    Write-Information "Summary"
    Write-Information "======="
    Write-Information "Total policies: $($results.Count)"
    Write-Information "Affecting MTR: $affecting"
    Write-Information "MTR excluded: $excluded"
    Write-Information "Blocking (MFA): $mfaBlocking"

    if ($mfaBlocking -gt 0) {
        Write-Warning ""
        Write-Warning "ACTION REQUIRED: $mfaBlocking policy(ies) require MFA and will block MTR sign-in."
        Write-Warning "Add MTR accounts to the exclusion list for these policies."
    }

    return $results
}
catch {
    Write-Error "Analysis failed: $_"
    throw
}

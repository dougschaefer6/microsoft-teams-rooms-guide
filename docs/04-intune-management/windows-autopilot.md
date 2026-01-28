# Windows Autopilot for Teams Rooms

## Overview

Windows Autopilot enables zero-touch deployment of Teams Rooms on Windows devices. Combined with MTR Autologin, you can deploy meeting rooms that are ready to use out of the box with no manual configuration.

## Prerequisites

### Licensing
- Microsoft 365 E3/E5 or equivalent (includes Intune)
- Teams Rooms Pro or Basic license
- Windows 10/11 IoT Enterprise license (OEM)

### Configuration Requirements
- Intune configured and operational
- Entra ID automatic enrollment enabled
- Resource accounts created with licenses
- Network connectivity to Microsoft services

### Hardware Requirements
- Windows Autopilot-capable device
- Certified for Teams Rooms
- Hardware ID registered with Microsoft

## Architecture

```
[Device Powers On]
        ↓
[Connects to Internet]
        ↓
[Downloads Autopilot Profile]
        ↓
[Joins Entra ID]
        ↓
[Enrolls in Intune]
        ↓
[Receives Policies & Apps]
        ↓
[Autologin Configures]
        ↓
[Ready for Meetings]
```

## Device Registration

### Method 1: OEM Registration (Recommended)

Request your hardware vendor to register devices before shipping:

1. Provide vendor with your tenant ID
2. Vendor extracts hardware IDs during manufacturing
3. Vendor uploads IDs to your Autopilot service
4. Devices arrive pre-registered

### Method 2: Partner Registration

Microsoft partners can register on your behalf:

1. Authorize partner in Partner Center
2. Partner extracts and uploads hardware IDs
3. Verify registration in Intune

### Method 3: Manual Registration

For existing devices or small quantities:

**Extract Hardware ID:**
```powershell
# Run on the device
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile "C:\Autopilot\AutopilotHWID.csv"
```

**Upload to Intune:**
1. Navigate to **Intune Admin Center** > **Devices** > **Enrollment**
2. Select **Windows enrollment** > **Devices**
3. Click **Import**
4. Upload the CSV file
5. Wait for processing (can take 15+ minutes)

### Hardware ID CSV Format

```csv
Device Serial Number,Windows Product ID,Hardware Hash,Group Tag,Assigned User
SERIALNUMBER001,,BASE64HASH==,MTR,
SERIALNUMBER002,,BASE64HASH==,MTR,
```

> **Tip:** Use the Group Tag `MTR` to identify Teams Rooms devices for dynamic group membership.

## Autopilot Deployment Profile

### Create Deployment Profile

1. Navigate to **Intune Admin Center** > **Devices** > **Enrollment**
2. Select **Windows enrollment** > **Deployment Profiles**
3. Click **Create profile** > **Windows PC**
4. Configure:

**Basics:**
- Name: `MTR-Autopilot-Profile`
- Description: `Autopilot profile for Microsoft Teams Rooms`

**Out-of-box experience (OOBE):**
- Deployment mode: **Self-Deploying** (recommended for MTR)
- Join to Entra ID as: **Entra ID joined**
- Microsoft Software License Terms: **Hide**
- Privacy settings: **Hide**
- Hide change account options: **Yes**
- User account type: **Standard**
- Allow pre-provisioned deployment: **No**

**Assignments:**
- Assign to group: **MTR-Autopilot-Devices** (dynamic group based on Group Tag)

### Self-Deploying Mode

Self-deploying mode is ideal for MTR because:
- No user credentials required during setup
- Device enrolls automatically
- No user interaction needed
- Fully automated process

**Requirements for self-deploying:**
- TPM 2.0
- Device attestation capability
- Ethernet connection recommended

### Dynamic Group for Autopilot Devices

Create a dynamic device group:

```
(device.devicePhysicalIds -any (_ -contains "[OrderID]:MTR"))
```

This captures devices with Group Tag "MTR".

## MTR Autologin Profile

### What is Autologin?

Autologin automatically signs in the resource account on the MTR device, eliminating manual credential entry.

### Configure Autologin

1. Navigate to **Intune Admin Center** > **Devices** > **Configuration profiles**
2. Click **Create profile**
3. Platform: **Windows 10 and later**
4. Profile type: **Templates** > **Custom**

**Settings:**
- Name: `MTR-Autologin-Profile`

**OMA-URI Settings:**

**Setting 1: Account Name**
- Name: `AutoLogonAccountName`
- OMA-URI: `./Device/Vendor/MSFT/Accounts/Users/mtr-roomname@contoso.com/LocalUserGroup`
- Data type: `Integer`
- Value: `2` (Standard user)

> **Note:** For Autologin, use a configuration service provider (CSP) or Windows Configuration Designer to set autologon credentials.

### Windows Configuration Designer Method

1. Install Windows Configuration Designer from Microsoft Store
2. Create new provisioning package
3. Add runtime settings:
   - `Accounts/ComputerAccount`
   - `SharedPC` settings
4. Export package
5. Deploy via Intune

### PowerShell-based Configuration

Create a PowerShell script for Autologin configuration:

```powershell
# Deploy via Intune PowerShell script
# This script configures autologon for the MTR resource account

param(
    [string]$Username,
    [string]$Domain,
    [string]$Password
)

# Set autologon registry keys
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $RegPath -Name "DefaultUserName" -Value $Username
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value $Domain
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value $Password

# Restart to apply
# Restart-Computer -Force
```

> **Security Note:** Storing passwords in scripts is not recommended for production. Use secure methods like Azure Key Vault or encrypted credentials.

## Enrollment Status Page

Configure the Enrollment Status Page (ESP) for MTR:

1. Navigate to **Intune Admin Center** > **Devices** > **Enrollment**
2. Select **Enrollment Status Page**
3. Click **Create**
4. Configure:
   - Show app and profile configuration progress: **Yes**
   - Show error when installation takes longer than: **60 minutes**
   - Allow users to reset device: **No**
   - Allow users to use device: **No** (wait for completion)
   - Block device use until required apps installed: **Yes**

Assign to MTR device group.

## Complete Deployment Flow

### Zero-Touch Process

1. **Receive device** from vendor (pre-registered)
2. **Connect to network** (Ethernet preferred)
3. **Power on device**
4. Device connects to internet
5. Autopilot profile downloads
6. Device joins Entra ID
7. Intune enrollment completes
8. Policies and apps deploy
9. Autologin configures
10. **MTR ready for meetings**

### Timeline

| Phase | Duration |
|-------|----------|
| OOBE and Autopilot | 5-10 minutes |
| Intune enrollment | 2-5 minutes |
| Policy application | 5-15 minutes |
| App installation | 10-20 minutes |
| **Total** | **25-50 minutes** |

## Troubleshooting

### Autopilot Not Starting

- Verify device is registered in Intune portal
- Check network connectivity
- Confirm hardware ID upload completed
- Verify Autopilot profile assigned

### Enrollment Failures

- Check ESP for error messages
- Review Intune enrollment logs
- Verify automatic enrollment configured
- Check device restrictions

### Autologin Not Working

- Verify resource account credentials
- Check account is enabled in Entra ID
- Confirm password not expired
- Review autologon registry settings

### Diagnostic Commands

```powershell
# Check Autopilot registration
dsregcmd /status

# View enrollment status
Get-WmiObject -Class MDM_DevDetail_Ext01 -Namespace root\cimv2\mdm\dmmap

# Check for pending reboot
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations
```

## Best Practices

1. **Use OEM registration** - Devices arrive ready to deploy
2. **Test with pilot devices** - Validate profile before production
3. **Use Ethernet** - More reliable than Wi-Fi during enrollment
4. **Configure ESP** - Ensure all apps install before use
5. **Document process** - Include network requirements for setup locations
6. **Monitor deployment** - Track enrollment status in Intune
7. **Plan for failures** - Have manual backup procedure

## Related Topics

- [Enrollment Overview](enrollment-overview.md)
- [Zero-Touch Deployment](../05-deployment/zero-touch-deployment.md)
- [Configuration Profiles](configuration-profiles.md)
- [Autopilot Profile Script](../../scripts/intune/New-MTRAutopilotProfile.ps1)

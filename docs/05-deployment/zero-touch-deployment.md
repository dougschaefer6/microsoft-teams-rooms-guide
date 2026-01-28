# Zero-Touch Deployment

## Overview

Zero-touch deployment enables automated provisioning of Microsoft Teams Rooms devices with minimal IT intervention. This guide covers the complete process for deploying Windows MTR devices using Windows Autopilot and Autologin.

## What is Zero-Touch Deployment?

Zero-touch deployment means:
- Device arrives pre-configured for your organization
- IT doesn't need to manually set up each device
- Device configures itself when connected to network
- Ready for meetings with no user interaction

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      ZERO-TOUCH FLOW                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  OEM     │───▶│ Autopilot│───▶│  Intune  │───▶│  MTR     │  │
│  │ Registers│    │ Enrolls  │    │ Configures│   │  Ready   │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       │               │               │               │         │
│       ▼               ▼               ▼               ▼         │
│  Hardware ID     Entra ID Join   Policies &      Autologin     │
│  uploaded        automatic       apps deploy     completes     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Tenant Configuration

- [ ] Entra ID P1/P2 (for Conditional Access)
- [ ] Intune license (included with M365 E3/E5)
- [ ] Teams Rooms Pro license
- [ ] Automatic Intune enrollment enabled

### Autopilot Configuration

- [ ] Autopilot deployment profile created
- [ ] Self-deploying mode configured
- [ ] Enrollment Status Page configured
- [ ] Device group tag defined (e.g., "MTR")

### Account Preparation

- [ ] Resource accounts created
- [ ] Licenses assigned
- [ ] Calendar processing configured
- [ ] Passwords documented securely

### Conditional Access

- [ ] MTR accounts excluded from MFA policies
- [ ] MTR-specific CA policy created
- [ ] Compliance policy ready

## Setup Procedure

### Step 1: Configure Autopilot Profile

Create self-deploying mode profile:

1. Navigate to **Intune Admin Center** > **Devices** > **Windows enrollment**
2. Select **Deployment Profiles** > **Create profile**
3. Configure:

```
Name: MTR-Autopilot-ZeroTouch
Deployment mode: Self-Deploying
Join to Entra ID as: Entra ID joined
Microsoft Software License Terms: Hide
Privacy settings: Hide
Hide change account options: Yes
User account type: Standard
Allow pre-provisioned deployment: No
Language: Operating system default
Automatically configure keyboard: Yes
Apply device name template: Yes
Name template: MTR-%SERIAL%
```

### Step 2: Create Dynamic Device Group

```
Group name: MTR-Autopilot-Devices
Membership type: Dynamic device
Rule: (device.devicePhysicalIds -any (_ -contains "[OrderID]:MTR"))
```

### Step 3: Configure Enrollment Status Page

1. Navigate to **Devices** > **Windows enrollment** > **Enrollment Status Page**
2. Create profile:

```
Name: MTR-ESP
Show app and profile configuration progress: Yes
Show error when installation takes longer than: 90 minutes
Show custom message when time limit or error occur: Yes
Custom message: "Teams Rooms device is being configured..."
Allow users to collect logs: Yes
Only show page to OOBE devices: Yes
Block device use until all apps and profiles are installed: Yes
Allow users to reset device: No
Allow users to use device if installation error occurs: No
Block device use until required apps are installed: Yes
Selected apps: Microsoft Teams Rooms (if deploying via Intune)
```

### Step 4: Configure Autologin

Create configuration profile for autologin:

**Method 1: Custom OMA-URI**

```
Platform: Windows 10 and later
Profile type: Custom

Setting 1:
Name: AutoLogon
OMA-URI: ./Device/Vendor/MSFT/Policy/Config/Authentication/AllowAadPasswordReset
Data type: Integer
Value: 1
```

**Method 2: PowerShell Script Deployment**

Deploy script via Intune:

```powershell
# Script deployed to configure autologon
# Variables replaced during deployment
$resourceAccount = "{{ResourceAccountUPN}}"
$resourcePassword = "{{ResourceAccountPassword}}"

# Configure autologon
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $registryPath -Name "DefaultUserName" -Value $resourceAccount
Set-ItemProperty -Path $registryPath -Name "DefaultPassword" -Value $resourcePassword
Set-ItemProperty -Path $registryPath -Name "AutoAdminLogon" -Value "1"
```

> **Security Note:** For production, use secure credential storage like Azure Key Vault with appropriate retrieval mechanisms.

### Step 5: Assign Profiles

Assign all profiles to the dynamic device group:

| Profile | Target Group |
|---------|--------------|
| Autopilot deployment | MTR-Autopilot-Devices |
| ESP | MTR-Autopilot-Devices |
| Compliance policy | MTR-Autopilot-Devices |
| Configuration profiles | MTR-Autopilot-Devices |
| Autologin script | MTR-Autopilot-Devices |

### Step 6: Register Devices

**OEM Registration (Recommended):**
1. Provide tenant ID to hardware vendor
2. Request devices be registered with group tag "MTR"
3. Devices ship pre-registered

**Manual Registration:**
```powershell
# On device, extract hardware ID
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile C:\AutopilotHWID.csv -GroupTag "MTR"

# Upload CSV to Intune
```

## Deployment Process

### What Happens When Device Powers On

1. **Device boots** and connects to internet
2. **Autopilot service contacted** - Device downloads profile
3. **OOBE skipped** - Self-deploying mode bypasses user prompts
4. **Entra ID join** - Device joins automatically
5. **Intune enrollment** - Device enrolls for management
6. **Policies applied** - Configuration profiles deploy
7. **ESP waits** - Required apps install
8. **Autologin executes** - Resource account signs in
9. **Teams Rooms launches** - Device ready for meetings

### Timeline

| Phase | Typical Duration |
|-------|------------------|
| Boot and OOBE | 3-5 minutes |
| Autopilot detection | 1-2 minutes |
| Entra ID join | 1-2 minutes |
| Intune enrollment | 2-3 minutes |
| Policy deployment | 5-10 minutes |
| App installation | 10-20 minutes |
| Autologin and finalization | 2-5 minutes |
| **Total** | **25-45 minutes** |

## Vendor Coordination

### Information for Hardware Vendors

Provide vendors with:
- Tenant ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- Group tag: `MTR`
- Deployment requirements: Self-deploying mode

### Pre-Ship Testing

Request vendor perform:
- Network connectivity test
- Hardware ID extraction
- Registration confirmation

## Scaling Zero-Touch

### For Large Deployments

1. **Batch device orders** by location/building
2. **Pre-create resource accounts** in bulk
3. **Standardize naming** (MTR-Building-Room)
4. **Coordinate shipping** with IT readiness
5. **Document deployment status** per device

### Automation Opportunities

```powershell
# Example: Bulk resource account creation
$rooms = Import-Csv "rooms.csv"
foreach ($room in $rooms) {
    # Create account
    # Assign license
    # Configure calendar processing
    # Document credentials
}
```

## Troubleshooting

### Autopilot Not Detecting Device

- Verify device registered in Intune portal
- Check group tag matches dynamic group rule
- Confirm network connectivity
- Check for firewall blocking Autopilot endpoints

### ESP Timeout

- Review required apps list
- Check app deployment status
- Extend timeout if needed
- Verify network bandwidth

### Autologin Not Working

- Confirm script deployment succeeded
- Verify resource account credentials
- Check account enabled in Entra ID
- Review password policy (non-expiring)

### Device Stuck in OOBE

- Verify self-deploying mode configured
- Check TPM 2.0 available
- Confirm device attestation capability
- Try Ethernet instead of Wi-Fi

## Validation

### Per-Device Checklist

- [ ] Device shows in Intune as enrolled
- [ ] Compliance state: Compliant
- [ ] All profiles: Succeeded
- [ ] Teams Rooms app running
- [ ] Resource account signed in
- [ ] Calendar displaying
- [ ] Meeting join working

### Dashboard Monitoring

Monitor deployment progress via:
- Intune device list
- Autopilot deployment status
- ESP completion reports
- Teams Admin Center device list

## Best Practices

1. **Start with pilot** - Test with 5-10 devices first
2. **Use Ethernet** - More reliable during deployment
3. **Coordinate with facilities** - Network drops, power
4. **Document each deployment** - Track serial numbers and rooms
5. **Monitor actively** - Watch for failures during rollout
6. **Have backup procedure** - Manual deployment as fallback
7. **Pre-stage network** - Ensure drops active before device arrival
8. **Test end-to-end** - Verify meeting join after deployment

## Related Topics

- [Windows Autopilot](../04-intune-management/windows-autopilot.md)
- [Windows Deployment](windows-deployment.md)
- [Resource Accounts](../02-prerequisites/resource-accounts.md)
- [Enrollment Overview](../04-intune-management/enrollment-overview.md)

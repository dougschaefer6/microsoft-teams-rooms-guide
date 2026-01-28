# Configuration Profiles for Teams Rooms

## Overview

Intune configuration profiles customize device settings for Microsoft Teams Rooms. This guide covers recommended profiles for both Windows and Android MTR platforms.

## Windows Configuration Profiles

### Device Restrictions

Control device functionality and security settings.

**Create Profile:**
1. **Intune Admin Center** > **Devices** > **Configuration profiles**
2. **Create profile**
3. Platform: **Windows 10 and later**
4. Profile type: **Device restrictions**

**Recommended Settings:**

| Category | Setting | Value | Reason |
|----------|---------|-------|--------|
| General | Screen capture | Allow | Support sharing |
| App Store | Block access | Yes | Prevent unauthorized apps |
| Password | Required | No | Kiosk mode, no user password |
| Reporting | Send diagnostic data | Full | Monitoring/troubleshooting |
| Cloud | Microsoft account | Block | Prevent personal accounts |

### Windows Update Settings

Control when and how updates install.

**Create Profile:**
1. Platform: **Windows 10 and later**
2. Profile type: **Update rings for Windows 10 and later**

**Recommended Settings:**

| Setting | Value | Reason |
|---------|-------|--------|
| Quality update deferral | 7 days | Test before production |
| Feature update deferral | 30 days | Allow time for compatibility |
| Automatic update behavior | Auto download, notify to install | Control timing |
| Maintenance window start | 2:00 AM | Outside business hours |
| Active hours start | 7:00 AM | Protect meeting times |
| Active hours end | 7:00 PM | Protect meeting times |

### Wi-Fi Profile

Configure enterprise Wi-Fi (if not using Ethernet).

**Create Profile:**
1. Profile type: **Wi-Fi**

**Settings:**
- Network name: Corporate SSID
- Security type: WPA2-Enterprise
- EAP type: PEAP or EAP-TLS
- Authentication method: Certificate or credentials

### VPN Profile

If MTR devices need VPN access:

**Create Profile:**
1. Profile type: **VPN**

> **Note:** VPN is rarely needed for MTR devices on corporate networks. Use only if required for your network architecture.

### Endpoint Protection

Defender and firewall settings.

**Create Profile:**
1. Profile type: **Endpoint protection**

**Defender Settings:**
- Real-time protection: Enable
- Cloud protection: Enable
- Scan schedule: Daily at 2:00 AM
- Quick scan: Yes

**Firewall Settings:**
- Firewall enabled: Yes (all profiles)
- Stealth mode: Yes
- Required inbound traffic: Allow Teams ports

### Custom Profile (OMA-URI)

For settings not available in templates.

**Common Custom Settings for MTR:**

**Disable Cortana:**
```
OMA-URI: ./Device/Vendor/MSFT/Policy/Config/Experience/AllowCortana
Data type: Integer
Value: 0
```

**Disable Consumer Features:**
```
OMA-URI: ./Device/Vendor/MSFT/Policy/Config/Experience/AllowWindowsConsumerFeatures
Data type: Integer
Value: 0
```

**Configure Power Settings:**
```
OMA-URI: ./Device/Vendor/MSFT/Policy/Config/Power/DisplayOffTimeoutPluggedIn
Data type: Integer
Value: 0 (never)
```

## Android Configuration Profiles

### Device Restrictions (AOSP)

**Create Profile:**
1. Platform: **Android (AOSP)**
2. Profile type: **Device restrictions**

**Recommended Settings:**

| Setting | Value | Reason |
|---------|-------|--------|
| Camera | Allow | Required for video |
| Microphone | Allow | Required for audio |
| Screen capture | Per policy | Security consideration |
| Factory reset | Block | Prevent unauthorized reset |
| USB file transfer | Block | Security |
| Bluetooth | Allow | Peripheral support |
| NFC | Allow or Block | Per requirements |

### Wi-Fi (AOSP)

**Create Profile:**
1. Profile type: **Wi-Fi**

**Settings:**
- Network name: Corporate SSID
- Connect automatically: Yes
- Security type: Per network requirements
- Hidden network: If applicable

## Profile Assignment

### Device Groups

Assign profiles to dynamic or assigned device groups:

**MTR Windows Devices:**
```
(device.deviceOSType -eq "Windows") and (device.displayName -startsWith "MTR-")
```

**MTR Android Devices:**
```
(device.deviceOSType -contains "Android") and (device.deviceCategory -eq "Teams Rooms")
```

### Scope Tags

Use scope tags if managing multiple tenants or delegating administration:

1. Create scope tag: `TeamsRooms`
2. Assign to profiles
3. Assign to admin roles

### Assignment Filters

Use filters for more precise targeting:

```
(device.enrollmentProfileName -eq "MTR-Autopilot-Profile")
```

## Profile Conflicts

### Detecting Conflicts

When multiple profiles target the same device with conflicting settings:

1. **Intune Admin Center** > **Devices** > Select device
2. View **Configuration status**
3. Check for **Conflict** status

### Resolution Priority

1. Last applied typically wins
2. Most specific assignment wins
3. Explicit values override defaults

### Best Practices for Avoiding Conflicts

1. **Use dedicated profiles** for MTR
2. **Don't overlap assignments** with user device profiles
3. **Document all settings** and their purposes
4. **Test in pilot group** first
5. **Review conflict reports** regularly

## Settings Catalog

The Settings Catalog provides access to all available settings:

1. **Create profile**
2. Profile type: **Settings catalog**
3. Search for specific settings
4. Add to profile

**Useful Settings for MTR:**

| Category | Setting |
|----------|---------|
| Experience | Allow Cortana |
| Start | Hide App List |
| Power | Display timeout (plugged in) |
| Privacy | Allow Input Personalization |
| Windows Defender | Real-time Monitoring |

## Administrative Templates

Use Administrative Templates for Group Policy-equivalent settings:

1. **Create profile**
2. Profile type: **Administrative Templates**
3. Configure ADMX-backed settings

**Useful for MTR:**
- Power management
- Windows Update behavior
- Start menu/Taskbar customization

## Monitoring Profile Status

### Per-Profile View

1. Select profile in Configuration profiles
2. View **Device status** and **User status**
3. Check for Succeeded, Pending, Failed, Error

### Per-Device View

1. **Devices** > **All devices** > Select device
2. **Device configuration**
3. View all assigned profiles and status

### Reports

1. **Reports** > **Device configuration**
2. Generate reports:
   - Assignment failures
   - Profiles per platform
   - Setting compliance

## Troubleshooting Profiles

### Profile Not Applying

| Symptom | Cause | Solution |
|---------|-------|----------|
| Status: Pending | Sync delay | Force sync |
| Status: Not applicable | Wrong platform/group | Check assignment |
| Status: Error | Invalid setting | Review profile configuration |
| Status: Conflict | Multiple profiles | Review and consolidate |

### Force Sync

**Windows:**
```powershell
# Force Intune sync
$EnrollmentID = Get-ScheduledTask | Where-Object {$_.TaskPath -like "*Microsoft*Enrollment*"} | Select -First 1
Start-ScheduledTask -TaskName $EnrollmentID.TaskName -TaskPath $EnrollmentID.TaskPath
```

**Via Intune:**
1. Select device
2. Click **Sync**

## Best Practices

1. **Separate MTR profiles** from user device profiles
2. **Use descriptive names** (e.g., `MTR-Windows-DeviceRestrictions`)
3. **Document settings** and rationale
4. **Test before deployment** with pilot group
5. **Monitor deployment** after rollout
6. **Review regularly** for needed updates
7. **Use Settings Catalog** for granular control

## Related Topics

- [Compliance Policies](compliance-policies.md)
- [Windows Autopilot](windows-autopilot.md)
- [Android AOSP](android-aosp.md)

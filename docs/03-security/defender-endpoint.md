# Microsoft Defender for Endpoint on Teams Rooms

## Overview

Microsoft Defender for Endpoint (MDE) provides advanced threat protection for Windows-based Teams Rooms devices. Proper configuration ensures security monitoring without impacting meeting room functionality.

## Platform Support

| Platform | MDE Support |
|----------|-------------|
| Windows MTR | Full support |
| Android MTR | Not supported |
| Teams Panels | Not supported |

## Prerequisites

### Licensing

MDE for Teams Rooms requires:
- Microsoft 365 E5, or
- Microsoft 365 E5 Security, or
- Microsoft Defender for Endpoint Plan 2

> **Note:** Teams Rooms Pro license does not include MDE. Separate licensing required.

### Requirements

- Windows 10/11 IoT Enterprise
- Internet connectivity to Microsoft security services
- Device enrolled in Intune (recommended)

## Onboarding Methods

### Method 1: Intune (Recommended)

Use Intune to deploy MDE configuration:

1. Navigate to **Intune Admin Center** > **Endpoint security** > **Endpoint detection and response**
2. Click **Create policy**
3. Select **Platform: Windows 10, Windows 11, and Windows Server**
4. Select **Profile: Endpoint detection and response**
5. Configure:
   - Sample sharing: **Send all samples**
   - Expedite telemetry reporting: **Yes**
6. Assign to **MTR-Devices-Windows** group

### Method 2: Local Configuration Package

For devices not managed by Intune:

1. Download onboarding package from Microsoft 365 Defender portal
2. Copy to MTR device
3. Run as administrator:

```powershell
# Extract and run onboarding script
.\WindowsDefenderATPLocalOnboardingScript.cmd
```

### Method 3: Group Policy

For domain-joined MTR devices:

1. Download Group Policy onboarding package
2. Import ADMX templates
3. Configure via GPO:
   - Computer Configuration > Administrative Templates > Windows Components > Microsoft Defender ATP

## Configuration Recommendations

### Antivirus Settings

Configure Defender Antivirus for MTR:

```powershell
# Configure Defender AV settings
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -ScanScheduleDay 0  # Every day
Set-MpPreference -ScanScheduleTime "02:00:00"  # 2 AM
Set-MpPreference -ScanParameters 1  # Quick scan
Set-MpPreference -RemediationScheduleDay 0
Set-MpPreference -SignatureUpdateInterval 4  # Every 4 hours
```

### Exclusions (If Needed)

Add exclusions for Teams Rooms application if experiencing performance issues:

```powershell
# Process exclusions
Add-MpPreference -ExclusionProcess "Microsoft.SkypeRoomSystem.exe"

# Path exclusions (if needed)
Add-MpPreference -ExclusionPath "C:\Users\Skype\AppData\Local\Packages\Microsoft.SkypeRoomSystem*"
```

> **Caution:** Only add exclusions if experiencing documented issues. Exclusions reduce protection.

### Attack Surface Reduction (ASR)

Configure ASR rules for MTR:

```powershell
# Enable recommended ASR rules
# Block executable content from email and webmail
Set-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 -AttackSurfaceReductionRules_Actions Enabled

# Block Office apps from creating child processes
Set-MpPreference -AttackSurfaceReductionRules_Ids D4F940AB-401B-4EFC-AADC-AD5F3C50688A -AttackSurfaceReductionRules_Actions Enabled

# Block credential stealing from LSASS
Set-MpPreference -AttackSurfaceReductionRules_Ids 9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2 -AttackSurfaceReductionRules_Actions Enabled
```

### Network Protection

Enable network protection for web threat blocking:

```powershell
Set-MpPreference -EnableNetworkProtection Enabled
```

## Intune Endpoint Security Policies

### Endpoint Detection and Response

Create EDR policy in Intune:

1. **Intune Admin Center** > **Endpoint security** > **Endpoint detection and response**
2. Create policy for Windows
3. Configure:
   - Microsoft Defender for Endpoint client configuration package type: **Automatic from connector**
   - Sample sharing: **All**
   - Expedite telemetry reporting frequency: **Yes**

### Antivirus Policy

Create antivirus policy:

1. **Intune Admin Center** > **Endpoint security** > **Antivirus**
2. Create policy for Windows
3. Configure:
   - Real-time protection: **Enable**
   - Cloud-delivered protection: **Enable**
   - Cloud-delivered protection level: **High**
   - Scan type: **Quick scan**
   - Scheduled scan time: **2:00 AM**
   - Signature update interval: **4 hours**

### Firewall Policy

Configure firewall for MTR:

1. **Intune Admin Center** > **Endpoint security** > **Firewall**
2. Create policy
3. Configure:
   - Enable stateful FTP: **Yes**
   - Domain profile firewall: **Enable**
   - Private profile firewall: **Enable**
   - Public profile firewall: **Enable**

## Monitoring

### Microsoft 365 Defender Portal

Access device security status:

1. Navigate to **security.microsoft.com**
2. Go to **Assets** > **Devices**
3. Filter by device name (MTR devices)
4. Review:
   - Exposure score
   - Active alerts
   - Security recommendations
   - Discovered vulnerabilities

### Device Page

For each MTR device, view:
- Timeline of activities
- Alerts and incidents
- Security recommendations
- Software inventory
- Discovered vulnerabilities

### Alert Monitoring

Configure alert notifications:

1. **Settings** > **Endpoints** > **Email notifications**
2. Create notification rule for MTR devices
3. Configure recipients and alert severity levels

## Threat & Vulnerability Management

### Security Recommendations

Review TVM recommendations for MTR devices:
- OS updates
- Application updates
- Security configurations
- Vulnerable software

### Vulnerability Assessment

Regular vulnerability scans identify:
- Missing security updates
- Vulnerable software versions
- Misconfigurations

## Incident Response

### Automated Investigation

MDE can automatically investigate alerts:
- Automated investigation enabled by default
- Review pending actions in Action Center
- Approve/reject remediation actions

### Response Actions

Available response actions for MTR devices:
- Run antivirus scan
- Collect investigation package
- Isolate device (use cautiously - disrupts meetings)
- Restrict app execution

> **Warning:** Device isolation will disrupt Teams Rooms functionality. Use only for confirmed security incidents.

## Troubleshooting

### Verify Onboarding

```powershell
# Check onboarding status
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status"
Get-ItemProperty -Path $registryPath | Select OnboardingState

# OnboardingState = 1 means onboarded
```

### Check Service Status

```powershell
# Verify Defender services
Get-Service -Name "Sense", "WinDefend", "WdNisSvc" | Select Name, Status

# Check connectivity
Test-NetConnection -ComputerName "winatp-gw-wus.microsoft.com" -Port 443
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Not onboarding | Firewall blocking | Allow MDE URLs |
| High resource usage | Full scan during meeting | Schedule scans off-hours |
| Performance impact | Real-time scanning | Add targeted exclusions |
| No alerts visible | Onboarding incomplete | Re-run onboarding script |

### Required URLs

Ensure these URLs are accessible:

```
*.securitycenter.windows.com
*.security.microsoft.com
*.wdcp.microsoft.com
*.wd.microsoft.com
*.microsoftonline.com
```

## Best Practices

1. **Use Intune for deployment** - Consistent configuration and monitoring
2. **Schedule scans during off-hours** - Minimize impact on meetings
3. **Monitor security recommendations** - Keep devices secure
4. **Configure appropriate exclusions** - Balance security and performance
5. **Enable automatic investigation** - Reduce manual effort
6. **Review alerts regularly** - Don't let alerts accumulate
7. **Test thoroughly** - Verify no impact on meeting functionality
8. **Maintain licensing** - Ensure MDE licenses are assigned

## Related Topics

- [Device Compliance](device-compliance.md)
- [Windows Deployment](../05-deployment/windows-deployment.md)
- [Troubleshooting](../06-post-deployment/troubleshooting.md)

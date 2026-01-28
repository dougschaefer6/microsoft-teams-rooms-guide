# Teams Rooms Pro Management Portal

## Overview

The Microsoft Teams Rooms Pro Management portal provides advanced monitoring, management, and analytics for Teams Rooms devices. It's included with the Teams Rooms Pro license.

## Accessing the Portal

### URL

Navigate to: **https://portal.rooms.microsoft.com**

### Required Permissions

Access requires one of these roles:
- Teams Administrator
- Teams Devices Administrator
- Global Administrator

### Licensing Requirement

- **Teams Rooms Pro** license required for full functionality
- Basic license provides limited access

## Dashboard Overview

### Home Dashboard

The main dashboard displays:
- **Health summary** - Device status overview
- **Active incidents** - Current issues requiring attention
- **Alerts** - Recent notifications
- **Device distribution** - Breakdown by status

### Health States

| State | Icon | Meaning |
|-------|------|---------|
| Healthy | Green checkmark | Device operating normally |
| Non-urgent | Yellow warning | Minor issue detected |
| Critical | Red alert | Requires immediate attention |
| Offline | Gray circle | Device not communicating |

## Device Management

### Viewing Devices

1. Navigate to **Rooms** in left menu
2. View all enrolled devices
3. Filter by:
   - Health state
   - Location
   - Platform
   - Tags

### Device Details

Click on a device to view:
- **Overview** - Health, status, account
- **Health** - Current and historical health
- **Incidents** - Active and resolved issues
- **Activity** - Meeting participation
- **Settings** - Device configuration

### Device Actions

Available actions:
- **Restart** - Remote restart
- **Collect logs** - Gather diagnostic data
- **Update** - Push software updates
- **Ring** - Play sound to locate device
- **Edit** - Modify device configuration

## Incident Management

### Incident Types

The portal automatically detects incidents:

| Category | Examples |
|----------|----------|
| **Hardware** | Camera failure, microphone issue, display problem |
| **Software** | App crash, update failure, sign-in issue |
| **Network** | Connectivity loss, high latency |
| **Account** | Authentication failure, license issue |

### Incident Lifecycle

1. **Detected** - System identifies issue
2. **Active** - Incident being tracked
3. **Investigating** - (Optional) Admin reviewing
4. **Resolved** - Issue fixed

### Managing Incidents

1. Navigate to **Incidents** > **Active**
2. Select incident
3. View details:
   - Affected device
   - Issue description
   - Recommended actions
   - Timeline
4. Take action or acknowledge

## Health Monitoring

### Real-Time Telemetry

The portal collects:
- Device status
- Component health
- Meeting metrics
- Network quality

### Health Signals

| Signal | What It Monitors |
|--------|------------------|
| **App** | Teams Rooms application status |
| **Audio** | Microphone and speaker health |
| **Camera** | Video device functionality |
| **Display** | Screen connectivity and status |
| **Network** | Connectivity and performance |
| **Sign-in** | Authentication status |

### Health History

View historical health:
1. Select device
2. Navigate to **Health** tab
3. View timeline of health states
4. Analyze patterns for recurring issues

## Analytics and Reporting

### Meeting Insights

View meeting metrics:
- Meetings hosted per device
- Meeting duration statistics
- Participant counts
- Feature usage

### Usage Reports

Available reports:
- Device utilization
- Meeting frequency
- Feature adoption
- Health trends

### Exporting Data

1. Navigate to report
2. Click **Export**
3. Select format (CSV, Excel)
4. Download data

## Configuration Management

### Remote Settings

Configure devices remotely:

| Setting | Description |
|---------|-------------|
| Device name | Display name for the room |
| Meeting defaults | Default meeting behaviors |
| Theme | UI theme and branding |
| Audio/Video | Default peripheral settings |

### Bulk Updates

Update multiple devices:
1. Select multiple devices
2. Choose **Bulk action**
3. Select setting to change
4. Apply to all selected

### Configuration Profiles

Create profiles for consistent settings:
1. Navigate to **Settings** > **Configuration profiles**
2. Create profile with desired settings
3. Assign to device groups

## Software Updates

### Update Management

Control when devices update:
- **Auto** - Updates install automatically
- **Manual** - Admin approves updates
- **Deferred** - Delay updates for testing

### Update Rings

Create update groups:
- **Pilot** - Early updates (1-5 devices)
- **Production** - After pilot validation
- **Deferred** - Critical rooms, delayed updates

### Viewing Update Status

1. Navigate to **Updates**
2. View:
   - Current versions
   - Available updates
   - Update history
   - Failed updates

## Alerting

### Alert Configuration

Configure notifications for:
- Critical health incidents
- Device offline events
- Repeated issues
- Update failures

### Alert Channels

Send alerts via:
- Email
- Teams channel (webhook)
- Third-party integration

### Setting Up Alerts

1. Navigate to **Settings** > **Alerts**
2. Configure:
   - Alert conditions
   - Recipients
   - Notification frequency

## Inventory Management

### Device Inventory

Track device information:
- Serial numbers
- Hardware details
- Firmware versions
- Installation dates
- Locations

### Location Management

Organize by location:
1. **Settings** > **Locations**
2. Create location hierarchy:
   - Region
   - Building
   - Floor
   - Room

### Tags

Apply custom tags:
- By department
- By use case
- By support tier
- Custom categories

## Integration

### Microsoft 365

Integrated with:
- Teams Admin Center
- Microsoft 365 Admin Center
- Entra ID
- Intune

### Third-Party

Connect to:
- ServiceNow
- Other ITSM tools
- Monitoring platforms

## Best Practices

1. **Check dashboard daily** - Catch issues early
2. **Resolve incidents promptly** - Don't let issues accumulate
3. **Use locations and tags** - Organize for easy management
4. **Configure alerts** - Get notified of critical issues
5. **Review analytics** - Understand usage patterns
6. **Manage updates** - Use rings for safe updates
7. **Document processes** - Train team on portal usage

## Troubleshooting

### Device Not Showing

- Verify Teams Rooms Pro license
- Check device is online
- Confirm device enrolled correctly

### Telemetry Not Updating

- Check device connectivity
- Verify firewall allows telemetry endpoints
- Restart device

### Alerts Not Working

- Verify alert configuration
- Check recipient email settings
- Test with manual alert

## Related Topics

- [Teams Admin Center](teams-admin-center.md)
- [Monitoring and Alerting](monitoring-alerting.md)
- [Updates and Maintenance](updates-maintenance.md)

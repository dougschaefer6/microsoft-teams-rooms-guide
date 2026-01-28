# Teams Panels Deployment

## Overview

Microsoft Teams Panels are wall-mounted touchscreen displays that show room scheduling information outside meeting rooms. They integrate with Exchange calendars and can be paired with Teams Rooms devices.

## What Teams Panels Do

- Display room availability (available/busy/reserved)
- Show upcoming meetings
- Enable ad-hoc room booking
- Display meeting details (optional)
- Integrate with Teams Rooms for coordinated experience

## Panel Types

Teams Panels are Android-based devices from certified vendors:

| Vendor | Models |
|--------|--------|
| Poly | TC10 Panel |
| Logitech | Tap Scheduler |
| Yealink | RoomPanel, RoomPanel Plus |
| Neat | Neat Pad (as Panel) |
| Crestron | TSS-770, TSS-1070 |

## Prerequisites

### Licensing

- **Shared Device License** for basic functionality
- **Teams Rooms Pro/Basic** if pairing with Teams Rooms device

> **Note:** Teams Panels can use a shared device license when not paired with a Teams Room.

### Resource Account

Panels use the same resource account as the paired Teams Room, or a dedicated resource account if standalone.

### Network

- Ethernet via PoE (recommended)
- Wi-Fi supported
- Same endpoint requirements as MTR

## Deployment Steps

### Step 1: Physical Installation

1. **Mount panel** next to room entrance
   - Standard height for accessibility
   - Wall mount bracket included

2. **Connect cabling**
   - **PoE**: Single Ethernet cable (power + data)
   - **Non-PoE**: Ethernet + power adapter

### Step 2: Initial Setup

1. **Power on panel**
   - Screen lights up
   - Boot process begins

2. **Complete setup wizard**
   - Select language
   - Connect to network
   - Accept license terms

3. **Select device type**
   - Choose "Microsoft Teams Panel"

### Step 3: Sign In

1. **Enter resource account**
   - UPN: `mtr-room@contoso.com` (same as paired room)
   - Password: Account password

2. **Complete sign-in**
   - Calendar syncs
   - Room schedule appears

### Step 4: Panel Configuration

Access settings via admin menu:

1. **Tap screen** corners in sequence (vendor-specific)
2. **Enter admin password**

**Configure:**

| Setting | Configuration |
|---------|---------------|
| Room name | Verify matches resource account |
| Theme | Light/Dark/Auto |
| Display settings | Brightness, timeout |
| Booking | Ad-hoc booking enabled/disabled |
| Meeting details | Show/hide meeting details |

## Pairing with Teams Room

When pairing Panel with Teams Room:

### Requirements

- Same resource account on both devices
- Both on same network
- Room coordination enabled in Teams Admin Center

### Configuration

1. **Teams Admin Center** > **Teams devices** > **Panels**
2. Select panel
3. Configure pairing settings
4. Enable room coordination

### Coordinated Features

- Panel reflects room status
- Booking from panel appears on room device
- Consistent availability display

## Intune Management

### Enrollment

Teams Panels support Android Enterprise enrollment:

1. **Factory reset** if needed
2. **Follow AOSP/Android enrollment** process
3. Apply configuration policies

### Configuration Profile

Create panel-specific configuration:

```
Platform: Android Enterprise
Profile: Device restrictions
```

**Settings:**
- Screen timeout
- System update settings
- Network configuration

## Teams Admin Center Management

### Device Management

1. Navigate to **Teams devices** > **Panels**
2. View all enrolled panels
3. Per-device options:
   - Restart
   - Update software
   - View health
   - Edit configuration

### Bulk Operations

- Update multiple panels
- Apply configuration changes
- Generate health reports

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Panel offline | Check network, PoE connection |
| Calendar not showing | Verify account, check Exchange connectivity |
| Wrong room displayed | Verify resource account |
| Booking not working | Check calendar processing settings |
| Display issues | Adjust brightness, check power |

### Factory Reset

If needed to start over:

1. **Access admin settings**
2. **Select Reset** or **Factory Reset**
3. **Confirm** action
4. **Re-run setup**

### LED Indicators

Most panels have LED status indicators:

| LED State | Meaning |
|-----------|---------|
| Green | Room available |
| Red | Room busy/booked |
| Amber/Yellow | Meeting ending soon |
| Blinking | Starting up or updating |

## Best Practices

1. **Use PoE** for cleaner installation
2. **Mount at appropriate height** for accessibility
3. **Use same account** as paired room
4. **Configure ad-hoc booking** per organization policy
5. **Test booking flow** after deployment
6. **Keep firmware updated** for security
7. **Document admin passwords** securely

## Validation Checklist

After deployment, verify:

- [ ] Panel showing correct room name
- [ ] Calendar displaying meetings
- [ ] Availability status accurate (green/red)
- [ ] Ad-hoc booking works (if enabled)
- [ ] Panel online in Teams Admin Center
- [ ] Paired with Teams Room (if applicable)

## Related Topics

- [Android Deployment](android-deployment.md)
- [Resource Accounts](../02-prerequisites/resource-accounts.md)
- [Exchange Configuration](../02-prerequisites/exchange-configuration.md)

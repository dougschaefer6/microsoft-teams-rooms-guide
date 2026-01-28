# Exchange Configuration

## Overview

Proper Exchange Online configuration ensures Teams Rooms devices can access calendars, display meeting information, and integrate with room booking workflows. This guide covers mailbox settings, calendar processing, and room list configuration.

## Room Mailbox Settings

### Basic Configuration

After creating a room mailbox, configure essential settings:

```powershell
# Connect to Exchange Online
Connect-ExchangeOnline

# Set room mailbox properties
Set-Mailbox -Identity "mtr-hq-101@contoso.com" `
    -Type Room `
    -RoomMailboxPassword (ConvertTo-SecureString -String "Password" -AsPlainText -Force) `
    -EnableRoomMailboxAccount $true
```

### Room Capacity

Set room capacity for scheduling purposes:

```powershell
Set-Place -Identity "mtr-hq-101@contoso.com" `
    -Capacity 10 `
    -Building "Headquarters" `
    -Floor 1 `
    -FloorLabel "First Floor" `
    -City "Seattle" `
    -State "WA" `
    -CountryOrRegion "US" `
    -AudioDeviceName "Poly Studio X50" `
    -VideoDeviceName "Poly Studio X50" `
    -DisplayDeviceName "Samsung 65-inch Display" `
    -IsWheelChairAccessible $true
```

### Room Features and Tags

Add features to help users find appropriate rooms:

```powershell
Set-Place -Identity "mtr-hq-101@contoso.com" `
    -Tags @("Teams Room", "Video Conferencing", "Whiteboard") `
    -MTREnabled $true
```

## Calendar Processing

Calendar processing rules determine how the room mailbox handles meeting requests.

### Recommended Settings for MTR

```powershell
Set-CalendarProcessing -Identity "mtr-hq-101@contoso.com" `
    -AutomateProcessing AutoAccept `
    -AddOrganizerToSubject $false `
    -AllowConflicts $false `
    -DeleteAttachments $true `
    -DeleteComments $false `
    -DeleteNonCalendarItems $true `
    -DeleteSubject $false `
    -ProcessExternalMeetingMessages $true `
    -RemovePrivateProperty $false `
    -AddAdditionalResponse $true `
    -AdditionalResponse "This is a Microsoft Teams Room. The meeting will be displayed on the room device."
```

### Settings Reference

| Setting | Recommended | Description |
|---------|-------------|-------------|
| `AutomateProcessing` | AutoAccept | Automatically accept/decline requests |
| `AddOrganizerToSubject` | $false | Keeps original meeting subject |
| `AllowConflicts` | $false | Prevents double-booking |
| `DeleteAttachments` | $true | Removes attachments from invites |
| `DeleteComments` | $false | Preserves meeting notes |
| `DeleteSubject` | $false | Keeps subject visible on device |
| `ProcessExternalMeetingMessages` | $true | Accepts external invitations |
| `RemovePrivateProperty` | $false | Respects private meeting flag |

### Booking Restrictions

#### Limit Who Can Book

```powershell
# Allow only specific users/groups to book
Set-CalendarProcessing -Identity "mtr-hq-101@contoso.com" `
    -AllBookInPolicy $false `
    -BookInPolicy "Executive-Assistants@contoso.com", "john.smith@contoso.com"
```

#### Allow All Users to Book

```powershell
Set-CalendarProcessing -Identity "mtr-hq-101@contoso.com" `
    -AllBookInPolicy $true `
    -BookInPolicy $null
```

### Booking Window

```powershell
# Set maximum advance booking window (in days)
Set-CalendarProcessing -Identity "mtr-hq-101@contoso.com" `
    -BookingWindowInDays 180 `
    -MaximumDurationInMinutes 480 `
    -MinimumDurationInMinutes 30
```

### Recurring Meetings

```powershell
# Configure recurring meeting handling
Set-CalendarProcessing -Identity "mtr-hq-101@contoso.com" `
    -AllowRecurringMeetings $true `
    -EnforceSchedulingHorizon $true `
    -ScheduleOnlyDuringWorkHours $false
```

## Room Lists

Room lists organize rooms by location, making them easier to find in Outlook.

### Create Room List

```powershell
# Create a distribution group for rooms
New-DistributionGroup -Name "Seattle-Conference-Rooms" `
    -RoomList `
    -PrimarySmtpAddress "seattle-rooms@contoso.com"
```

### Add Rooms to List

```powershell
# Add room to room list
Add-DistributionGroupMember -Identity "Seattle-Conference-Rooms" `
    -Member "mtr-hq-101@contoso.com"

Add-DistributionGroupMember -Identity "Seattle-Conference-Rooms" `
    -Member "mtr-hq-102@contoso.com"
```

### View Room List Members

```powershell
Get-DistributionGroupMember -Identity "Seattle-Conference-Rooms" |
    Select DisplayName, PrimarySmtpAddress
```

## Resource Scheduling Policies

### Organization-Wide Defaults

```powershell
# Set organization default for new room mailboxes
Set-OrganizationConfig `
    -RoomMailboxDefaultMinimumDuration 30 `
    -RoomMailboxDefaultMaximumDuration 1440
```

### Automatic Room Release

Configure rooms to automatically release when meetings end early:

```powershell
# This feature is configured in Teams Admin Center or via Teams policy
# Room mailbox doesn't control this directly
```

## Delegates and Permissions

### Add Delegate Access

```powershell
# Grant someone access to manage room bookings
Add-MailboxFolderPermission -Identity "mtr-hq-101@contoso.com:\Calendar" `
    -User "receptionist@contoso.com" `
    -AccessRights Editor
```

### View Permissions

```powershell
Get-MailboxFolderPermission -Identity "mtr-hq-101@contoso.com:\Calendar"
```

## Verification Commands

### Check Mailbox Configuration

```powershell
# Get mailbox details
Get-Mailbox -Identity "mtr-hq-101@contoso.com" |
    Select DisplayName, RecipientTypeDetails, RoomMailboxAccountEnabled

# Get calendar processing settings
Get-CalendarProcessing -Identity "mtr-hq-101@contoso.com" |
    Select AutomateProcessing, AllowConflicts, ProcessExternalMeetingMessages, BookingWindowInDays

# Get place/room details
Get-Place -Identity "mtr-hq-101@contoso.com" |
    Select DisplayName, Capacity, Building, Floor, Tags
```

### Bulk Verification

```powershell
# Check all room mailboxes
Get-Mailbox -RecipientTypeDetails RoomMailbox | ForEach-Object {
    $calSettings = Get-CalendarProcessing -Identity $_.Identity
    [PSCustomObject]@{
        DisplayName = $_.DisplayName
        Email = $_.PrimarySmtpAddress
        AutoAccept = $calSettings.AutomateProcessing
        AllowConflicts = $calSettings.AllowConflicts
        ExternalMeetings = $calSettings.ProcessExternalMeetingMessages
    }
}
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Room shows as busy but isn't | Orphaned meetings | Clean up old bookings |
| External invites not showing | ProcessExternalMeetingMessages | Set to $true |
| Double bookings | AllowConflicts setting | Set to $false |
| Can't find room in Outlook | Not in room list | Add to distribution group |
| Meeting details not showing | DeleteSubject enabled | Set to $false |

### Clear Ghost Bookings

```powershell
# Remove specific meeting from room calendar
# Use with caution - identify meetings first
Search-Mailbox -Identity "mtr-hq-101@contoso.com" `
    -SearchQuery "Subject:'Ghost Meeting'" `
    -DeleteContent
```

### Test Room Availability

```powershell
# Check room availability for a time range
Get-CalendarDiagnosticLog -Identity "mtr-hq-101@contoso.com" `
    -StartDate (Get-Date) `
    -EndDate (Get-Date).AddDays(7) |
    Select Subject, StartTime, EndTime
```

## Best Practices

1. **Standardize calendar processing** - Use consistent settings across all rooms
2. **Use room lists** - Organize rooms by location/building
3. **Set capacity** - Help users find appropriately sized rooms
4. **Configure Place attributes** - Enable room finder features
5. **Don't allow conflicts** - Prevent double-booking issues
6. **Accept external meetings** - Support meetings with external participants
7. **Set reasonable booking windows** - Balance flexibility with scheduling needs

## Related Topics

- [Resource Accounts](resource-accounts.md)
- [Calendar Processing Script](../../scripts/accounts/Set-MTRCalendarProcessing.ps1)
- [Account Status Script](../../scripts/accounts/Get-MTRAccountStatus.ps1)

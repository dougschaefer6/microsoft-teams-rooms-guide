# Microsoft Teams Rooms Deployment Guide

Comprehensive deployment guide, scripts, and best practices for Microsoft Teams Rooms on Windows and Android. From zero to fully managed meeting rooms.

## Overview

This repository consolidates documentation and automation tools for deploying and managing Microsoft Teams Rooms (MTR). Whether you're deploying a single room or hundreds across multiple locations, this guide provides the knowledge and scripts you need.

## Quick Navigation

### Documentation

| Section | Description |
|---------|-------------|
| [Planning](docs/01-planning/) | Platform comparison, licensing, hardware, and network requirements |
| [Prerequisites](docs/02-prerequisites/) | Entra ID setup, resource accounts, licensing, Exchange configuration |
| [Security](docs/03-security/) | Conditional Access, MFA considerations, compliance, Defender |
| [Intune Management](docs/04-intune-management/) | Enrollment, Autopilot, AOSP, configuration profiles |
| [Deployment](docs/05-deployment/) | Step-by-step deployment guides for all platforms |
| [Post-Deployment](docs/06-post-deployment/) | Management portal, monitoring, updates, troubleshooting |
| [Reference](docs/reference/) | Terminology, supported policies, official links, FAQ |

### Scripts

| Category | Description |
|----------|-------------|
| [Account Scripts](scripts/accounts/) | Create and manage resource accounts |
| [Licensing Scripts](scripts/licensing/) | License assignment and reporting |
| [Conditional Access](scripts/entra-conditional-access/) | CA policy management |
| [Intune Scripts](scripts/intune/) | Autopilot, compliance, enrollment |
| [Validation Scripts](scripts/validation/) | Pre/post deployment validation |

### Templates & Examples

- [Resource Accounts CSV](templates/resource-accounts.csv) - Bulk account creation template
- [Autopilot Devices CSV](templates/autopilot-devices.csv) - Hardware ID import template
- [Deployment Checklist](templates/deployment-checklist.md) - Printable deployment checklist
- [Policy Examples](examples/) - CA and compliance policy JSON exports

## Getting Started

### For New Deployments

1. **Plan** - Read [Overview](docs/01-planning/overview.md) and [Licensing](docs/01-planning/licensing.md)
2. **Prepare** - Follow [Prerequisites](docs/02-prerequisites/) guides
3. **Secure** - Configure [Conditional Access](docs/03-security/conditional-access.md)
4. **Deploy** - Use platform-specific guides in [Deployment](docs/05-deployment/)
5. **Manage** - Set up [Monitoring](docs/06-post-deployment/monitoring-alerting.md)

### Quick Start with Scripts

```powershell
# Install required modules
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser

# Connect to services
Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"
Connect-ExchangeOnline

# Check prerequisites
.\scripts\validation\Test-MTRPrerequisites.ps1

# Create a single resource account
.\scripts\accounts\New-MTRResourceAccount.ps1 -DisplayName "HQ-Conf-101" -UserPrincipalName "mtr-hq-101@contoso.com"

# Or bulk create from CSV
.\scripts\accounts\New-MTRResourceAccountsBulk.ps1 -CsvPath ".\templates\resource-accounts.csv"
```

## Platform Support

| Platform | Documentation | Scripts |
|----------|---------------|---------|
| Teams Rooms on Windows | Full | Full |
| Teams Rooms on Android | Full | Partial |
| Teams Panels | Included | N/A |
| Surface Hub | Included | N/A |

## Documentation Structure

```
docs/
├── 01-planning/           # What to consider before deployment
│   ├── overview.md        # MTR platform overview
│   ├── licensing.md       # Pro vs Basic, costs
│   ├── hardware-requirements.md
│   └── network-requirements.md
│
├── 02-prerequisites/      # What to set up before deployment
│   ├── entra-id-setup.md
│   ├── resource-accounts.md
│   ├── licensing-assignment.md
│   └── exchange-configuration.md
│
├── 03-security/           # Security configuration
│   ├── conditional-access.md
│   ├── mfa-considerations.md
│   ├── device-compliance.md
│   └── defender-endpoint.md
│
├── 04-intune-management/  # Device management
│   ├── enrollment-overview.md
│   ├── windows-autopilot.md
│   ├── android-aosp.md
│   ├── configuration-profiles.md
│   └── compliance-policies.md
│
├── 05-deployment/         # Step-by-step deployment
│   ├── windows-deployment.md
│   ├── android-deployment.md
│   ├── surface-hub.md
│   ├── teams-panels.md
│   └── zero-touch-deployment.md
│
├── 06-post-deployment/    # Ongoing management
│   ├── pro-management-portal.md
│   ├── teams-admin-center.md
│   ├── monitoring-alerting.md
│   ├── updates-maintenance.md
│   └── troubleshooting.md
│
└── reference/             # Reference materials
    ├── terminology.md
    ├── supported-policies.md
    ├── microsoft-learn-links.md
    └── faq.md
```

## Prerequisites

### Required Licenses

- Microsoft 365 tenant
- Teams Rooms Pro or Basic license (per room)
- Intune license (for device management)
- Entra ID P1 or P2 (for Conditional Access)

### Required PowerShell Modules

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module MicrosoftTeams -Scope CurrentUser
```

### Required Permissions

- User Administrator (resource account creation)
- Exchange Administrator (mailbox configuration)
- Teams Administrator (Teams settings)
- Intune Administrator (device management)
- Conditional Access Administrator (CA policies)

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute

- Report issues or suggest improvements
- Submit pull requests for documentation updates
- Share scripts or automation tools
- Provide feedback on existing content

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Disclaimer

This is a community resource and is not officially affiliated with or endorsed by Microsoft. Always refer to [official Microsoft documentation](https://learn.microsoft.com/microsoftteams/rooms/) for the most current information.

## Resources

- [Microsoft Teams Rooms Documentation](https://learn.microsoft.com/microsoftteams/rooms/)
- [Teams Rooms Certified Devices](https://learn.microsoft.com/microsoftteams/rooms/certified-hardware)
- [Microsoft Tech Community - Teams](https://techcommunity.microsoft.com/t5/microsoft-teams/ct-p/MicrosoftTeams)

---

**Topics:** microsoft-teams, teams-rooms, intune, autopilot, conditional-access, powershell, entra-id, meeting-rooms, deployment

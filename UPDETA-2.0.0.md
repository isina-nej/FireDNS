
# CHANGELOG.md (برای اپدیت جدید v2.0.0)

```markdown
# FireDNS Changelog

All notable changes to FireDNS will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-08-20

### Added
- **DNS Testing Modes**: Introduced four modes - Auto (intelligent), Simultaneous (parallel for speed), Sequential (precise), and Advanced (upcoming with ping averages, packet loss, and scoring).
- **Internet Speed Test**: New module for measuring download/upload speeds, ping, with real-time circular gauge UI and detailed stats (IP, server info).
- **Custom DNS Management**: Add, edit, delete custom DNS with validation; favorites system; smart search/sort (by ping, name, favorites).
- **Notifications System**: Local and FCM push notifications; types (Info, Warning, Error, Success); management features (read/unread, delete, refresh).
- **Ticket System**: In-app submission for bug reports/suggestions with forms, server processing, and status tracking.
- **Auto-Updates**: Manual/auto version checks; changelog display; forced updates for critical versions.
- **Multilingual Support**: Added Arabic, Russian, Chinese; auto-detection; instant switching.
- **Theme Options**: System, Dark, Light modes with custom colors.
- **Advanced Architecture**: MVVM with Provider; native integrations; security enhancements (HTTPS, JWT); analytics and optimization tools.
- **Platform-Specific Features**: Admin access for Windows DNS changes; permissions for Android/iOS.
- **Future Teasers**: Prep for DoH/DoT, VPN integration, content filtering.

### Changed
- **UI/UX Improvements**: Modern Material Design; responsive layouts; Lottie animations; custom fonts (e.g., IranSansX for Persian).
- **DNS Switching**: Enhanced auto-switching with priority/secondary support and pre-apply validation.
- **Testing Metrics**: Color-coded results (🟢 <50ms, etc.); caching; hourly auto-tests; single-domain testing.
- **Data Management**: Upgraded to smart caching, JSON serialization; preserved customs during server syncs.
- **Versioning**: Bumped to 2.0.0 for major feature additions.

### Fixed
- Resolved IPv6 compatibility issues in DNS testing.
- Fixed background notification processing on closed app states.
- Improved error handling in API communications and ticket submissions.
- Addressed theme persistence across restarts.
- Patched minor UI glitches on web platform (no system DNS changes).

### Deprecated
- Legacy DNS list format; migrate to new server-synced lists.

### Removed
- Outdated manual DNS entry without validation (replaced with safer system).

### Security
- Added certificate pinning and input validation to prevent injection attacks.
- Ensured all communications use HTTPS.

For full details, see the [release notes](https://github.com/isina-nej/FireDNS/releases/tag/v2.0.0).

[Unreleased]: https://github.com/isina-nej/FireDNS/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/isina-nej/FireDNS/releases/tag/v2.0.0
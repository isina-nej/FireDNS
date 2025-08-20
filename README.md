# FireDNS - Advanced DNS Management Tool

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/yourusername/FireDNS/releases/tag/v2.0.0)
[![Platform](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Web-green.svg)](https://github.com/yourusername/FireDNS)
[![Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B.svg?logo=flutter&logoColor=white)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](https://github.com/yourusername/FireDNS/blob/main/LICENSE)

FireDNS is a comprehensive, cross-platform DNS management application designed to simplify DNS configuration, testing, and optimization. Built with Flutter (Dart), it supports Android, iOS, Windows, and Web platforms, offering a modern UI with multilingual support (Persian, English, Arabic, Russian, Chinese). Whether you're a casual user seeking faster internet or a developer needing advanced DNS tools, FireDNS provides automated DNS switching, performance testing, and secure notifications.

## Key Features

### Core DNS Management
- **Automatic DNS Switching**: Seamlessly change system DNS with IPv4 and IPv6 support.
- **Primary/Secondary DNS**: Configure priority and backup DNS servers.
- **Validation & Testing**: Verify DNS validity and accessibility before applying changes.

### User Interface & Customization
- **Modern Design**: Material Design with responsive layouts for all screen sizes.
- **Theme Support**: System, Dark, and Light modes.
- **Animations**: Smooth Lottie animations for an engaging experience.
- **Multilingual**: Auto-detect device language; instant switching without restarts. Custom fonts like IranSansX for Persian.

### Testing & Performance
- **DNS Testing Modes**:
  - Auto: Intelligent selection.
  - Simultaneous: Parallel testing for speed.
  - Sequential: High-precision sequential testing.
  - Advanced (Upcoming): Detailed ping averages, packet loss, and scoring.
- **Metrics**: Ping time (ms), accessibility status with color-coded results (🟢 Excellent <50ms, 🟡 Good 50-120ms, etc.).
- **Internet Speed Test**: Download/upload speeds, ping, with circular gauge UI and real-time stats.
- **Custom Domain Testing**: Compare DNS performance on specific domains.

### Notifications System
- **Local & Push Notifications**: Via Firebase Cloud Messaging (FCM) for background alerts.
- **Types**: Info, Warning, Error, Success.
- **Management**: Mark as read/unread, delete, pull-to-refresh, welcome notifications.

### Custom DNS Management
- **Add/Edit/Delete**: Custom names, primary/secondary IPs with validation.
- **Favorites**: Star frequently used DNS for quick access.
- **Search & Sort**: By name, IP, ping (default: lowest ping first).
- **Server Sync**: Update official DNS lists while preserving customs.

### Support & Ticketing
- **Ticket System**: Submit bug reports or suggestions with detailed forms.
- **Processing**: Server authentication, progress tracking, confirmation IDs.

### Auto-Updates
- **Manual/Auto Checks**: Compare versions, view changelogs, download sizes.
- **Forced Updates**: For incompatible versions with dedicated guidance pages.

### Advanced Technical Features
- **Architecture**: MVVM with Provider for state management; Flutter framework for multi-platform.
- **Native Integration**: Method Channels for platform-specific code (Kotlin/Java for Android, Swift/Objective-C for iOS, C++ for Windows).
- **Data Management**: SharedPreferences, JSON serialization, smart caching.
- **Security**: HTTPS, certificate pinning, JWT authentication, input validation.
- **Analytics**: Performance monitoring, crash reporting, usage stats.
- **Optimization**: Lazy loading, memory management, network efficiency.
- **Testing**: Unit, integration tests; code linting.

### Platforms & Compatibility
- **Android**: API 21+ (5.0+); Permissions: INTERNET, ACCESS_NETWORK_STATE, etc.
- **iOS**: 12.0+; Permissions: Network, Notifications, Background Refresh.
- **Windows**: 10/11; Admin access for DNS changes.
- **Web**: Chrome, Firefox, Safari, Edge; Limited to testing (no system DNS changes).

### Future Features
- Advanced DNS testing with scoring.
- User profiles and advanced controls.
- DoH/DoT support.
- Integrated VPN.
- Content filtering.
- Multi-profiles.

## Screenshots

![Main Screen](screenshots/main_screen.png)  
![DNS Test](screenshots/dns_test.png)  
![Speed Test](screenshots/speed_test.png)  
![Settings](screenshots/settings.png)

(Add actual screenshot paths or links here.)

## Installation

### Prerequisites
- Flutter SDK (v3.0+ recommended).
- Dart (included with Flutter).
- Platform-specific tools: Android Studio, Xcode, Visual Studio for Windows.

### Clone & Setup
```bash
git clone https://github.com/isina-nej/FireDNS.git
cd FireDNS
flutter pub get


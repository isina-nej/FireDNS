# Update Feature Documentation

## Overview
This document explains the new update feature implementation for the FireDNS application. The feature enhances the user experience by providing detailed information about app updates directly within the update page.

## Features Added

### 1. Update Information Model
- Created `UpdateInfo` model to represent update information
- Fields include:
  - `currentVersion`: Current app version
  - `latestVersion`: Latest available version
  - `updateUrl`: URL for downloading the update
  - `description`: Description of the update
  - `features`: List of new features in the update
  - `changes`: List of changes in the update

### 2. Update API Service
- Created `UpdateApiService` to fetch update information from the server
- Uses the existing `ApiClient` for HTTP requests
- Provides error handling and response parsing

### 3. Enhanced ForceUpdatePage
- Converted from StatelessWidget to StatefulWidget
- Fetches update information on initialization
- Displays detailed update information including:
  - Version comparison (current vs latest)
  - Update description
  - New features with checkmark icons
  - Recent changes with update icons
- Maintains existing functionality for opening update URL

### 4. API Documentation
- Added `/update-info` endpoint to the OpenAPI specification
- Includes detailed schema for update information response

## Usage

### Client Side
The `ForceUpdatePage` automatically fetches update information when displayed. The page shows:
1. Loading indicator during API request
2. Error message if API request fails with retry button
3. Update information including:
   - Current and latest version numbers
   - Description of the update
   - List of new features
   - List of recent changes
4. Button to open update URL

### Server Side
The server should implement the `/update-info` endpoint that returns JSON in the following format:
```json
{
  "status": true,
  "message": "Operation successful",
  "data": {
    "currentVersion": "1.0.0",
    "latestVersion": "1.2.0",
    "updateUrl": "https://update.fire-dns.ir",
    "description": "This update includes new features and bug fixes.",
    "features": [
      "New speed test feature",
      "Improved UI"
    ],
    "changes": [
      "Fixed connection issues",
      "Improved performance"
    ]
  }
}
```

## Files Modified/Added
1. `lib/api/models/update_info.dart` - New model for update information
2. `lib/api/services/update_api_service.dart` - New service for fetching update information
3. `lib/screens/force_update_page.dart` - Enhanced update page with detailed information
4. `lib/path/path.dart` - Updated exports to include new files
5. `dns-changer-api.json` - Updated API documentation with new endpoint
6. `lib/screens/force_update_page_test.dart` - Basic tests for the update page
7. `UPDATE_FEATURE_DOCUMENTATION.md` - This documentation file

## Testing
Run the existing tests to ensure the update page works correctly:
```bash
flutter test lib/screens/force_update_page_test.dart
```

## Future Improvements
1. Add more comprehensive tests including error scenarios
2. Implement caching for update information
3. Add localization for error messages
4. Add analytics for update page views and button clicks
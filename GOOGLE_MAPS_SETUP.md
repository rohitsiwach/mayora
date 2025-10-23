# Google Maps Setup Guide for Mayora

## Overview
This guide will help you integrate Google Maps into the Mayora app for location management functionality.

## Prerequisites
- Google Cloud Platform account
- Mayora project setup
- Flutter development environment

---

## Step 1: Get Google Maps API Key

### 1.1 Create/Select Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Note your project ID

### 1.2 Enable Required APIs
Enable these APIs in your Google Cloud Console:
1. Go to **APIs & Services** > **Library**
2. Search and enable the following:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**
   - **Geolocation API**

### 1.3 Create API Key
1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **API Key**
3. Copy the generated API key
4. Click **Edit API key** to add restrictions (recommended for production)

### 1.4 Restrict API Key (Recommended)
For security, add restrictions:

**For Android:**
- Application restrictions: Android apps
- Add your package name: `com.example.mayora` (or your actual package)
- Add SHA-1 certificate fingerprint

**For iOS:**
- Application restrictions: iOS apps
- Add your bundle identifier

---

## Step 2: Configure Android

### 2.1 Add API Key to AndroidManifest.xml
File: `android/app/src/main/AndroidManifest.xml`

Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy...your-actual-key-here"/>
```

### 2.2 Get SHA-1 Certificate Fingerprint (for API restrictions)

**Debug Certificate:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release Certificate:**
```bash
keytool -list -v -keystore /path/to/your-release-key.jks -alias your-alias-name
```

Copy the SHA-1 and add it to your API key restrictions in Google Cloud Console.

---

## Step 3: Configure iOS

### 3.1 Add API Key to AppDelegate.swift
File: `ios/Runner/AppDelegate.swift`

Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```swift
GMSServices.provideAPIKey("AIzaSy...your-actual-key-here")
```

### 3.2 Update iOS Deployment Target (if needed)
Google Maps requires iOS 14.0 or higher.

File: `ios/Podfile`

Add at the top if not present:
```ruby
platform :ios, '14.0'
```

### 3.3 Install iOS Pods
```bash
cd ios
pod install
cd ..
```

---

## Step 4: Test the Integration

### 4.1 Run the App
```bash
flutter run
```

### 4.2 Test Location Features
1. Navigate to **Management** > **Locations**
2. Tap the **+** button to add a location
3. You should see a Google Map instead of the placeholder
4. Tap **"Use My Current Location"** - it should request location permission
5. Tap anywhere on the map to select a location
6. The address should auto-populate via reverse geocoding

### 4.3 Troubleshooting

**Map shows blank/gray:**
- Check API key is correct in both Android and iOS config
- Verify APIs are enabled in Google Cloud Console
- Check billing is enabled on Google Cloud (required after trial)
- Wait a few minutes for API key activation

**Location permission issues:**
- Android: Check permissions in `AndroidManifest.xml`
- iOS: Check usage descriptions in `Info.plist`
- Test on a real device (emulator location can be unreliable)

**Geocoding not working:**
- Verify Geocoding API is enabled
- Check API key restrictions aren't blocking requests
- Check console for error messages

---

## Step 5: Security Best Practices

### 5.1 Use Different Keys for Development and Production
Create separate API keys:
- One for development (less restricted)
- One for production (with tight restrictions)

### 5.2 Never Commit API Keys to Git
Consider using environment variables or secure storage:

**Option 1: Use `.env` file (gitignored)**
```bash
# .env
GOOGLE_MAPS_API_KEY=your_key_here
```

**Option 2: Use Flutter environment variables**
```bash
flutter run --dart-define=MAPS_API_KEY=your_key_here
```

### 5.3 Monitor API Usage
- Set up billing alerts in Google Cloud Console
- Monitor API usage dashboard
- Set quotas to prevent unexpected charges

---

## API Pricing

Google Maps Platform has a **monthly $200 free credit** that covers:
- ~28,000 map loads
- ~40,000 geocoding requests

After free tier:
- Maps SDK: $7 per 1,000 loads
- Geocoding API: $5 per 1,000 requests

For a small team app, you'll likely stay within free tier.

---

## Features Enabled

With Google Maps integrated, you now have:

✅ **Interactive Map View**
- Pan and zoom
- Tap to select location
- Draggable markers

✅ **Current Location**
- GPS-based location detection
- "Use My Current Location" button
- Permission handling

✅ **Geocoding**
- Reverse geocoding (coordinates → address)
- Automatic address population
- Formatted address display

✅ **Location Management**
- Save work locations with coordinates
- Set custom radius per location
- Edit and delete locations

---

## Next Steps

### Optional Enhancements:
1. **Place Autocomplete**: Add search bar with Google Places API
2. **Geofencing**: Implement geofence triggers for attendance
3. **Offline Maps**: Cache map tiles for offline use
4. **Custom Map Styling**: Apply custom map themes
5. **Location Tracking**: Continuous location tracking for route history

---

## Support

### Documentation
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Google Maps Platform Docs](https://developers.google.com/maps/documentation)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Geocoding Package](https://pub.dev/packages/geocoding)

### Common Issues
- [Google Maps Platform Support](https://support.google.com/maps)
- [Flutter Google Maps Issues](https://github.com/flutter/flutter/labels/p%3A%20maps)

---

## Checklist

Before deploying to production:

- [ ] API key added to Android `AndroidManifest.xml`
- [ ] API key added to iOS `AppDelegate.swift`
- [ ] Required APIs enabled in Google Cloud Console
- [ ] Billing enabled on Google Cloud account
- [ ] API restrictions configured for security
- [ ] SHA-1 fingerprints added for Android
- [ ] Bundle ID added for iOS
- [ ] Tested on real Android device
- [ ] Tested on real iOS device
- [ ] Location permissions working correctly
- [ ] Geocoding functioning properly
- [ ] API usage monitored and within budget

---

## Quick Reference

**Package Name:** `com.example.mayora` (update in `AndroidManifest.xml`)
**Bundle ID:** `com.example.mayora` (update in Xcode)

**Files Modified:**
- `pubspec.yaml` - Dependencies added
- `android/app/src/main/AndroidManifest.xml` - API key & permissions
- `ios/Runner/AppDelegate.swift` - API key initialization
- `ios/Runner/Info.plist` - Location permissions
- `lib/pages/location_picker_page.dart` - Google Maps integration

**APIs Required:**
- Maps SDK for Android
- Maps SDK for iOS  
- Geocoding API
- Geolocation API

---

**Ready to go!** 🎉

Once you've added your API key to both platforms, run the app and test the location management feature.

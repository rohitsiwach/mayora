# Google Maps Web Setup Guide

## Issue: Map not loading and "forbidden" error on autocomplete

### Root Causes:
1. **Missing API Key**: The placeholder `YOUR_GOOGLE_MAPS_API_KEY_HERE` needs to be replaced with your actual Google Cloud API key
2. **Missing Places Library**: The Google Maps script needs to include the Places library for autocomplete to work

### Solution Steps:

#### 1. Get Your Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps JavaScript API
   - Places API
   - Geocoding API
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy your API key

#### 2. Configure API Key Restrictions (Recommended)
For security, restrict your API key:
- **Application restrictions**: 
  - For development: None or HTTP referrers with `localhost:*`
  - For production: HTTP referrers with your domain (e.g., `yourdomain.com/*`)
- **API restrictions**: 
  - Select "Restrict key"
  - Enable: Maps JavaScript API, Places API, Geocoding API

#### 3. Update Files with Your API Key

**File 1: `web/index.html`**
Replace line 36:
```html
<!-- BEFORE -->
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY_HERE&libraries=places"></script>

<!-- AFTER -->
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&libraries=places"></script>
```

**File 2: `lib/pages/location_picker_page.dart`**
Replace line 447:
```dart
// BEFORE
googleAPIKey: "YOUR_GOOGLE_MAPS_API_KEY_HERE",

// AFTER
googleAPIKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
```

**File 3: `android/app/src/main/AndroidManifest.xml`**
Replace line 14:
```xml
<!-- BEFORE -->
<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>

<!-- AFTER -->
<meta-data android:name="com.google.android.geo.API_KEY" android:value="AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"/>
```

**File 4: `ios/Runner/AppDelegate.swift`**
Replace line 10:
```swift
// BEFORE
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")

// AFTER
GMSServices.provideAPIKey("AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
```

#### 4. Test the Application

**For Web:**
```powershell
flutter run -d chrome
```

**Expected behavior:**
- Address field shows autocomplete suggestions when typing
- Suggestions are clickable and update the location
- No "forbidden" or 403 errors in browser console

#### 5. Verify API Key is Working

Open browser Developer Tools (F12) and check:
- **Console tab**: Should have no errors about API key or "RefererNotAllowedMapError"
- **Network tab**: Google Maps API requests should return status 200, not 403

### Common Issues:

**Issue: "This page can't load Google Maps correctly"**
- Solution: API key is invalid or not enabled for Maps JavaScript API

**Issue: "RefererNotAllowedMapError"**
- Solution: Your domain/localhost is not in the API key's HTTP referrer restrictions

**Issue: Autocomplete shows "forbidden"**
- Solution: Places API is not enabled or API key doesn't have Places API access

**Issue: API key exposed in source code**
- Solution: For production, use environment variables or backend proxy to hide the key

### Web Limitations:

The web version has some limitations compared to mobile:
1. **No interactive map**: The map area shows a placeholder (the google_maps_flutter package has limited web support)
2. **Address search only**: Users must use the address autocomplete field to select locations
3. **GPS button disabled**: Current location feature is not available on web (requires mobile app)

For full map functionality, users should use the Android or iOS app.

### Production Considerations:

1. **Never commit API keys**: Add them to `.gitignore` or use environment variables
2. **Use backend proxy**: Consider proxying Google Maps API calls through your backend
3. **Monitor usage**: Set up billing alerts in Google Cloud Console
4. **Restrict by domain**: Always use HTTP referrer restrictions in production

### Testing Checklist:

- [ ] Google Cloud project created
- [ ] Maps JavaScript API enabled
- [ ] Places API enabled  
- [ ] Geocoding API enabled
- [ ] API key created
- [ ] API key restrictions configured
- [ ] API key added to `web/index.html`
- [ ] API key added to `location_picker_page.dart`
- [ ] API key added to `AndroidManifest.xml`
- [ ] API key added to `AppDelegate.swift`
- [ ] Web app tested in Chrome
- [ ] Autocomplete working on web
- [ ] No console errors
- [ ] Mobile app tested on Android
- [ ] Map view working on Android

---

**Last Updated:** October 23, 2025

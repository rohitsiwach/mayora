# Location Management Feature

## Overview
Complete location management system for tracking work locations with geofencing capabilities.

## Features Implemented

### 1. Location Settings
- **Location Tracking**: Toggle location tracking on/off for app activity
- **Require Location for Punch**: Option to require users to be at a work location to punch in/out
- **Allow Punch Outside Location**: Toggle to allow/disallow activity outside authorized locations
- **Default Radius**: Set default geofence radius for new locations

### 2. Work Locations Management
- **Add Locations**: Create new work locations with name, address, coordinates, and custom radius
- **Edit Locations**: Update existing location details
- **Delete Locations**: Remove locations with confirmation dialog
- **Real-time Updates**: Locations list updates automatically via Firestore streams

### 3. Location Picker
- **Map Interface**: Visual map placeholder (ready for Google Maps integration)
- **Current Location**: Button to use device's current location
- **Manual Selection**: Tap on map to select location
- **Address Display**: Shows selected coordinates and address
- **Custom Radius**: Set individual radius for each location (in meters)

## Files Created

### Models
- `lib/models/work_location.dart` - Work location data model

### Services
- `lib/services/location_settings_service.dart` - Manages location settings and work locations in Firestore

### Pages
- `lib/pages/locations_page.dart` - Main location management page with settings and locations list
- `lib/pages/location_picker_page.dart` - Map-based location picker for adding/editing locations

## Database Structure

### Firestore Collections

#### `location_settings/{organizationId}`
```
{
  locationTrackingEnabled: boolean
  requireLocationForPunch: boolean
  allowPunchOutsideLocation: boolean
  defaultRadiusMeters: number
  updatedAt: timestamp
}
```

#### `work_locations/{locationId}`
```
{
  name: string
  address: string
  latitude: number
  longitude: number
  radiusMeters: number
  organizationId: string
  createdAt: timestamp
  updatedAt: timestamp
}
```

## Integration with Main App
- Added "Locations" menu item in drawer under Management section
- Route: `/locations`
- Icon: `location_on_outlined`

## Future Enhancements (Ready for Integration)

### Google Maps Integration
To enable real Google Maps functionality, uncomment in `pubspec.yaml`:
```yaml
google_maps_flutter: ^2.5.0
geolocator: ^10.1.0
geocoding: ^2.1.1
```

Then update `location_picker_page.dart` to:
1. Replace placeholder `LatLng` class with `google_maps_flutter` LatLng
2. Replace placeholder map widget with actual `GoogleMap` widget
3. Implement real geolocation using `geolocator` package
4. Implement reverse geocoding using `geocoding` package

### Additional Features
- Distance calculation from user to work locations
- Map view showing all work locations
- Geofence notifications
- Location history tracking
- Export locations data

## UI Design
Follows the structure from the provided reference image:
- Clean card-based layout
- Toggle switches for settings with status indicators (Enabled/Yes/No)
- List view with circular avatars for locations
- Edit and delete actions for each location
- Floating action button style for adding locations

## Testing
- All files compile without errors
- Firestore operations are properly structured
- UI is responsive and follows Material Design guidelines
- Error handling implemented throughout

## Notes
- Currently uses placeholder map (gray box with icon)
- Real map functionality requires Google Maps API key
- Coordinates default to Munich, Germany (48.1351, 11.5820)
- All operations are organization-scoped for multi-tenancy

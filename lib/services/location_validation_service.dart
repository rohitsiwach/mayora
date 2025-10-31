import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/work_location.dart';
import 'location_settings_service.dart';

class LocationValidationService {
  final LocationSettingsService locationSettingsService =
      LocationSettingsService();

  /// Check if location permissions are granted and request if needed
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current user position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Check if user is within range of any approved work location
  /// Returns a map with validation result and details
  Future<LocationValidationResult> validateUserLocation({
    required String organizationId,
    required Position userPosition,
  }) async {
    try {
      // Get location settings
      final settings = await locationSettingsService.getLocationSettings(
        organizationId,
      );

      // If location tracking is disabled, allow access
      if (settings['locationTrackingEnabled'] != true) {
        return LocationValidationResult(
          isValid: true,
          reason: 'Location tracking is disabled',
        );
      }

      // Get all work locations
      final workLocationsStream = locationSettingsService.getWorkLocations(
        organizationId,
      );
      final workLocations = await workLocationsStream.first;

      if (workLocations.isEmpty) {
        // No locations defined, check if we should allow or deny
        if (settings['allowPunchOutsideLocation'] == true) {
          return LocationValidationResult(
            isValid: true,
            reason: 'No work locations defined, allowing punch',
          );
        } else {
          return LocationValidationResult(
            isValid: false,
            reason: 'No approved work locations have been set up',
          );
        }
      }

      // Check if user is within range of any location
      WorkLocation? nearestLocation;
      double nearestDistance = double.infinity;

      for (final location in workLocations) {
        final distance = calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          location.latitude,
          location.longitude,
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestLocation = location;
        }

        // If within range of this location, validation succeeds
        if (distance <= location.radiusMeters) {
          return LocationValidationResult(
            isValid: true,
            nearestLocation: location,
            distanceMeters: distance,
            reason:
                'Within ${location.name} (${distance.toStringAsFixed(0)}m away)',
          );
        }
      }

      // User is not within range of any location
      if (settings['allowPunchOutsideLocation'] == true) {
        return LocationValidationResult(
          isValid: true,
          nearestLocation: nearestLocation,
          distanceMeters: nearestDistance,
          reason: 'Outside approved locations but allowed to punch',
        );
      } else {
        return LocationValidationResult(
          isValid: false,
          nearestLocation: nearestLocation,
          distanceMeters: nearestDistance,
          reason: nearestLocation != null
              ? 'You must be within ${nearestLocation.radiusMeters.toStringAsFixed(0)}m of an approved location. Nearest: ${nearestLocation.name} (${nearestDistance.toStringAsFixed(0)}m away)'
              : 'You must be at an approved work location to punch in',
        );
      }
    } catch (e) {
      print('Error validating user location: $e');
      return LocationValidationResult(
        isValid: false,
        reason: 'Error validating location: $e',
      );
    }
  }

  /// Validate location for time tracking action
  /// Returns validation result or null if location not required
  Future<LocationValidationResult?> validateLocationForAction({
    required String organizationId,
  }) async {
    try {
      // Get location settings
      final settings = await locationSettingsService.getLocationSettings(
        organizationId,
      );

      // If location tracking is disabled, no validation needed
      if (settings['locationTrackingEnabled'] != true) {
        return null;
      }

      // If location is not required for punch, no validation needed
      if (settings['requireLocationForPunch'] != true) {
        return null;
      }

      // Get current position
      final position = await getCurrentPosition();
      if (position == null) {
        return LocationValidationResult(
          isValid: false,
          reason:
              'Unable to get your location. Please enable location services and grant permission.',
        );
      }

      // Validate position against approved locations
      return await validateUserLocation(
        organizationId: organizationId,
        userPosition: position,
      );
    } catch (e) {
      print('Error in validateLocationForAction: $e');
      return LocationValidationResult(
        isValid: false,
        reason: 'Error validating location: $e',
      );
    }
  }
}

/// Result of location validation
class LocationValidationResult {
  final bool isValid;
  final String reason;
  final WorkLocation? nearestLocation;
  final double? distanceMeters;

  LocationValidationResult({
    required this.isValid,
    required this.reason,
    this.nearestLocation,
    this.distanceMeters,
  });
}

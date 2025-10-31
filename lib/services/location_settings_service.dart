import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_location.dart';
import 'hierarchical_firestore_service.dart';

class LocationSettingsService {
  final HierarchicalFirestoreService _hierarchical =
      HierarchicalFirestoreService();

  /// Get location settings for an organization
  Future<Map<String, dynamic>> getLocationSettings(
    String organizationId,
  ) async {
    try {
      // Read org-scoped settings doc under: organizations/{orgId}/location_settings/{orgId}
      final doc = await _hierarchical
          .locationSettingsCollection(organizationId)
          .doc(organizationId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data ?? _defaultSettings();
      }
      return _defaultSettings();
    } catch (e) {
      print('Error getting location settings: $e');
      return _defaultSettings();
    }
  }

  /// Update location settings for an organization
  Future<void> updateLocationSettings(
    String organizationId,
    Map<String, dynamic> settings,
  ) async {
    try {
      // Write org-scoped settings doc under: organizations/{orgId}/location_settings/{orgId}
      await _hierarchical
          .locationSettingsCollection(organizationId)
          .doc(organizationId)
          .set({
            ...settings,
            'organizationId': organizationId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating location settings: $e');
      rethrow;
    }
  }

  /// Get all work locations for an organization
  Stream<List<WorkLocation>> getWorkLocations(String organizationId) {
    return _hierarchical
        .workLocationsCollection(organizationId)
        .snapshots()
        .map((snapshot) {
          // Sort locations by name in-memory instead of using Firestore orderBy
          final locations = snapshot.docs
              .map(
                (doc) => WorkLocation.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          // Sort by name alphabetically
          locations.sort((a, b) => a.name.compareTo(b.name));

          return locations;
        });
  }

  /// Add a new work location
  Future<String> addWorkLocation(WorkLocation location) async {
    try {
      final docRef = await _hierarchical
          .workLocationsCollection(location.organizationId)
          .add({
            ...location.toMap(),
            'organizationId': location.organizationId,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } catch (e) {
      print('Error adding work location: $e');
      rethrow;
    }
  }

  /// Update an existing work location
  Future<void> updateWorkLocation(WorkLocation location) async {
    if (location.id == null) {
      throw Exception('Location ID is required for update');
    }

    try {
      await _hierarchical
          .workLocationsCollection(location.organizationId)
          .doc(location.id)
          .update({
            ...location.toMap(),
            'organizationId': location.organizationId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error updating work location: $e');
      rethrow;
    }
  }

  /// Delete a work location
  Future<void> deleteWorkLocation(
    String organizationId,
    String locationId,
  ) async {
    try {
      await _hierarchical
          .workLocationsCollection(organizationId)
          .doc(locationId)
          .delete();
    } catch (e) {
      print('Error deleting work location: $e');
      rethrow;
    }
  }

  /// Default settings
  Map<String, dynamic> _defaultSettings() {
    return {
      'locationTrackingEnabled': true,
      'requireLocationForPunch': false,
      'allowPunchOutsideLocation': true,
      'defaultRadiusMeters': 10.0,
    };
  }
}

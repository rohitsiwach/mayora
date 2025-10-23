import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_location.dart';

class LocationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Location Settings Keys
  static const String _settingsCollection = 'location_settings';
  static const String _locationsCollection = 'work_locations';

  /// Get location settings for an organization
  Future<Map<String, dynamic>> getLocationSettings(
    String organizationId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_settingsCollection)
          .doc(organizationId)
          .get();

      if (doc.exists) {
        return doc.data() ?? _defaultSettings();
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
      await _firestore.collection(_settingsCollection).doc(organizationId).set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating location settings: $e');
      rethrow;
    }
  }

  /// Get all work locations for an organization
  Stream<List<WorkLocation>> getWorkLocations(String organizationId) {
    return _firestore
        .collection(_locationsCollection)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
          // Sort locations by name in-memory instead of using Firestore orderBy
          final locations = snapshot.docs
              .map((doc) => WorkLocation.fromMap(doc.data(), doc.id))
              .toList();

          // Sort by name alphabetically
          locations.sort((a, b) => a.name.compareTo(b.name));

          return locations;
        });
  }

  /// Add a new work location
  Future<String> addWorkLocation(WorkLocation location) async {
    try {
      final docRef = await _firestore.collection(_locationsCollection).add({
        ...location.toMap(),
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
      await _firestore.collection(_locationsCollection).doc(location.id).update(
        {...location.toMap(), 'updatedAt': FieldValue.serverTimestamp()},
      );
    } catch (e) {
      print('Error updating work location: $e');
      rethrow;
    }
  }

  /// Delete a work location
  Future<void> deleteWorkLocation(String locationId) async {
    try {
      await _firestore
          .collection(_locationsCollection)
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

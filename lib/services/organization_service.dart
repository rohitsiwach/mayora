import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new organization during signup
  Future<String> createOrganization(
    Map<String, dynamic> organizationData,
  ) async {
    try {
      final docRef = await _firestore.collection('organizations').add({
        ...organizationData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'Active',
      });

      return docRef.id;
    } catch (e) {
      print('Error creating organization: $e');
      rethrow;
    }
  }

  /// Create default internal project for new organization
  Future<void> createDefaultProject(
    String organizationId,
    String createdBy,
  ) async {
    try {
      // Use hierarchical path: organizations/{orgId}/projects
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('projects')
          .add({
            'projectName': 'Default internal project',
            'projectType': 'Internal',
            'billableToClient': false,
            'clientName': null,
            'clientEmail': null,
            'clientPhone': null,
            'description': 'default internal project',
            'paymentType': null,
            'lumpSumAmount': null,
            'monthlyRate': null,
            'hourlyRate': null,
            'location': '',
            'organizationId': organizationId,
            'createdBy': createdBy,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error creating default project: $e');
      rethrow;
    }
  }

  /// Get organization by ID
  Future<Map<String, dynamic>?> getOrganization(String organizationId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (!doc.exists) return null;

      return {...doc.data()!, 'id': doc.id};
    } catch (e) {
      print('Error getting organization: $e');
      rethrow;
    }
  }

  /// Update organization details
  Future<void> updateOrganization(
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('organizations').doc(organizationId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating organization: $e');
      rethrow;
    }
  }

  /// Get user's organization ID from lightweight lookup doc
  Future<String?> getUserOrganizationId(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return doc.data()?['organizationId'] as String?;
    } catch (e) {
      print('Error getting user organization: $e');
      rethrow;
    }
  }

  /// Stream of organization data
  Stream<DocumentSnapshot> organizationStream(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .snapshots();
  }

  /// Add user to organization
  Future<void> addUserToOrganization(
    String userId,
    String organizationId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(querySnapshot.docs.first.id)
            .update({
              'organizationId': organizationId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error adding user to organization: $e');
      rethrow;
    }
  }

  /// Get error message
  String getErrorMessage(dynamic error) {
    if (error.toString().contains('PERMISSION_DENIED')) {
      return 'Permission denied. Please check your access rights.';
    } else if (error.toString().contains('NOT_FOUND')) {
      return 'Organization not found.';
    } else if (error.toString().contains('UNAVAILABLE')) {
      return 'Service unavailable. Please check your internet connection.';
    } else {
      return 'An error occurred. Please try again later.';
    }
  }
}

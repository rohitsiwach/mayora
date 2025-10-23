import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Cache for organization ID
  String? _cachedOrganizationId;

  /// Get the current user's organization ID
  Future<String?> getCurrentUserOrganizationId() async {
    if (_cachedOrganizationId != null) return _cachedOrganizationId;

    if (_currentUserId == null) return null;

    try {
      // Access user document directly by document ID (which is the user's auth UID)
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        _cachedOrganizationId = userDoc.data()?['organizationId'] as String?;
        return _cachedOrganizationId;
      }
      return null;
    } catch (e) {
      print('Error getting organization ID: $e');
      return null;
    }
  }

  /// Clear cached organization ID (call on sign out)
  void clearCache() {
    _cachedOrganizationId = null;
  }

  // ==================== PROJECTS ====================

  /// Add a new project
  Future<String?> addProject(Map<String, dynamic> projectData) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get organization ID
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      // Add metadata
      projectData['organizationId'] = organizationId;
      projectData['createdBy'] = _currentUserId;
      projectData['createdAt'] = FieldValue.serverTimestamp();
      projectData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('projects').add(projectData);
      return docRef.id;
    } catch (e) {
      print('Error adding project: $e');
      rethrow;
    }
  }

  /// Get all projects for the current user's organization
  Stream<QuerySnapshot> getProjects() {
    if (_currentUserId == null) {
      // Return empty stream instead of throwing
      return Stream.error(Exception('User not authenticated'));
    }

    // Return a stream that first gets the organizationId then queries projects
    return Stream.fromFuture(getCurrentUserOrganizationId()).asyncExpand((
      organizationId,
    ) {
      if (organizationId == null) {
        // Return empty stream instead of throwing
        return Stream.error(
          Exception(
            'User is not associated with an organization. Please contact support.',
          ),
        );
      }

      return _firestore
          .collection('projects')
          .where('organizationId', isEqualTo: organizationId)
          .snapshots();
    });
  }

  /// Update a project
  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> projectData,
  ) async {
    try {
      projectData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('projects')
          .doc(projectId)
          .update(projectData);
    } catch (e) {
      print('Error updating project: $e');
      rethrow;
    }
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  // ==================== USERS ====================

  /// Generate a unique 8-character invitation code
  String generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding similar chars
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    var value = random;

    for (int i = 0; i < 8; i++) {
      code += chars[value % chars.length];
      value = value ~/ chars.length;
    }

    return code;
  }

  /// Send user invitation (save to Firestore)
  Future<String?> sendUserInvitation(Map<String, dynamic> userData) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get organization ID
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      // Generate unique invitation code
      final invitationCode = generateInvitationCode();

      // Calculate expiry date (2 weeks from now)
      final expiryDate = DateTime.now().add(const Duration(days: 14));

      // Add metadata
      userData['organizationId'] = organizationId;
      userData['invitedBy'] = _currentUserId;
      userData['invitationCode'] = invitationCode;
      userData['expiryDate'] = Timestamp.fromDate(expiryDate);
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      userData['status'] = 'Pending';
      userData['invitationCount'] = 1;

      final docRef = await _firestore
          .collection('user_invitations')
          .add(userData);
      return docRef.id;
    } catch (e) {
      print('Error sending invitation: $e');
      rethrow;
    }
  }

  /// Get all user invitations for the current user's organization
  Stream<QuerySnapshot> getUserInvitations() {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return Stream.fromFuture(getCurrentUserOrganizationId()).asyncExpand((
      organizationId,
    ) {
      if (organizationId == null) {
        return Stream.error(
          Exception(
            'User is not associated with an organization. Please contact support.',
          ),
        );
      }

      return _firestore
          .collection('user_invitations')
          .where('organizationId', isEqualTo: organizationId)
          .where('invitedBy', isEqualTo: _currentUserId)
          .snapshots();
    });
  }

  /// Update user invitation
  Future<void> updateUserInvitation(
    String invitationId,
    Map<String, dynamic> userData,
  ) async {
    try {
      userData['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('user_invitations')
          .doc(invitationId)
          .update(userData);
    } catch (e) {
      print('Error updating invitation: $e');
      rethrow;
    }
  }

  /// Delete user invitation
  Future<void> deleteUserInvitation(String invitationId) async {
    try {
      await _firestore
          .collection('user_invitations')
          .doc(invitationId)
          .delete();
    } catch (e) {
      print('Error deleting invitation: $e');
      rethrow;
    }
  }

  /// Resend invitation (update timestamp)
  Future<void> resendInvitation(String invitationId) async {
    try {
      await _firestore.collection('user_invitations').doc(invitationId).update({
        'lastInvitationSent': FieldValue.serverTimestamp(),
        'invitationCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error resending invitation: $e');
      rethrow;
    }
  }

  /// Deactivate user
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': 'Deactivated',
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deactivating user: $e');
      rethrow;
    }
  }

  /// Get registered users (accepted invitations) for the current user's organization
  Stream<QuerySnapshot> getRegisteredUsers() {
    if (_currentUserId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    return Stream.fromFuture(getCurrentUserOrganizationId()).asyncExpand((
      organizationId,
    ) {
      if (organizationId == null) {
        return Stream.error(
          Exception(
            'User is not associated with an organization. Please contact support.',
          ),
        );
      }

      return _firestore
          .collection('users')
          .where('organizationId', isEqualTo: organizationId)
          .snapshots();
    });
  }

  /// Validate invitation code and get invitation data
  Future<Map<String, dynamic>?> validateInvitationCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_invitations')
          .where('invitationCode', isEqualTo: code)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // Invalid code
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Check if expired
      final expiryDate = (data['expiryDate'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        return null; // Expired
      }

      return {...data, 'id': doc.id};
    } catch (e) {
      print('Error validating invitation code: $e');
      rethrow;
    }
  }

  /// Accept invitation and create user account
  Future<void> acceptInvitation(
    String invitationId,
    Map<String, dynamic> additionalUserData,
  ) async {
    try {
      // Get invitation data (this works because we allow public read)
      final invitationDoc = await _firestore
          .collection('user_invitations')
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitationData = invitationDoc.data()!;

      // Merge invitation data with additional user data
      final userData = {
        ...invitationData,
        ...additionalUserData,
        'status': 'Active',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove invitation-specific fields
      userData.remove('invitationCode');
      userData.remove('expiryDate');
      userData.remove('invitationCount');

      // Add to users collection (this works because we allow public create)
      await _firestore.collection('users').add(userData);

      // Delete the invitation from user_invitations collection
      // The invitation has been accepted and user created, so we no longer need it
      try {
        await _firestore
            .collection('user_invitations')
            .doc(invitationId)
            .delete();
        print('Invitation deleted successfully after user creation');
      } catch (deleteError) {
        print('Note: Could not delete invitation (this is okay): $deleteError');
        // Don't rethrow - the important part (creating the user) succeeded
      }
    } catch (e) {
      print('Error accepting invitation: $e');
      rethrow;
    }
  }

  /// Get invitation by ID
  Future<Map<String, dynamic>?> getInvitationById(String invitationId) async {
    try {
      final doc = await _firestore
          .collection('user_invitations')
          .doc(invitationId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return {...doc.data()!, 'id': doc.id};
    } catch (e) {
      print('Error getting invitation: $e');
      rethrow;
    }
  }

  // ==================== USER GROUPS ====================

  /// Create a new user group
  Future<String?> createUserGroup(Map<String, dynamic> groupData) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      groupData['organizationId'] = organizationId;
      groupData['createdBy'] = _currentUserId;
      groupData['createdAt'] = FieldValue.serverTimestamp();
      groupData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('user_groups').add(groupData);
      return docRef.id;
    } catch (e) {
      print('Error creating user group: $e');
      rethrow;
    }
  }

  /// Get all user groups for the current user's organization
  Stream<QuerySnapshot> getUserGroups() {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return Stream.fromFuture(getCurrentUserOrganizationId()).asyncExpand((
      organizationId,
    ) {
      if (organizationId == null) {
        return Stream.error(
          Exception('User is not associated with an organization'),
        );
      }

      return _firestore
          .collection('user_groups')
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    });
  }

  /// Update user group
  Future<void> updateUserGroup(
    String groupId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('user_groups').doc(groupId).update(updates);
    } catch (e) {
      print('Error updating user group: $e');
      rethrow;
    }
  }

  /// Delete user group
  Future<void> deleteUserGroup(String groupId) async {
    try {
      await _firestore.collection('user_groups').doc(groupId).delete();
    } catch (e) {
      print('Error deleting user group: $e');
      rethrow;
    }
  }

  /// Add user to group
  Future<void> addUserToGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('user_groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding user to group: $e');
      rethrow;
    }
  }

  /// Remove user from group
  Future<void> removeUserFromGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('user_groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing user from group: $e');
      rethrow;
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    if (error.toString().contains('PERMISSION_DENIED')) {
      return 'Permission denied. Please check your access rights.';
    } else if (error.toString().contains('NOT_FOUND')) {
      return 'Resource not found.';
    } else if (error.toString().contains('UNAVAILABLE')) {
      return 'Service unavailable. Please check your internet connection.';
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('User not authenticated')) {
      return 'Please sign in to continue.';
    } else {
      return 'An error occurred. Please try again later.';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hierarchical_firestore_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HierarchicalFirestoreService _hierarchical =
      HierarchicalFirestoreService();

  // Get current user's ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get the current user's organization ID from lightweight lookup doc
  Future<String?> getCurrentUserOrganizationId() async {
    return await _hierarchical.getCurrentUserOrganizationId();
  }

  /// Clear cached organization ID (call on sign out)
  void clearCache() {
    _hierarchical.clearCache();
  }

  /// Ensure there is a lightweight user lookup document at `users/{uid}`
  Future<void> ensureCanonicalUserDocument() async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      final canonicalRef = _firestore.collection('users').doc(uid);
      final canonicalSnap = await canonicalRef.get();
      if (canonicalSnap.exists) return; // Already present

      // Get org ID from organizations where user is admin
      final orgByAdmin = await _firestore
          .collection('organizations')
          .where('adminUserId', isEqualTo: uid)
          .limit(1)
          .get();

      if (orgByAdmin.docs.isNotEmpty) {
        final orgId = orgByAdmin.docs.first.id;
        final email = _auth.currentUser?.email ?? '';

        // Create lightweight lookup doc
        await _hierarchical.updateUserLookup(uid, orgId, email);
      }
    } catch (e) {
      print('ensureCanonicalUserDocument error: $e');
    }
  }

  /// Get current user's access level (Admin/Manager/Employee)
  Future<String?> getCurrentUserAccessLevel() async {
    final uid = _currentUserId;
    if (uid == null) return null;

    try {
      final orgId = await getCurrentUserOrganizationId();
      if (orgId == null) return null;

      final profile = await _hierarchical.getUserProfile(orgId, uid);
      return profile?['accessLevel'] as String?;
    } catch (e) {
      print('Error getting access level: $e');
      return null;
    }
  }

  // ==================== PROJECTS ====================

  /// Add a new project
  Future<String?> addProject(Map<String, dynamic> projectData) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      projectData['createdBy'] = _currentUserId;
      return await _hierarchical.createProject(organizationId, projectData);
    } catch (e) {
      print('Error adding project: $e');
      rethrow;
    }
  }

  /// Get all projects for the current user's organization
  Stream<QuerySnapshot> getProjects() {
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

      return _hierarchical.streamOrgProjects(organizationId);
    });
  }

  /// Update a project
  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> projectData,
  ) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      await _hierarchical.updateProject(organizationId, projectId, projectData);
    } catch (e) {
      print('Error updating project: $e');
      rethrow;
    }
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      await _hierarchical.deleteProject(organizationId, projectId);
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }

  // ==================== USERS ====================

  /// Generate a unique 8-character invitation code
  String generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    var value = random;

    for (int i = 0; i < 8; i++) {
      code += chars[value % chars.length];
      value = value ~/ chars.length;
    }

    return code;
  }

  /// Send user invitation (now under organizations/{orgId}/user_invitations)
  /// Returns both the created document id and the generated invitationCode
  Future<Map<String, String>?> sendUserInvitation(
    Map<String, dynamic> userData,
  ) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Ensure the lightweight lookup doc exists so Firestore rules can validate org membership
      String? organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        await ensureCanonicalUserDocument();
        organizationId = await getCurrentUserOrganizationId();
      }
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      final invitationCode = generateInvitationCode();
      final expiryDate = DateTime.now().add(const Duration(days: 14));

      userData['organizationId'] = organizationId;
      userData['invitedBy'] = _currentUserId;
      userData['invitationCode'] = invitationCode;
      userData['expiryDate'] = Timestamp.fromDate(expiryDate);
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      userData['status'] = 'Pending';
      userData['invitationCount'] = 1;

      final id = await _hierarchical.createInvitation(organizationId, userData);
      return {'id': id, 'invitationCode': invitationCode};
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
      if (organizationId != null) {
        // Preferred: scope to current org
        return _hierarchical
            .invitationsCollection(organizationId)
            .where('invitedBy', isEqualTo: _currentUserId)
            .snapshots();
      }

      // Fallback: If org lookup is missing (eg. legacy admin), use collectionGroup
      // filtered by inviter so the user still sees their invitations.
      // This avoids breaking the Invitations tab with an error state.
      return _firestore
          .collectionGroup('user_invitations')
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
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }
      await _hierarchical.updateInvitation(
        organizationId,
        invitationId,
        userData,
      );
    } catch (e) {
      print('Error updating invitation: $e');
      rethrow;
    }
  }

  /// Delete user invitation
  Future<void> deleteUserInvitation(String invitationId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }
      await _hierarchical.deleteInvitation(organizationId, invitationId);
    } catch (e) {
      print('Error deleting invitation: $e');
      rethrow;
    }
  }

  /// Resend invitation (update timestamp)
  Future<void> resendInvitation(String invitationId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }
      await _hierarchical.updateInvitation(organizationId, invitationId, {
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
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      await _hierarchical.updateUserProfile(organizationId, userId, {
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

      return _hierarchical.streamOrgUsers(organizationId);
    });
  }

  /// Validate invitation code and get invitation data
  /// Validate invitation by code using collection group query so it works across orgs
  Future<Map<String, dynamic>?> validateInvitationCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('user_invitations')
          .where('invitationCode', isEqualTo: code)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      final expiryDate = (data['expiryDate'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        return null;
      }

      return {...data, 'id': doc.id};
    } catch (e) {
      print('Error validating invitation code: $e');
      rethrow;
    }
  }

  /// Accept invitation and create user account
  /// Accept invitation under organization path
  Future<void> acceptInvitation(
    String invitationId,
    Map<String, dynamic> additionalUserData,
  ) async {
    try {
      final String? orgId = additionalUserData['organizationId'] as String?;

      // If orgId not present in the payload, fetch via collection group by id
      Map<String, dynamic>? invitationData;
      String? organizationId;
      DocumentSnapshot? invitationDoc;

      if (orgId != null) {
        organizationId = orgId;
        invitationDoc = await _hierarchical
            .invitationsCollection(organizationId)
            .doc(invitationId)
            .get();
      } else {
        // Fallback: organizationId should always be provided, but handle gracefully
        throw Exception(
          'Organization ID is required to accept invitation. Please validate the invitation code first.',
        );
      }

      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }
      invitationData = invitationDoc.data() as Map<String, dynamic>;
      // organizationId is guaranteed to be set above; no-op
      final userId = additionalUserData['userId'] as String;

      final userData = {
        ...invitationData,
        ...additionalUserData,
        'status': 'Active',
        'acceptedAt': FieldValue.serverTimestamp(),
      };

      userData.remove('invitationCode');
      userData.remove('expiryDate');
      userData.remove('invitationCount');

      // Create user profile in org hierarchy
      await _hierarchical.createUserProfile(organizationId, userId, userData);

      // Create lightweight lookup doc
      final email = userData['email'] as String? ?? '';
      await _hierarchical.updateUserLookup(userId, organizationId, email);

      // Delete the invitation from org path
      try {
        await _hierarchical
            .invitationsCollection(organizationId)
            .doc(invitationId)
            .delete();
      } catch (deleteError) {
        print('Note: Could not delete invitation: $deleteError');
      }
    } catch (e) {
      print('Error accepting invitation: $e');
      rethrow;
    }
  }

  /// Get invitation by ID
  Future<Map<String, dynamic>?> getInvitationById(String invitationId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) return null;
      final doc = await _hierarchical
          .invitationsCollection(organizationId)
          .doc(invitationId)
          .get();
      if (!doc.exists) return null;
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
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

      groupData['createdBy'] = _currentUserId;
      return await _hierarchical.createUserGroup(organizationId, groupData);
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

      return _hierarchical.streamOrgUserGroups(organizationId);
    });
  }

  /// Update user group
  Future<void> updateUserGroup(
    String groupId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      await _hierarchical.updateUserGroup(organizationId, groupId, updates);
    } catch (e) {
      print('Error updating user group: $e');
      rethrow;
    }
  }

  /// Delete user group
  Future<void> deleteUserGroup(String groupId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      await _hierarchical.deleteUserGroup(organizationId, groupId);
    } catch (e) {
      print('Error deleting user group: $e');
      rethrow;
    }
  }

  /// Add user to group
  Future<void> addUserToGroup(String groupId, String userId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      await _hierarchical.updateUserGroup(organizationId, groupId, {
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error adding user to group: $e');
      rethrow;
    }
  }

  /// Remove user from group
  Future<void> removeUserFromGroup(String groupId, String userId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) {
        throw Exception('User is not associated with an organization');
      }

      await _hierarchical.updateUserGroup(organizationId, groupId, {
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error removing user from group: $e');
      rethrow;
    }
  }

  // ==================== USER PROFILE ====================

  /// Get user's join date
  Future<DateTime?> getUserJoinDate(String userId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) return DateTime(DateTime.now().year, 1, 1);

      final profile = await _hierarchical.getUserProfile(
        organizationId,
        userId,
      );
      if (profile != null) {
        if (profile['hireDate'] != null) {
          return (profile['hireDate'] as Timestamp).toDate();
        }
        if (profile['createdAt'] != null) {
          return (profile['createdAt'] as Timestamp).toDate();
        }
      }
      return DateTime(DateTime.now().year, 1, 1);
    } catch (e) {
      print('Error getting user join date: $e');
      return DateTime(DateTime.now().year, 1, 1);
    }
  }

  /// Get user's annual leave entitlement
  Future<int?> getUserAnnualLeave(String userId) async {
    try {
      final organizationId = await getCurrentUserOrganizationId();
      if (organizationId == null) return null;

      final profile = await _hierarchical.getUserProfile(
        organizationId,
        userId,
      );
      return profile?['yearlyVacations'] as int?;
    } catch (e) {
      print('Error getting user annual leave: $e');
      return null;
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

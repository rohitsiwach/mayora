import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle hierarchical Firestore paths under organizations
///
/// New structure:
/// organizations/{orgId}/users/{userId}/
/// organizations/{orgId}/projects/{projectId}
/// organizations/{orgId}/user_groups/{groupId}
/// etc.
///
/// Top-level users/{uid} kept lightweight for org lookup only
class HierarchicalFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;
  String? _cachedOrganizationId;

  /// Get current user's organization ID from lightweight lookup doc
  Future<String?> getCurrentUserOrganizationId() async {
    if (_cachedOrganizationId != null) return _cachedOrganizationId;
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (doc.exists) {
        _cachedOrganizationId = doc.data()?['organizationId'] as String?;
        return _cachedOrganizationId;
      }
      return null;
    } catch (e) {
      print('Error getting organization ID: $e');
      return null;
    }
  }

  /// Clear cached org ID (call on sign out)
  void clearCache() {
    _cachedOrganizationId = null;
  }

  // === PATH HELPERS ===

  /// Get organization collection reference
  /// Returns: organizations/{orgId}
  DocumentReference orgDoc(String orgId) {
    return _firestore.collection('organizations').doc(orgId);
  }

  /// Get users collection under org
  /// Returns: organizations/{orgId}/users
  CollectionReference usersCollection(String orgId) {
    return orgDoc(orgId).collection('users');
  }

  /// Get specific user doc under org
  /// Returns: organizations/{orgId}/users/{userId}
  DocumentReference userDoc(String orgId, String userId) {
    return usersCollection(orgId).doc(userId);
  }

  /// Get schedules collection for a user
  /// Returns: organizations/{orgId}/users/{userId}/schedules
  CollectionReference schedulesCollection(String orgId, String userId) {
    return userDoc(orgId, userId).collection('schedules');
  }

  /// Get leaves collection for a user
  /// Returns: organizations/{orgId}/users/{userId}/leaves
  CollectionReference leavesCollection(String orgId, String userId) {
    return userDoc(orgId, userId).collection('leaves');
  }

  /// Get projects collection under org
  /// Returns: organizations/{orgId}/projects
  CollectionReference projectsCollection(String orgId) {
    return orgDoc(orgId).collection('projects');
  }

  /// Get user_groups collection under org
  /// Returns: organizations/{orgId}/user_groups
  CollectionReference userGroupsCollection(String orgId) {
    return orgDoc(orgId).collection('user_groups');
  }

  /// Get work_locations collection under org
  /// Returns: organizations/{orgId}/work_locations
  CollectionReference workLocationsCollection(String orgId) {
    return orgDoc(orgId).collection('work_locations');
  }

  /// Get location_settings collection under org
  /// Returns: organizations/{orgId}/location_settings
  CollectionReference locationSettingsCollection(String orgId) {
    return orgDoc(orgId).collection('location_settings');
  }

  /// Get user_invitations collection under org
  /// Returns: organizations/{orgId}/user_invitations
  CollectionReference invitationsCollection(String orgId) {
    return orgDoc(orgId).collection('user_invitations');
  }

  // === INVITATION OPERATIONS ===

  /// Create user invitation under organization
  Future<String> createInvitation(
    String orgId,
    Map<String, dynamic> data,
  ) async {
    final ref = await invitationsCollection(orgId).add({
      ...data,
      'organizationId': orgId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Stream invitations under organization
  Stream<QuerySnapshot> streamOrgInvitations(String orgId) {
    return invitationsCollection(orgId).snapshots();
  }

  /// Update invitation document
  Future<void> updateInvitation(
    String orgId,
    String invitationId,
    Map<String, dynamic> updates,
  ) async {
    await invitationsCollection(orgId).doc(invitationId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete invitation document
  Future<void> deleteInvitation(String orgId, String invitationId) async {
    await invitationsCollection(orgId).doc(invitationId).delete();
  }

  // === USER OPERATIONS ===

  /// Create or update lightweight top-level user lookup doc
  /// Should contain: { organizationId, email, userId }
  Future<void> updateUserLookup(
    String userId,
    String orgId,
    String email,
  ) async {
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'organizationId': orgId,
      'email': email,
    }, SetOptions(merge: false)); // Replace entirely
  }

  /// Create user profile under organization
  Future<void> createUserProfile(
    String orgId,
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await userDoc(orgId, userId).set({
      ...userData,
      'userId': userId,
      'organizationId': orgId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user profile from org hierarchy
  Future<Map<String, dynamic>?> getUserProfile(
    String orgId,
    String userId,
  ) async {
    final doc = await userDoc(orgId, userId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return {...data, 'id': doc.id};
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String orgId,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await userDoc(
      orgId,
      userId,
    ).update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Get all users in organization
  Stream<QuerySnapshot> streamOrgUsers(String orgId) {
    return usersCollection(orgId).snapshots();
  }

  // === PROJECT OPERATIONS ===

  /// Create project under organization
  Future<String> createProject(
    String orgId,
    Map<String, dynamic> projectData,
  ) async {
    final docRef = await projectsCollection(orgId).add({
      ...projectData,
      'organizationId': orgId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get all projects in organization
  Stream<QuerySnapshot> streamOrgProjects(String orgId) {
    return projectsCollection(orgId).snapshots();
  }

  /// Update project
  Future<void> updateProject(
    String orgId,
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    await projectsCollection(orgId).doc(projectId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete project
  Future<void> deleteProject(String orgId, String projectId) async {
    await projectsCollection(orgId).doc(projectId).delete();
  }

  // === USER GROUP OPERATIONS ===

  /// Create user group under organization
  Future<String> createUserGroup(
    String orgId,
    Map<String, dynamic> groupData,
  ) async {
    final docRef = await userGroupsCollection(orgId).add({
      ...groupData,
      'organizationId': orgId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get all user groups in organization
  Stream<QuerySnapshot> streamOrgUserGroups(String orgId) {
    return userGroupsCollection(orgId).snapshots();
  }

  /// Update user group
  Future<void> updateUserGroup(
    String orgId,
    String groupId,
    Map<String, dynamic> updates,
  ) async {
    await userGroupsCollection(orgId).doc(groupId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete user group
  Future<void> deleteUserGroup(String orgId, String groupId) async {
    await userGroupsCollection(orgId).doc(groupId).delete();
  }

  // === SCHEDULE OPERATIONS ===

  /// Create schedule for a user
  Future<String> createSchedule(
    String orgId,
    String userId,
    Map<String, dynamic> scheduleData,
  ) async {
    final docRef = await schedulesCollection(orgId, userId).add({
      ...scheduleData,
      'userId': userId,
      'organizationId': orgId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get schedules for a user
  Stream<QuerySnapshot> streamUserSchedules(String orgId, String userId) {
    return schedulesCollection(orgId, userId).snapshots();
  }

  /// Update schedule
  Future<void> updateSchedule(
    String orgId,
    String userId,
    String scheduleId,
    Map<String, dynamic> updates,
  ) async {
    await schedulesCollection(orgId, userId).doc(scheduleId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete schedule
  Future<void> deleteSchedule(
    String orgId,
    String userId,
    String scheduleId,
  ) async {
    await schedulesCollection(orgId, userId).doc(scheduleId).delete();
  }

  // === LEAVE OPERATIONS ===

  /// Create leave request for a user
  Future<String> createLeaveRequest(
    String orgId,
    String userId,
    Map<String, dynamic> leaveData,
  ) async {
    final docRef = await leavesCollection(orgId, userId).add({
      ...leaveData,
      'userId': userId,
      'organizationId': orgId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get leaves for a user
  Stream<QuerySnapshot> streamUserLeaves(String orgId, String userId) {
    return leavesCollection(orgId, userId).snapshots();
  }

  /// Update leave request (approve/reject/cancel)
  Future<void> updateLeaveRequest(
    String orgId,
    String userId,
    String leaveId,
    Map<String, dynamic> updates,
  ) async {
    await leavesCollection(orgId, userId).doc(leaveId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

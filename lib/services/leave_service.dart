import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_request.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a new leave request to user's subcollection
  Future<void> submitUserLeaveRequest(String userId, LeaveRequest request) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .add(request.toMap());
  }

  // Get leave requests stream for a specific user from their subcollection
  Stream<List<LeaveRequest>> getUserLeavesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get all leave requests for an organization (for managers/admins)
  // This uses collection group query to get all leaves across all users
  Stream<List<LeaveRequest>> getOrganizationLeaveRequests(String organizationId) {
    return _firestore
        .collectionGroup('leaves')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Calculate total annual leaves taken for a user in current year
  Future<int> getUserAnnualLeavesTaken(String userId) async {
    final currentYear = DateTime.now().year;
    final startOfYear = DateTime(currentYear, 1, 1);
    final endOfYear = DateTime(currentYear, 12, 31);

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .where('status', isEqualTo: 'approved')
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
        .get();

    int totalDays = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalDays += (data['numberOfDays'] ?? 0) as int;
    }
    return totalDays;
  }

  // Get pending leave requests count for user
  Future<int> getPendingRequestsCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  // Calculate used leave days by type for a user in current year
  Future<int> getUsedLeaveDays(String userId, String leaveTypeId) async {
    final currentYear = DateTime.now().year;
    final startOfYear = DateTime(currentYear, 1, 1);
    final endOfYear = DateTime(currentYear, 12, 31);

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .where('leaveTypeId', isEqualTo: leaveTypeId)
        .where('status', isEqualTo: 'approved')
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
        .get();

    int totalDays = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalDays += (data['numberOfDays'] ?? 0) as int;
    }
    return totalDays;
  }

  // Update leave request status (for managers/admins)
  // This requires knowing both userId and requestId
  Future<void> updateLeaveStatus({
    required String userId,
    required String requestId,
    required String status,
    required String reviewedBy,
    String? comments,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .doc(requestId)
        .update({
      'status': status,
      'reviewedAt': Timestamp.now(),
      'reviewedBy': reviewedBy,
      'reviewComments': comments,
    });
  }

  // Cancel leave request (only if pending)
  Future<void> cancelLeaveRequest(String userId, String requestId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('leaves')
        .doc(requestId)
        .update({
      'status': 'cancelled',
    });
  }
}

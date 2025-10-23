import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_request.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a new leave request
  Future<void> submitLeaveRequest(LeaveRequest request) async {
    await _firestore.collection('leave_requests').add(request.toMap());
  }

  // Get leave requests for a specific user
  Stream<List<LeaveRequest>> getUserLeaveRequests(String userId) {
    return _firestore
        .collection('leave_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get all leave requests for an organization (for managers/admins)
  Stream<List<LeaveRequest>> getOrganizationLeaveRequests(String organizationId) {
    return _firestore
        .collection('leave_requests')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get pending leave requests count for user
  Future<int> getPendingRequestsCount(String userId) async {
    final snapshot = await _firestore
        .collection('leave_requests')
        .where('userId', isEqualTo: userId)
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
        .collection('leave_requests')
        .where('userId', isEqualTo: userId)
        .where('leaveTypeId', isEqualTo: leaveTypeId)
        .where('status', isEqualTo: 'approved')
        .where('startDate', isGreaterThanOrEqualTo: startOfYear.toIso8601String())
        .where('startDate', isLessThanOrEqualTo: endOfYear.toIso8601String())
        .get();

    int totalDays = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalDays += (data['numberOfDays'] ?? 0) as int;
    }
    return totalDays;
  }

  // Update leave request status (for managers/admins)
  Future<void> updateLeaveStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? comments,
  }) async {
    await _firestore.collection('leave_requests').doc(requestId).update({
      'status': status,
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewComments': comments,
    });
  }

  // Cancel leave request (only if pending)
  Future<void> cancelLeaveRequest(String requestId) async {
    await _firestore.collection('leave_requests').doc(requestId).update({
      'status': 'cancelled',
    });
  }
}

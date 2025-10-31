import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_request.dart';
import 'hierarchical_firestore_service.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HierarchicalFirestoreService _hierarchical =
      HierarchicalFirestoreService();

  // Submit a new leave request to user's subcollection under org
  Future<void> submitUserLeaveRequest(
    String organizationId,
    String userId,
    LeaveRequest request,
  ) async {
    await _hierarchical
        .leavesCollection(organizationId, userId)
        .add(request.toMap());
  }

  // Get leave requests stream for a specific user from their subcollection
  Stream<List<LeaveRequest>> getUserLeavesStream(
    String organizationId,
    String userId,
  ) {
    return _hierarchical
        .leavesCollection(organizationId, userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => LeaveRequest.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get all leave requests for an organization (for managers/admins)
  // This uses collection group query to get all leaves across all users
  Stream<List<LeaveRequest>> getOrganizationLeaveRequests(
    String organizationId,
  ) {
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
  Future<int> getUserAnnualLeavesTaken(
    String organizationId,
    String userId,
  ) async {
    final currentYear = DateTime.now().year;
    final startOfYear = DateTime(currentYear, 1, 1);
    final endOfYear = DateTime(currentYear, 12, 31);

    final snapshot = await _hierarchical
        .leavesCollection(organizationId, userId)
        .where('status', isEqualTo: 'approved')
        .where(
          'startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
        )
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
        .get();

    int totalDays = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalDays += (data['numberOfDays'] ?? 0) as int;
      }
    }
    return totalDays;
  }

  // Get pending leave requests count for user
  Future<int> getPendingRequestsCount(
    String organizationId,
    String userId,
  ) async {
    final snapshot = await _hierarchical
        .leavesCollection(organizationId, userId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  // Calculate used leave days by type for a user in current year
  Future<int> getUsedLeaveDays(
    String organizationId,
    String userId,
    String leaveTypeId,
  ) async {
    final currentYear = DateTime.now().year;
    final startOfYear = DateTime(currentYear, 1, 1);
    final endOfYear = DateTime(currentYear, 12, 31);

    final snapshot = await _hierarchical
        .leavesCollection(organizationId, userId)
        .where('leaveTypeId', isEqualTo: leaveTypeId)
        .where('status', isEqualTo: 'approved')
        .where(
          'startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
        )
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
        .get();

    int totalDays = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        totalDays += (data['numberOfDays'] ?? 0) as int;
      }
    }
    return totalDays;
  }

  // Check if a user has an approved leave that includes the given date
  Future<bool> hasApprovedLeaveOn(
    String organizationId,
    String userId,
    DateTime date,
  ) async {
    final day = DateTime(date.year, date.month, date.day);
    // Firestore restriction: only one range filter per query field. We'll
    // filter by startDate <= date, then check endDate >= date in memory.
    final snapshot = await _hierarchical
        .leavesCollection(organizationId, userId)
        .where('status', isEqualTo: 'approved')
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(day))
        .orderBy('startDate', descending: true)
        .limit(25)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final endTs = data['endDate'] as Timestamp?;
        if (endTs != null) {
          final end = endTs.toDate();
          if (!end.isBefore(day)) {
            return true; // Conflict: leave spans the day
          }
        }
      }
    }
    return false;
  }

  // Update leave request status (for managers/admins)
  // This requires knowing both orgId, userId and requestId
  Future<void> updateLeaveStatus({
    required String organizationId,
    required String userId,
    required String requestId,
    required String status,
    required String reviewedBy,
    String? comments,
  }) async {
    await _hierarchical
        .leavesCollection(organizationId, userId)
        .doc(requestId)
        .update({
          'status': status,
          'reviewedAt': Timestamp.now(),
          'reviewedBy': reviewedBy,
          'reviewComments': comments,
        });
  }

  // Cancel leave request (only if pending)
  Future<void> cancelLeaveRequest(
    String organizationId,
    String userId,
    String requestId,
  ) async {
    await _hierarchical
        .leavesCollection(organizationId, userId)
        .doc(requestId)
        .update({'status': 'cancelled'});
  }
}

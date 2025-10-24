import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_schedule.dart';
import 'leave_service.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  /// Create a schedule document under organizations/{orgId}/schedules
  Future<void> createSchedule(ShiftSchedule schedule) async {
    final orgRef = _firestore
        .collection('organizations')
        .doc(schedule.organizationId)
        .collection('schedules');

    // Deterministic ID for idempotency: userId_yyyyMMdd
    final keyDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
    final id = '${schedule.userId}_${keyDate.year}${keyDate.month.toString().padLeft(2, '0')}${keyDate.day.toString().padLeft(2, '0')}';
    await orgRef.doc(id).set(schedule.toMap());
  }

  /// Batch-create schedules for multiple users across multiple dates.
  /// Returns a stream of progress messages.
  Stream<SchedulingProgress> createSchedulesBatch({
    required String organizationId,
    required String createdBy,
    required String title,
    required List<String> userIds,
    required DateTime startDate,
    required Recurrence recurrence,
    Set<int>? selectedDays, // 1=Mon, 7=Sun; only used if recurrence=weekly
  }) async* {
    final endOfYear = DateTime(startDate.year, 12, 31);
    final dates = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    while (!current.isAfter(endOfYear)) {
      // If weekly and selectedDays is provided, only include matching weekdays
      if (recurrence == Recurrence.weekly && selectedDays != null && selectedDays.isNotEmpty) {
        if (selectedDays.contains(current.weekday)) {
          dates.add(current);
        }
      } else {
        dates.add(current);
      }
      if (recurrence == Recurrence.none) break;
      current = recurrence == Recurrence.daily
          ? current.add(const Duration(days: 1))
          : current.add(const Duration(days: 7));
    }

    int total = dates.length * userIds.length;
    int completed = 0;

    for (final date in dates) {
      for (final userId in userIds) {
        try {
          final conflict = await _leaveService.hasApprovedLeaveOn(userId, date);
          if (conflict) {
            completed++;
            yield SchedulingProgress(
              completed: completed,
              total: total,
              message: 'Skipped: $userId on ${_fmt(date)} (approved leave)',
              isError: false,
            );
            continue;
          }

          final schedule = ShiftSchedule(
            organizationId: organizationId,
            userId: userId,
            title: title,
            date: date,
            createdBy: createdBy,
            createdAt: DateTime.now(),
          );
          await createSchedule(schedule);
          completed++;
          yield SchedulingProgress(
            completed: completed,
            total: total,
            message: 'Scheduled: $userId on ${_fmt(date)}',
            isError: false,
          );
        } catch (e) {
          completed++;
          yield SchedulingProgress(
            completed: completed,
            total: total,
            message: 'Error: $userId on ${_fmt(date)} -> $e',
            isError: true,
          );
        }
      }
    }
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

enum Recurrence { none, daily, weekly }

class SchedulingProgress {
  final int completed;
  final int total;
  final String message;
  final bool isError;

  SchedulingProgress({
    required this.completed,
    required this.total,
    required this.message,
    required this.isError,
  });
}

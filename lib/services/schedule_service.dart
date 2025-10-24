import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_schedule.dart';
import 'leave_service.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  /// Create a schedule document under users/{userId}/schedules
  Future<void> createSchedule(ShiftSchedule schedule) async {
    final userRef = _firestore
        .collection('users')
        .doc(schedule.userId)
        .collection('schedules');

    // Deterministic ID for idempotency: yyyyMMdd
    final keyDate = DateTime(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
    );
    final id =
        '${keyDate.year}${keyDate.month.toString().padLeft(2, '0')}${keyDate.day.toString().padLeft(2, '0')}';
    await userRef.doc(id).set(schedule.toMap());
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
    
    // For non-recurring, just add the start date
    if (recurrence == Recurrence.none) {
      dates.add(current);
    } else if (recurrence == Recurrence.daily) {
      // Add all days from startDate to end of year
      while (!current.isAfter(endOfYear)) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
    } else if (recurrence == Recurrence.weekly) {
      // For weekly recurrence with specific days selected
      if (selectedDays != null && selectedDays.isNotEmpty) {
        // Iterate through all days from start to end, adding only matching weekdays
        while (!current.isAfter(endOfYear)) {
          if (selectedDays.contains(current.weekday)) {
            dates.add(current);
          }
          current = current.add(const Duration(days: 1));
        }
      } else {
        // No specific days selected, repeat same weekday as startDate every week
        while (!current.isAfter(endOfYear)) {
          dates.add(current);
          current = current.add(const Duration(days: 7));
        }
      }
    }

    print('[ScheduleService] Generated ${dates.length} dates for scheduling');
    print('[ScheduleService] First 5 dates: ${dates.take(5).map((d) => _fmt(d)).join(", ")}');
    if (dates.length > 5) {
      print('[ScheduleService] Last 5 dates: ${dates.skip(dates.length - 5).map((d) => _fmt(d)).join(", ")}');
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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

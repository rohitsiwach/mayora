class ProjectTimeEntry {
  final String projectId;
  final String projectName;
  final int durationMs;

  ProjectTimeEntry({
    required this.projectId,
    required this.projectName,
    required this.durationMs,
  });

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    'projectName': projectName,
    'durationMs': durationMs,
  };

  static ProjectTimeEntry fromMap(Map<String, dynamic> map) => ProjectTimeEntry(
    projectId: map['projectId'] ?? '',
    projectName: map['projectName'] ?? '',
    durationMs: (map['durationMs'] ?? 0) as int,
  );
}

class ShiftRecord {
  final String orgId;
  final String userId;
  final String? shiftId; // Firestore doc id if known
  final DateTime clockInTime;
  final DateTime clockOutTime;
  final int totalHoursAtWorkMs;
  final int actualWorkingHoursMs;
  final int totalBreakTimeMs;
  final List<ProjectTimeEntry> projectBreakdown;
  final bool shiftAdjustmentsMade;
  final bool isAutoEnded;
  final String date; // yyyy-MM-dd
  final int weekOfYear; // ISO week approx
  final int monthOfYear;
  final int year;

  ShiftRecord({
    required this.orgId,
    required this.userId,
    this.shiftId,
    required this.clockInTime,
    required this.clockOutTime,
    required this.totalHoursAtWorkMs,
    required this.actualWorkingHoursMs,
    required this.totalBreakTimeMs,
    required this.projectBreakdown,
    required this.shiftAdjustmentsMade,
    required this.isAutoEnded,
    required this.date,
    required this.weekOfYear,
    required this.monthOfYear,
    required this.year,
  });

  Map<String, dynamic> toMap() => {
    'orgId': orgId,
    'userId': userId,
    'clockInTime': clockInTime.toUtc().toIso8601String(),
    'clockOutTime': clockOutTime.toUtc().toIso8601String(),
    'totalHoursAtWorkMs': totalHoursAtWorkMs,
    'actualWorkingHoursMs': actualWorkingHoursMs,
    'totalBreakTimeMs': totalBreakTimeMs,
    'projectBreakdown': projectBreakdown.map((e) => e.toMap()).toList(),
    'shiftAdjustmentsMade': shiftAdjustmentsMade,
    'isAutoEnded': isAutoEnded,
    'date': date,
    'weekOfYear': weekOfYear,
    'monthOfYear': monthOfYear,
    'year': year,
  };
}

int _isoWeekNumber(DateTime date) {
  final thursday = date.add(Duration(days: (3 - (date.weekday + 6) % 7)));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final week = 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
  return week;
}

String yyyymmdd(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

Map<String, dynamic> buildShiftRecordMap({
  required String orgId,
  required String userId,
  required DateTime clockInTime,
  required DateTime clockOutTime,
  required int totalHoursAtWorkMs,
  required int actualWorkingHoursMs,
  required int totalBreakTimeMs,
  required List<ProjectTimeEntry> projectBreakdown,
  required bool shiftAdjustmentsMade,
  required bool isAutoEnded,
}) {
  final date = yyyymmdd(clockInTime.toLocal());
  final week = _isoWeekNumber(clockInTime.toLocal());
  return {
    'orgId': orgId,
    'userId': userId,
    'clockInTime': clockInTime.toUtc().toIso8601String(),
    'clockOutTime': clockOutTime.toUtc().toIso8601String(),
    'totalHoursAtWorkMs': totalHoursAtWorkMs,
    'actualWorkingHoursMs': actualWorkingHoursMs,
    'totalBreakTimeMs': totalBreakTimeMs,
    'projectBreakdown': projectBreakdown.map((e) => e.toMap()).toList(),
    'shiftAdjustmentsMade': shiftAdjustmentsMade,
    'isAutoEnded': isAutoEnded,
    'date': date,
    'weekOfYear': week,
    'monthOfYear': clockInTime.month,
    'year': clockInTime.year,
  };
}

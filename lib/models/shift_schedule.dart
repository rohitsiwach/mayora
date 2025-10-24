import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftSchedule {
  final String? id;
  final String organizationId;
  final String userId;
  final String title;
  final DateTime date; // Date-only semantics
  final String? startTime; // Format: "HH:mm" (e.g., "09:00")
  final String? endTime; // Format: "HH:mm" (e.g., "17:00")
  final String createdBy;
  final DateTime createdAt;

  ShiftSchedule({
    this.id,
    required this.organizationId,
    required this.userId,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'organizationId': organizationId,
      'userId': userId,
      'title': title,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    
    if (startTime != null) map['startTime'] = startTime!;
    if (endTime != null) map['endTime'] = endTime!;
    
    return map;
  }

  factory ShiftSchedule.fromMap(String id, Map<String, dynamic> map) {
    return ShiftSchedule(
      id: id,
      organizationId: map['organizationId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

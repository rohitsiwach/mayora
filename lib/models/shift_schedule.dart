import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftSchedule {
  final String? id;
  final String organizationId;
  final String userId;
  final String title;
  final DateTime date; // Date-only semantics
  final String createdBy;
  final DateTime createdAt;

  ShiftSchedule({
    this.id,
    required this.organizationId,
    required this.userId,
    required this.title,
    required this.date,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'userId': userId,
      'title': title,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ShiftSchedule.fromMap(String id, Map<String, dynamic> map) {
    return ShiftSchedule(
      id: id,
      organizationId: map['organizationId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

import 'package:flutter/material.dart';

class LeaveType {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int maxDaysPerYear;
  final bool requiresApproval;

  LeaveType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.maxDaysPerYear,
    this.requiresApproval = true,
  });

  // Predefined leave types
  static final List<LeaveType> defaultTypes = [
    LeaveType(
      id: 'annual',
      name: 'Annual Leave',
      description: 'Paid time off for vacation and personal matters',
      icon: '🏖️',
      maxDaysPerYear: 30,
    ),
    LeaveType(
      id: 'sick',
      name: 'Sick Leave',
      description: 'Leave for illness or medical appointments',
      icon: '🤒',
      maxDaysPerYear: 15,
    ),
    LeaveType(
      id: 'personal',
      name: 'Personal Leave',
      description: 'Leave for personal emergencies or urgent matters',
      icon: '👤',
      maxDaysPerYear: 10,
    ),
    LeaveType(
      id: 'maternity',
      name: 'Maternity Leave',
      description: 'Leave for childbirth and childcare',
      icon: '👶',
      maxDaysPerYear: 180,
    ),
    LeaveType(
      id: 'paternity',
      name: 'Paternity Leave',
      description: 'Leave for fathers after childbirth',
      icon: '👨‍👦',
      maxDaysPerYear: 30,
    ),
    LeaveType(
      id: 'unpaid',
      name: 'Unpaid Leave',
      description: 'Leave without pay for extended periods',
      icon: '📋',
      maxDaysPerYear: 365,
    ),
    LeaveType(
      id: 'bereavement',
      name: 'Bereavement Leave',
      description: 'Leave for family member loss',
      icon: '🕊️',
      maxDaysPerYear: 7,
    ),
    LeaveType(
      id: 'study',
      name: 'Study Leave',
      description: 'Leave for education and professional development',
      icon: '📚',
      maxDaysPerYear: 20,
    ),
  ];
}

class LeaveRequest {
  final String? id;
  final String userId;
  final String userName;
  final String organizationId;
  final String leaveTypeId;
  final String leaveTypeName;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfDays;
  final String reason;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewComments;

  LeaveRequest({
    this.id,
    required this.userId,
    required this.userName,
    required this.organizationId,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.reason,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewComments,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'organizationId': organizationId,
      'leaveTypeId': leaveTypeId,
      'leaveTypeName': leaveTypeName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'numberOfDays': numberOfDays,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'reviewComments': reviewComments,
    };
  }

  factory LeaveRequest.fromMap(String id, Map<String, dynamic> map) {
    return LeaveRequest(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      organizationId: map['organizationId'] ?? '',
      leaveTypeId: map['leaveTypeId'] ?? '',
      leaveTypeName: map['leaveTypeName'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      numberOfDays: map['numberOfDays'] ?? 0,
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt']) : null,
      reviewedBy: map['reviewedBy'],
      reviewComments: map['reviewComments'],
    );
  }

  Color get statusColor {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String get statusDisplay {
    return status[0].toUpperCase() + status.substring(1);
  }
}

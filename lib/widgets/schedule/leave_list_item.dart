import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leave_request.dart';

/// List item card used in the day details list for leaves.
class LeaveListItem extends StatelessWidget {
  const LeaveListItem({super.key, required this.leave});

  final LeaveRequest leave;

  @override
  Widget build(BuildContext context) {
    final isMultiDay = leave.numberOfDays > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
          child: const Icon(Icons.beach_access, color: Color(0xFF4CAF50)),
        ),
        title: Text(
          leave.leaveTypeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.event, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    isMultiDay
                        ? '${DateFormat('MMM d').format(leave.startDate)} - ${DateFormat('MMM d, yyyy').format(leave.endDate)}'
                        : DateFormat('MMM d, yyyy').format(leave.startDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${leave.numberOfDays} ${leave.numberOfDays == 1 ? 'day' : 'days'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Approved',
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

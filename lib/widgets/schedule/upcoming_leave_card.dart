import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leave_request.dart';

/// Card used in the Upcoming section to display an approved leave entry.
class UpcomingLeaveCard extends StatelessWidget {
  const UpcomingLeaveCard({super.key, required this.leave});

  final LeaveRequest leave;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final leaveStart = DateTime(
      leave.startDate.year,
      leave.startDate.month,
      leave.startDate.day,
    );
    final daysUntil = leaveStart.difference(today).inDays;

    String daysText;
    Color accentColor;

    if (daysUntil == 0) {
      daysText = 'Today';
      accentColor = const Color(0xFF4CAF50);
    } else if (daysUntil == 1) {
      daysText = 'Tomorrow';
      accentColor = const Color(0xFF66BB6A);
    } else {
      daysText = 'in $daysUntil days';
      accentColor = const Color(0xFF2E7D32);
    }

    final isMultiDay = leave.numberOfDays > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                leave.startDate.day.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              Text(
                DateFormat('MMM').format(leave.startDate).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          leave.leaveTypeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.event, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    isMultiDay
                        ? '${DateFormat('MMM d').format(leave.startDate)} - ${DateFormat('MMM d').format(leave.endDate)}'
                        : DateFormat('MMM d, yyyy').format(leave.startDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: accentColor,
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Text(
            daysText,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

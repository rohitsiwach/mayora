import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_schedule.dart';

/// List item card used in the day details list for shifts.
class ShiftListItem extends StatelessWidget {
  const ShiftListItem({super.key, required this.shift});

  final ShiftSchedule shift;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF673AB7).withOpacity(0.1),
          child: const Icon(Icons.work_outline, color: Color(0xFF673AB7)),
        ),
        title: Text(
          shift.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shift.startTime != null && shift.endTime != null
                        ? '${shift.startTime} - ${shift.endTime}'
                        : 'Time not set',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Created: ${DateFormat('MMM d, yyyy').format(shift.createdAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Scheduled',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

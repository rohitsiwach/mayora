import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_schedule.dart';

/// Card used in the Upcoming section to display a shift with date and time.
class UpcomingShiftCard extends StatelessWidget {
  const UpcomingShiftCard({super.key, required this.shift});

  final ShiftSchedule shift;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shiftDate = DateTime(
      shift.date.year,
      shift.date.month,
      shift.date.day,
    );
    final daysUntil = shiftDate.difference(today).inDays;

    String daysText;
    Color accentColor;

    if (daysUntil == 0) {
      daysText = 'Today';
      accentColor = const Color(0xFFFF5722);
    } else if (daysUntil == 1) {
      daysText = 'Tomorrow';
      accentColor = const Color(0xFFFF9800);
    } else {
      daysText = 'in $daysUntil days';
      accentColor = const Color(0xFF673AB7);
    }

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
                shift.date.day.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              Text(
                DateFormat('MMM').format(shift.date).toUpperCase(),
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
          shift.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    shift.startTime != null && shift.endTime != null
                        ? '${shift.startTime} - ${shift.endTime}'
                        : 'Time not set',
                    style: TextStyle(
                      fontSize: 13,
                      color: shift.startTime != null && shift.endTime != null
                          ? accentColor
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('EEEE').format(shift.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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

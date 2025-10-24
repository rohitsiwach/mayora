import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/shift_schedule.dart';
import '../models/leave_request.dart';
import '../services/auth_service.dart';

class ShiftCalendarWidget extends StatefulWidget {
  const ShiftCalendarWidget({super.key});

  @override
  State<ShiftCalendarWidget> createState() => _ShiftCalendarWidgetState();
}

class _ShiftCalendarWidgetState extends State<ShiftCalendarWidget> {
  final _auth = AuthService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ShiftSchedule>> _shifts = {};
  Map<DateTime, List<LeaveRequest>> _leaves = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadShifts();
    _loadLeaves();
  }

  Future<void> _loadShifts() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Load shifts for the current month and adjacent months
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('schedules')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<DateTime, List<ShiftSchedule>> shifts = {};
      for (final doc in snapshot.docs) {
        final shift = ShiftSchedule.fromMap(doc.id, doc.data());
        final dateOnly = DateTime(
          shift.date.year,
          shift.date.month,
          shift.date.day,
        );

        if (shifts[dateOnly] == null) {
          shifts[dateOnly] = [];
        }
        shifts[dateOnly]!.add(shift);
      }

      setState(() {
        _shifts = shifts;
        _loading = false;
      });
    } catch (e) {
      print('[ShiftCalendarWidget] Error loading shifts: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLeaves() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Load approved leaves for the current month and adjacent months
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('leaves')
          .where('status', isEqualTo: 'approved')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<DateTime, List<LeaveRequest>> leaves = {};
      for (final doc in snapshot.docs) {
        final leave = LeaveRequest.fromMap(doc.id, doc.data());

        // Only include leaves that end after our start date
        if (leave.endDate.isAfter(startDate) ||
            leave.endDate.isAtSameMomentAs(startDate)) {
          // Add leave to all dates in its range
          DateTime currentDate = leave.startDate.isAfter(startDate)
              ? leave.startDate
              : startDate;

          while (currentDate.isBefore(leave.endDate) ||
              currentDate.isAtSameMomentAs(leave.endDate)) {
            if (currentDate.isBefore(endDate) ||
                currentDate.isAtSameMomentAs(endDate)) {
              final dateOnly = DateTime(
                currentDate.year,
                currentDate.month,
                currentDate.day,
              );

              if (leaves[dateOnly] == null) {
                leaves[dateOnly] = [];
              }
              leaves[dateOnly]!.add(leave);
            }
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
      }

      setState(() {
        _leaves = leaves;
      });
    } catch (e) {
      print('[ShiftCalendarWidget] Error loading leaves: $e');
    }
  }

  List<ShiftSchedule> _getShiftsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _shifts[dateOnly] ?? [];
  }

  List<ShiftSchedule> _getUpcomingShifts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final upcomingShifts = <ShiftSchedule>[];

    for (final entry in _shifts.entries) {
      final date = entry.key;
      if ((date.isAfter(today) || date.isAtSameMomentAs(today)) &&
          date.isBefore(nextWeek)) {
        upcomingShifts.addAll(entry.value);
      }
    }

    // Sort by date
    upcomingShifts.sort((a, b) => a.date.compareTo(b.date));

    return upcomingShifts;
  }

  List<LeaveRequest> _getUpcomingLeaves() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final upcomingLeaves = <LeaveRequest>[];
    final seenLeaveIds = <String>{};

    for (final entry in _leaves.entries) {
      final date = entry.key;
      if ((date.isAfter(today) || date.isAtSameMomentAs(today)) &&
          date.isBefore(nextWeek)) {
        for (final leave in entry.value) {
          // Add each leave only once (since it appears on multiple dates)
          final leaveId = leave.id ?? '';
          if (leaveId.isNotEmpty && !seenLeaveIds.contains(leaveId)) {
            upcomingLeaves.add(leave);
            seenLeaveIds.add(leaveId);
          }
        }
      }
    }

    // Sort by start date
    upcomingLeaves.sort((a, b) => a.startDate.compareTo(b.startDate));

    return upcomingLeaves;
  }

  List<LeaveRequest> _getLeavesForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _leaves[dateOnly] ?? [];
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return [..._getShiftsForDay(day), ..._getLeavesForDay(day)];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF673AB7)),
                const SizedBox(width: 8),
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF673AB7),
                  ),
                ),
                const Spacer(),
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Shifts Section
                  _buildUpcomingShiftsSection(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Calendar Section
                  Text(
                    'Full Schedule',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TableCalendar<dynamic>(
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF673AB7),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF9C27B0).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF673AB7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadShifts(); // Reload shifts when month changes
                      _loadLeaves(); // Reload leaves when month changes
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildShiftsList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingShiftsSection() {
    final upcomingShifts = _getUpcomingShifts();
    final upcomingLeaves = _getUpcomingLeaves();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.upcoming, color: Color(0xFF673AB7), size: 20),
            const SizedBox(width: 8),
            Text(
              'Upcoming Shifts & Leaves (Next 7 Days)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcomingShifts.isEmpty && upcomingLeaves.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.event_available, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No shifts or leaves scheduled in the next 7 days',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...upcomingShifts.map((shift) => _buildUpcomingShiftCard(shift)),
          ...upcomingLeaves.map((leave) => _buildUpcomingLeaveCard(leave)),
        ],
      ],
    );
  }

  Widget _buildUpcomingShiftCard(ShiftSchedule shift) {
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
      accentColor = const Color(0xFFFF5722); // Red-Orange for today
    } else if (daysUntil == 1) {
      daysText = 'Tomorrow';
      accentColor = const Color(0xFFFF9800); // Orange for tomorrow
    } else {
      daysText = 'in $daysUntil days';
      accentColor = const Color(0xFF673AB7); // Purple for later
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

  Widget _buildUpcomingLeaveCard(LeaveRequest leave) {
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
      accentColor = const Color(0xFF4CAF50); // Green for leave
    } else if (daysUntil == 1) {
      daysText = 'Tomorrow';
      accentColor = const Color(0xFF66BB6A); // Light green
    } else {
      daysText = 'in $daysUntil days';
      accentColor = const Color(0xFF2E7D32); // Dark green
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

  Widget _buildShiftsList() {
    if (_selectedDay == null) {
      return const Center(child: Text('Select a day to view schedule'));
    }

    final shifts = _getShiftsForDay(_selectedDay!);
    final leaves = _getLeavesForDay(_selectedDay!);

    if (shifts.isEmpty && leaves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.event_busy, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No shifts or leaves scheduled for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (shifts.isNotEmpty) ...[
          Text(
            'Shifts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF673AB7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...shifts.map((shift) => _buildShiftCard(shift)),
        ],
        if (leaves.isNotEmpty) ...[
          if (shifts.isNotEmpty) const SizedBox(height: 12),
          Text(
            'Leaves',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF4CAF50),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...leaves.map((leave) => _buildLeaveCard(leave)),
        ],
      ],
    );
  }

  Widget _buildShiftCard(ShiftSchedule shift) {
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

  Widget _buildLeaveCard(LeaveRequest leave) {
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

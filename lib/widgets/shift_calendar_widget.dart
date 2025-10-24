import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/shift_schedule.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadShifts();
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
        final dateOnly = DateTime(shift.date.year, shift.date.month, shift.date.day);
        
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

  List<ShiftSchedule> _getShiftsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _shifts[dateOnly] ?? [];
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
                  'My Shift Schedule',
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
                children: [
                  TableCalendar<ShiftSchedule>(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    eventLoader: _getShiftsForDay,
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 1,
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

  Widget _buildShiftsList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Select a day to view shifts'),
      );
    }

    final shifts = _getShiftsForDay(_selectedDay!);
    
    if (shifts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'No shifts scheduled for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
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
          'Shifts on ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...shifts.map((shift) => _buildShiftCard(shift)),
      ],
    );
  }

  Widget _buildShiftCard(ShiftSchedule shift) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF673AB7).withOpacity(0.1),
          child: const Icon(
            Icons.work_outline,
            color: Color(0xFF673AB7),
          ),
        ),
        title: Text(
          shift.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Created: ${DateFormat('MMM d, yyyy').format(shift.createdAt)}',
          style: const TextStyle(fontSize: 12),
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

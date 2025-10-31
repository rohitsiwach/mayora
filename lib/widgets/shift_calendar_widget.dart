import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'schedule/upcoming_shift_card.dart';
import 'schedule/upcoming_leave_card.dart';
import 'schedule/shift_list_item.dart';
import 'schedule/leave_list_item.dart';
import '../models/shift_schedule.dart';
import '../models/leave_request.dart';
import '../services/auth_service.dart';
import '../services/hierarchical_firestore_service.dart';

class ShiftCalendarWidget extends StatefulWidget {
  const ShiftCalendarWidget({super.key});

  @override
  State<ShiftCalendarWidget> createState() => _ShiftCalendarWidgetState();
}

class _ShiftCalendarWidgetState extends State<ShiftCalendarWidget>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _hierarchical = HierarchicalFirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ShiftSchedule>> _shifts = {};
  Map<DateTime, List<LeaveRequest>> _leaves = {};
  bool _loading = true;
  late TabController _tabController;
  String? _selectedColleagueId;
  String? _selectedColleagueName;
  List<Map<String, dynamic>> _colleagues = [];
  bool _colleaguesLoading = false;
  String? _organizationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _loadShifts();
    _loadLeaves();
    _loadColleagues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadColleagues() async {
    setState(() => _colleaguesLoading = true);
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() => _colleaguesLoading = false);
      return;
    }

    try {
      // Get organization ID from lightweight lookup doc
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final orgId = userDoc.data()?['organizationId'] as String?;

      if (orgId == null) {
        setState(() => _colleaguesLoading = false);
        return;
      }

      _organizationId = orgId;

      // Query users from hierarchical structure
      final snapshot = await _hierarchical.usersCollection(orgId).get();

      final colleagues = snapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {'id': doc.id, 'name': data['name'] ?? 'Unnamed User'};
          })
          .toList();

      // Sort colleagues alphabetically by name
      colleagues.sort(
        (a, b) => (a['name'] as String).toLowerCase().compareTo(
          (b['name'] as String).toLowerCase(),
        ),
      );

      setState(() {
        _colleagues = colleagues;
        _colleaguesLoading = false;
      });
    } catch (e) {
      print('[ShiftCalendarWidget] Error loading colleagues: $e');
      setState(() => _colleaguesLoading = false);
    }
  }

  Future<void> _loadShifts() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Ensure we have organization ID
      if (_organizationId == null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        _organizationId = userDoc.data()?['organizationId'] as String?;
      }

      if (_organizationId == null) {
        setState(() => _loading = false);
        return;
      }

      // Load shifts for the current month and adjacent months
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final snapshot = await _hierarchical
          .schedulesCollection(_organizationId!, currentUser.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<DateTime, List<ShiftSchedule>> shifts = {};
      for (final doc in snapshot.docs) {
        final shift = ShiftSchedule.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
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
      // Ensure we have organization ID
      if (_organizationId == null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        _organizationId = userDoc.data()?['organizationId'] as String?;
      }

      if (_organizationId == null) return;

      // Load approved leaves for the current month and adjacent months
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final snapshot = await _hierarchical
          .leavesCollection(_organizationId!, currentUser.uid)
          .where('status', isEqualTo: 'approved')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<DateTime, List<LeaveRequest>> leaves = {};
      for (final doc in snapshot.docs) {
        final leave = LeaveRequest.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

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
      child: SizedBox(
        height: 800, // Fixed height for the card
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
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF673AB7),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF673AB7),
                tabs: const [
                  Tab(text: 'My Schedule'),
                  Tab(text: 'Colleagues'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildMyScheduleTab(), _buildColleaguesTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyScheduleTab() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TableCalendar<dynamic>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
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
    );
  }

  Widget _buildColleaguesTab() {
    if (_colleaguesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_colleagues.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No colleagues found in your organization'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a colleague to view their schedule:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedColleagueId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Choose a colleague'),
          items: _colleagues
              .map(
                (colleague) => DropdownMenuItem<String>(
                  value: colleague['id'],
                  child: Text(colleague['name']),
                ),
              )
              .toList(),
          onChanged: (id) {
            setState(() {
              _selectedColleagueId = id;
              _selectedColleagueName = _colleagues.firstWhere(
                (c) => c['id'] == id,
              )['name'];
            });
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _selectedColleagueId != null
              ? ColleagueScheduleView(
                  userId: _selectedColleagueId!,
                  colleagueName: _selectedColleagueName ?? 'Colleague',
                  organizationId: _organizationId,
                )
              : TodayColleaguesScheduleView(
                  colleagues: _colleagues,
                  organizationId: _organizationId,
                ),
        ),
      ],
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
          ...upcomingShifts.map((shift) => UpcomingShiftCard(shift: shift)),
          ...upcomingLeaves.map((leave) => UpcomingLeaveCard(leave: leave)),
        ],
      ],
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
          ...shifts.map((shift) => ShiftListItem(shift: shift)),
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
          ...leaves.map((leave) => LeaveListItem(leave: leave)),
        ],
      ],
    );
  }
}

// Colleague Schedule View Widget
class ColleagueScheduleView extends StatefulWidget {
  final String userId;
  final String colleagueName;
  final String? organizationId;

  const ColleagueScheduleView({
    required this.userId,
    required this.colleagueName,
    this.organizationId,
    super.key,
  });

  @override
  State<ColleagueScheduleView> createState() => _ColleagueScheduleViewState();
}

class _ColleagueScheduleViewState extends State<ColleagueScheduleView> {
  final _hierarchical = HierarchicalFirestoreService();
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
    try {
      if (widget.organizationId == null) {
        setState(() => _loading = false);
        return;
      }

      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final snapshot = await _hierarchical
          .schedulesCollection(widget.organizationId!, widget.userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<DateTime, List<ShiftSchedule>> shifts = {};
      for (final doc in snapshot.docs) {
        final shift = ShiftSchedule.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
        final dateOnly = DateTime(
          shift.date.year,
          shift.date.month,
          shift.date.day,
        );
        shifts.putIfAbsent(dateOnly, () => []).add(shift);
      }

      setState(() {
        _shifts = shifts;
        _loading = false;
      });
    } catch (e) {
      print('[ColleagueScheduleView] Error loading shifts: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLeaves() async {
    try {
      if (widget.organizationId == null) return;

      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final snapshot = await _hierarchical
          .leavesCollection(widget.organizationId!, widget.userId)
          .where('status', isEqualTo: 'approved')
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<DateTime, List<LeaveRequest>> leaves = {};
      for (final doc in snapshot.docs) {
        final leave = LeaveRequest.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        if (leave.endDate.isAfter(startDate) ||
            leave.endDate.isAtSameMomentAs(startDate)) {
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
              leaves.putIfAbsent(dateOnly, () => []).add(leave);
            }
            currentDate = currentDate.add(const Duration(days: 1));
          }
        }
      }

      setState(() {
        _leaves = leaves;
      });
    } catch (e) {
      print('[ColleagueScheduleView] Error loading leaves: $e');
    }
  }

  List<ShiftSchedule> _getShiftsForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _shifts[dateOnly] ?? [];
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.colleagueName}\'s Schedule',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TableCalendar<dynamic>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF2196F3),
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
              _loadShifts();
              _loadLeaves();
            },
          ),
          const SizedBox(height: 16),
          _buildShiftsList(),
        ],
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
              color: const Color(0xFF2196F3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...shifts.map((shift) => ShiftListItem(shift: shift)),
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
          ...leaves.map((leave) => LeaveListItem(leave: leave)),
        ],
      ],
    );
  }
}

// Today's Colleagues Schedule View Widget
class TodayColleaguesScheduleView extends StatefulWidget {
  final List<Map<String, dynamic>> colleagues;
  final String? organizationId;

  const TodayColleaguesScheduleView({
    required this.colleagues,
    this.organizationId,
    super.key,
  });

  @override
  State<TodayColleaguesScheduleView> createState() =>
      _TodayColleaguesScheduleViewState();
}

class _TodayColleaguesScheduleViewState
    extends State<TodayColleaguesScheduleView> {
  final _hierarchical = HierarchicalFirestoreService();
  Map<String, List<ShiftSchedule>> _todayShifts = {};
  Map<String, List<LeaveRequest>> _todayLeaves = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodaySchedules();
  }

  Future<void> _loadTodaySchedules() async {
    if (widget.organizationId == null) {
      setState(() => _loading = false);
      return;
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    try {
      Map<String, List<ShiftSchedule>> shifts = {};
      Map<String, List<LeaveRequest>> leaves = {};

      for (final colleague in widget.colleagues) {
        final userId = colleague['id'] as String;

        final shiftsSnapshot = await _hierarchical
            .schedulesCollection(widget.organizationId!, userId)
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
            .get();

        if (shiftsSnapshot.docs.isNotEmpty) {
          shifts[userId] = shiftsSnapshot.docs
              .map(
                (doc) => ShiftSchedule.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        }

        final leavesSnapshot = await _hierarchical
            .leavesCollection(widget.organizationId!, userId)
            .where('status', isEqualTo: 'approved')
            .where(
              'startDate',
              isLessThanOrEqualTo: Timestamp.fromDate(todayEnd),
            )
            .where(
              'endDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
            )
            .get();

        if (leavesSnapshot.docs.isNotEmpty) {
          leaves[userId] = leavesSnapshot.docs
              .map(
                (doc) => LeaveRequest.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        }
      }

      setState(() {
        _todayShifts = shifts;
        _todayLeaves = leaves;
        _loading = false;
      });
    } catch (e) {
      print('[TodayColleaguesScheduleView] Error loading schedules: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final today = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(today);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF673AB7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.today, color: Color(0xFF673AB7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today'
                    's Schedule - $formattedDate',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF673AB7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_todayShifts.isEmpty && _todayLeaves.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No schedules or leaves for any colleague today',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...widget.colleagues.map((colleague) {
              final userId = colleague['id'] as String;
              final name = colleague['name'] as String;
              final shifts = _todayShifts[userId] ?? [];
              final leaves = _todayLeaves[userId] ?? [];

              if (shifts.isEmpty && leaves.isEmpty) {
                return const SizedBox.shrink();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF673AB7),
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      if (shifts.isNotEmpty) ...[
                        Text(
                          'Shifts',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        ...shifts.map((shift) => ShiftListItem(shift: shift)),
                      ],
                      if (leaves.isNotEmpty) ...[
                        if (shifts.isNotEmpty) const SizedBox(height: 12),
                        Text(
                          'Leaves',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        ...leaves.map((leave) => LeaveListItem(leave: leave)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

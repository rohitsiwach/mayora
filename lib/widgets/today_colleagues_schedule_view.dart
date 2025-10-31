import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'schedule/shift_list_item.dart';
import 'schedule/leave_list_item.dart';
import '../models/shift_schedule.dart';
import '../models/leave_request.dart';
import '../services/hierarchical_firestore_service.dart';

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
                    'Today\'s Schedule - $formattedDate',
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

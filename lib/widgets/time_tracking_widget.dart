import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/time_tracking_service.dart';
import '../services/firestore_service.dart';

class TimeTrackingWidget extends StatefulWidget {
  const TimeTrackingWidget({super.key});

  @override
  State<TimeTrackingWidget> createState() => _TimeTrackingWidgetState();
}

class _TimeTrackingWidgetState extends State<TimeTrackingWidget>
    with WidgetsBindingObserver {
  final TimeTrackingController _controller = TimeTrackingController();
  final FirestoreService _fs = FirestoreService();

  String? _selectedProjectId;
  String? _selectedProjectName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist when going inactive/paused; controller handles recovery on init
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // best-effort: controller persists every tick already
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (!_controller.isClockedIn) return _buildInitialState();
        if (_controller.isOnBreak) return _buildOnBreakState();
        return _buildWorkingState();
      },
    );
  }

  // ================= UI STATES =================

  Widget _buildInitialState() {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Time Tracking',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          _projectDropdown(enabled: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_selectedProjectId == null)
                ? null
                : () async {
                    await _controller.clockIn(
                      projectId: _selectedProjectId!,
                      projectName: _selectedProjectName ?? 'Project',
                    );
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFF2962FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('CLOCK IN'),
          ),
          const SizedBox(height: 16),
          _metricsRow(),
        ],
      ),
    );
  }

  Widget _buildWorkingState() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _projectDropdown(enabled: true, showSelectedLabel: true),
          const SizedBox(height: 8),
          Text(
            'TIME ON PROJECTS (CURRENT SHIFT)',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _projectBreakdownList(),
          const SizedBox(height: 8),
          _metricsRow(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _controller.startBreak(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF5E5CE6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('BREAK'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _showEndShiftConfirmation,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFFFF5E57),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('END SHIFT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnBreakState() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _projectDropdown(enabled: true, showSelectedLabel: true),
          const SizedBox(height: 8),
          Text(
            'TIME ON PROJECTS (CURRENT SHIFT)',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _projectBreakdownList(),
          const SizedBox(height: 8),
          _metricsRow(onBreak: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _controller.resumeFromBreak(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('RESUME'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _showEndShiftConfirmation,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFFFF5E57),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('END SHIFT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============== UI helpers ===============

  Widget _projectDropdown({
    bool enabled = true,
    bool showSelectedLabel = false,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.getProjects(),
      builder: (context, snapshot) {
        final items = <DropdownMenuItem<String>>[];
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? data['projectName'] ?? 'Project';
            items.add(DropdownMenuItem(value: doc.id, child: Text(name)));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _controller.isClockedIn
                  ? _controller.activeProjectId
                  : _selectedProjectId,
              items: items,
              onChanged: !enabled
                  ? null
                  : (val) {
                      if (_controller.isClockedIn) {
                        final name =
                            items.firstWhere((e) => e.value == val).child
                                is Text
                            ? ((items.firstWhere((e) => e.value == val).child
                                          as Text)
                                      .data ??
                                  'Project')
                            : 'Project';
                        _controller.switchProject(
                          projectId: val!,
                          projectName: name,
                        );
                      } else {
                        setState(() {
                          _selectedProjectId = val;
                          final name =
                              items.firstWhere((e) => e.value == val).child
                                  as Text;
                          _selectedProjectName = name.data ?? 'Project';
                        });
                      }
                    },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Project',
              ),
            ),
            if (showSelectedLabel && _controller.activeProjectName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Project: ${_controller.activeProjectName!}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _metricsRow({bool onBreak = false}) {
    final totalAtWork = TimeTrackingController.formatHms(
      _controller.totalAtWork,
    );
    final actualWorking = TimeTrackingController.formatHms(
      _controller.actualWorking,
    );
    final totalBreak = TimeTrackingController.formatHms(_controller.totalBreak);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _metricCircle(title: 'TOTAL AT WORK', value: totalAtWork),
        _metricCircle(
          title: onBreak ? 'ON BREAK' : 'ACTUAL WORKING TIME',
          value: actualWorking,
          highlight: !onBreak,
        ),
        _metricCircle(title: 'TOTAL BREAK', value: totalBreak),
      ],
    );
  }

  Widget _metricCircle({
    required String title,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: highlight
                ? const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade200, Colors.grey.shade300],
                  ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 120,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _projectBreakdownList() {
    final snapshot = _controller.projectDurationsSnapshot();
    print('[Widget] _projectBreakdownList called, snapshot: $snapshot');
    if (snapshot.isEmpty) {
      return Text(
        'No project time yet',
        style: TextStyle(color: Colors.grey[600]),
      );
    }
    final entries = snapshot.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${_controller.projectNames[e.key] ?? e.key}: ' +
                  TimeTrackingController.formatHms(
                    Duration(milliseconds: e.value),
                  ),
            ),
          ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Future<void> _showEndShiftConfirmation() async {
    // Build a preview snapshot
    final preview = _controller.previewShiftRecord();
    if (preview == null) {
      // Fallback: if not clocked in
      return;
    }

    String fmtMs(int ms) =>
        TimeTrackingController.formatHms(Duration(milliseconds: ms));
    final clockIn = DateTime.tryParse(preview['clockInTime'] ?? '')?.toLocal();
    final clockOut = DateTime.tryParse(
      preview['clockOutTime'] ?? '',
    )?.toLocal();
    final df = DateFormat('yyyy-MM-dd HH:mm:ss');

    final totalMs = preview['totalHoursAtWorkMs'] as int? ?? 0;
    final actualMs = preview['actualWorkingHoursMs'] as int? ?? 0;
    final breakMs = preview['totalBreakTimeMs'] as int? ?? 0;
    final adjusted = preview['shiftAdjustmentsMade'] == true;
    final breakdown =
        (preview['projectBreakdown'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Shift Summary'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (clockIn != null) Text('Clock In:  ${df.format(clockIn)}'),
                if (clockOut != null) Text('Clock Out: ${df.format(clockOut)}'),
                const SizedBox(height: 8),
                Text('Total at work:     ${fmtMs(totalMs)}'),
                Text('Total break:       ${fmtMs(breakMs)}'),
                Text('Actual working:    ${fmtMs(actualMs)}'),
                if (adjusted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text('Minimum break adjustment applied.'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Project breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 6),
                if (breakdown.isEmpty)
                  Text(
                    'No project time recorded',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in breakdown)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${e['projectName'] ?? e['projectId']}: ${fmtMs((e['durationMs'] ?? 0) as int)}',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _controller.endShift();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E57),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & End Shift'),
            ),
          ],
        );
      },
    );
  }
}

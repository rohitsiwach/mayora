import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isRecurring = false;
  final Set<int> _selectedDays = {}; // 1=Mon, 7=Sun

  final _auth = AuthService();
  final _fs = FirestoreService();
  final _scheduler = ScheduleService();

  String? _organizationId;
  String _targetMode = 'single'; // single | group | multiple
  String? _selectedUserId;
  String? _selectedGroupId;
  final Set<String> _selectedUserIds = {};

  bool _loading = true;
  String? _error;

  // Progress
  final List<String> _progress = [];
  int _completed = 0;
  int _total = 0;
  Stream<SchedulingProgress>? _progressStream;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _fs.ensureCanonicalUserDocument();
      _organizationId = await _fs.getCurrentUserOrganizationId();
      if (_organizationId == null) {
        _error = 'Organization not found for your account.';
      }
    } catch (e) {
      _error = 'Failed to load: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
        backgroundColor: const Color(0xFF2962FF),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error ?? 'Error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _loading = true);
                _init();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildForm(),
          const SizedBox(height: 16),
          _buildProgress(),
          const SizedBox(height: 8),
          SizedBox(
            height: 400,
            child: _buildRecentSchedules(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF2962FF)),
                  const SizedBox(width: 8),
                  Text('Create New Shift', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Employee', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _targetMode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'single', child: Text('Individual')),
                            DropdownMenuItem(value: 'group', child: Text('Employee Group')),
                            DropdownMenuItem(value: 'multiple', child: Text('Multiple Users')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _targetMode = v ?? 'single';
                              _selectedUserId = null;
                              _selectedGroupId = null;
                              _selectedUserIds.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 58,
                          child: _buildTargetSelector(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _buildTimePicker(true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _buildTimePicker(false),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Shift Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Recurring Shift', style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v ?? false),
                  ),
                ],
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                const Text('Create this shift on multiple days', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                const Text('Select Days:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildDaySelector(),
                const SizedBox(height: 12),
                const Text('End Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildEndDateDisplay(),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _titleController.clear();
                        setState(() {
                          _startDate = null;
                          _isRecurring = false;
                          _selectedDays.clear();
                          _selectedUserId = null;
                          _selectedUserIds.clear();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _organizationId == null ? null : _startScheduling,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Create Shift'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(bool isStart) {
    final time = isStart ? _startTime : _endTime;
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startTime = picked;
            } else {
              _endTime = picked;
            }
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(time.format(context)),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = [
      {'label': 'Mon', 'value': 1},
      {'label': 'Tue', 'value': 2},
      {'label': 'Wed', 'value': 3},
      {'label': 'Thu', 'value': 4},
      {'label': 'Fri', 'value': 5},
      {'label': 'Sat', 'value': 6},
      {'label': 'Sun', 'value': 7},
    ];
    return Wrap(
      spacing: 8,
      children: days.map((day) {
        final value = day['value'] as int;
        final selected = _selectedDays.contains(value);
        return FilterChip(
          label: Text(day['label'] as String),
          selected: selected,
          onSelected: (s) {
            setState(() {
              if (s) {
                _selectedDays.add(value);
              } else {
                _selectedDays.remove(value);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildEndDateDisplay() {
    final now = DateTime.now();
    final endDate = DateTime(now.year, 12, 31);
    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_month),
      ),
      child: Text(
        '${_getDayName(endDate.weekday)}, ${_getMonthName(endDate.month)} ${endDate.day}, ${endDate.year}',
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }


  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _startDate ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: DateTime(now.year, 12, 31),
        );
        if (picked != null) setState(() => _startDate = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_month),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(
          _startDate == null
              ? 'Pick a date'
              : '${_getDayName(_startDate!.weekday)}, ${_getMonthName(_startDate!.month)} ${_startDate!.day}, ${_startDate!.year}',
        ),
      ),
    );
  }

  Widget _buildTargetSelector() {
    if (_organizationId == null) {
      return const SizedBox();
    }
    if (_targetMode == 'single') {
      return _buildUsersDropdown(single: true);
    } else if (_targetMode == 'group') {
      return _buildGroupsDropdown();
    } else {
      return _buildUsersMultiSelect();
    }
  }

  Widget _buildUsersDropdown({bool single = false}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('organizationId', isEqualTo: _organizationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const InputDecorator(
            decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Users'),
            child: Text('Loading...'),
          );
        }
        final docs = snapshot.data!.docs;
        // Deduplicate by userId to avoid duplicate Dropdown values (canonical + legacy doc)
        final Map<String, String> userMap = {};
        for (final d in docs) {
          final data = d.data();
          final uid = (data['userId'] ?? d.id).toString();
          final name = (data['name'] ?? data['email'] ?? uid).toString();
          // Keep first occurrence; prefer non-empty name if duplicate encountered
          if (!userMap.containsKey(uid) || (userMap[uid] == uid && name != uid)) {
            userMap[uid] = name;
          }
        }
        // Sort for stability and build a key to reset field when options change
        final entries = userMap.entries.toList()
          ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
        final items = entries
            .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
            .toList();
        final dropdownKey = ValueKey<String>('users_${entries.map((e) => e.key).join('|')}');
        final String? safeValue = userMap.containsKey(_selectedUserId) ? _selectedUserId : null;
        return DropdownButtonFormField<String>(
          key: dropdownKey,
          value: safeValue,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'User *', border: OutlineInputBorder()),
          items: items,
          onChanged: (v) => setState(() => _selectedUserId = v),
          validator: (v) => (v == null || v.isEmpty) ? 'Select a user' : null,
        );
      },
    );
  }

  Widget _buildGroupsDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_groups')
          .where('organizationId', isEqualTo: _organizationId)
          .snapshots(),
      builder: (context, snapshot) {
        final items = <DropdownMenuItem<String>>[];
        if (snapshot.hasData) {
          items.addAll(snapshot.data!.docs.map((d) {
            final data = d.data();
            return DropdownMenuItem<String>(
              value: d.id,
              child: Text(data['name'] ?? 'Group ${d.id.substring(0, 6)}'),
            );
          }));
        }
        final groupKey = ValueKey<String>('groups_${items.map((e) => e.value).join('|')}');
        final safeGroupValue = items.any((i) => i.value == _selectedGroupId) ? _selectedGroupId : null;
        return DropdownButtonFormField<String>(
          key: groupKey,
          value: safeGroupValue,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Group *', border: OutlineInputBorder()),
          items: items,
          onChanged: (v) => setState(() => _selectedGroupId = v),
          validator: (v) => (v == null || v.isEmpty) ? 'Select a group' : null,
        );
      },
    );
  }

  Widget _buildUsersMultiSelect() {
    return OutlinedButton(
      onPressed: _pickUsers,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        alignment: Alignment.centerLeft,
      ),
      child: Text(
        _selectedUserIds.isEmpty
            ? 'Select users'
            : '${_selectedUserIds.length} user(s) selected',
      ),
    );
  }

  Future<void> _pickUsers() async {
    // Use a temp set to collect selection within the dialog
    final tempSelected = Set<String>.from(_selectedUserIds);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select users'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('organizationId', isEqualTo: _organizationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                // Deduplicate by userId
                final Map<String, String> userMap = {};
                for (final d in docs) {
                  final data = d.data();
                  final uid = (data['userId'] ?? d.id).toString();
                  final name = (data['name'] ?? data['email'] ?? uid).toString();
                  if (!userMap.containsKey(uid) || (userMap[uid] == uid && name != uid)) {
                    userMap[uid] = name;
                  }
                }
                return StatefulBuilder(builder: (context, setStateDialog) {
                  // Keep tempSelected in sync and ensure only valid userIds remain
                  tempSelected.removeWhere((id) => !userMap.containsKey(id));
                  final entries = userMap.entries.toList();
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final uid = e.key;
                      final name = e.value;
                      final selected = tempSelected.contains(uid);
                      return CheckboxListTile(
                        value: selected,
                        title: Text(name),
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v == true) {
                              tempSelected.add(uid);
                            } else {
                              tempSelected.remove(uid);
                            }
                          });
                        },
                      );
                    },
                  );
                });
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, tempSelected), child: const Text('Done')),
          ],
        );
      },
    );
    if (result != null) setState(() => _selectedUserIds
      ..clear()
      ..addAll(result));
  }

  Widget _buildProgress() {
    if (_progressStream == null && _progress.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Scheduling Progress (${_completed}/$_total)')
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _total == 0 ? null : (_completed / _total).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: _progress.length,
                itemBuilder: (context, index) => Text(_progress[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScheduling() async {
    if (!_formKey.currentState!.validate()) return;
    if (_organizationId == null || _startDate == null) return;

    final title = _titleController.text.trim();
    List<String> users = <String>[];
    if (_targetMode == 'single') {
      if (_selectedUserId == null) return;
      users = [_selectedUserId!];
    } else if (_targetMode == 'group') {
      if (_selectedGroupId == null) return;
      // Load group members (userIds array)
      final groupDoc = await FirebaseFirestore.instance.collection('user_groups').doc(_selectedGroupId).get();
      final data = groupDoc.data() ?? {};
      final List<dynamic> members = data['userIds'] ?? [];
      users = members.map((e) => e.toString()).toList();
    } else {
      users = _selectedUserIds.toList();
    }

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one user')));
      return;
    }

    // Determine recurrence based on UI state
    Recurrence recurrence;
    if (!_isRecurring) {
      recurrence = Recurrence.none;
    } else if (_selectedDays.isNotEmpty) {
      recurrence = Recurrence.weekly; // Custom days = weekly pattern
    } else {
      recurrence = Recurrence.daily; // No specific days = daily
    }

    _progress.clear();
    setState(() {
      _completed = 0;
      _total = 0; // will be set when stream yields first event
    });

    final createdBy = _auth.currentUser?.uid ?? 'system';
    final stream = _scheduler.createSchedulesBatch(
      organizationId: _organizationId!,
      createdBy: createdBy,
      title: title,
      userIds: users,
      startDate: _startDate!,
      recurrence: recurrence,
      selectedDays: _selectedDays.isEmpty ? null : _selectedDays,
    );

    setState(() => _progressStream = stream);

    stream.listen((evt) {
      setState(() {
        _completed = evt.completed;
        _total = evt.total;
        _progress.insert(0, evt.message);
      });
    }, onError: (e) {
      setState(() {
        _progress.insert(0, 'Fatal error: $e');
      });
    }, onDone: () {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scheduling completed')));
    });
  }

  Widget _buildRecentSchedules() {
    if (_organizationId == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .doc(_organizationId)
          .collection('schedules')
          .orderBy('date', descending: true)
          .limit(25)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No schedules yet'));
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final date = (data['date'] as Timestamp?)?.toDate();
            final userId = data['userId'] ?? '';
            final title = data['title'] ?? '';
            return ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(title),
              subtitle: Text('User: $userId  |  Date: ${date != null ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}' : '-'}'),
            );
          },
        );
      },
    );
  }
}

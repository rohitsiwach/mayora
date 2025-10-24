import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _userId;
  String? _organizationId;
  int _totalAnnualLeaves = 30; // Default, can be customized per user
  int _leavesTaken = 0;
  int _remainingLeaves = 0;
  bool _loading = true;
  String? _errorMessage;
  DateTime? _joinDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        // Not signed in; show friendly message instead of spinning forever
        setState(() {
          _errorMessage = 'You need to sign in to view and request leaves.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _userId = user.uid;
      });

      // Fetch required data; failures should not block the whole page
      _organizationId = await _firestoreService.getCurrentUserOrganizationId();
      _joinDate = await _firestoreService.getUserJoinDate(_userId!);
      _totalAnnualLeaves =
          await _firestoreService.getUserAnnualLeave(_userId!) ?? 30;
      _leavesTaken = await _leaveService.getUserAnnualLeavesTaken(_userId!);
      _remainingLeaves = _calculateRemainingLeaves();
    } catch (e) {
      // Capture error but still unblock UI
      _errorMessage = 'Failed to load leave data. ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int _calculateRemainingLeaves() {
    final now = DateTime.now();
    final yearEnd = DateTime(now.year, 12, 31);
    final joinDate = _joinDate ?? DateTime(now.year, 1, 1);
    final isMidYear =
        joinDate.year == now.year && joinDate.isAfter(DateTime(now.year, 1, 1));
    if (isMidYear) {
      final remainingDays = yearEnd.difference(joinDate).inDays + 1;
      final prorated = ((remainingDays / 365) * _totalAnnualLeaves).round();
      return prorated - _leavesTaken;
    } else {
      return _totalAnnualLeaves - _leavesTaken;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leaves'),
        backgroundColor: const Color(0xFF2962FF),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null)
          ? _buildErrorState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.beach_access,
                        color: Colors.blue,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Remaining leave for the year: $_remainingLeaves',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showLeaveApplicationDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Apply for Leave'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2962FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildLeaveHistoryList()),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _loading = true;
                });
                _loadUserData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveApplicationDialog() {
    final formKey = GlobalKey<FormState>();
    LeaveType? selectedLeaveType;
    DateTime? startDate;
    DateTime? endDate;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Apply for Leave',
              style: TextStyle(fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<LeaveType>(
                      value: selectedLeaveType,
                      decoration: InputDecoration(
                        labelText: 'Type of Leave *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: LeaveType.defaultTypes.map((leaveType) {
                        return DropdownMenuItem(
                          value: leaveType,
                          child: Text(leaveType.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLeaveType = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Select leave type' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                            if (endDate != null && endDate!.isBefore(picked)) {
                              endDate = picked;
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          startDate != null
                              ? DateFormat('dd/MM/yyyy').format(startDate!)
                              : 'Select start date',
                          style: TextStyle(
                            color: startDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: startDate == null
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate!,
                                firstDate: startDate!,
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setState(() {
                                  endDate = picked;
                                });
                              }
                            },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                          enabled: startDate != null,
                        ),
                        child: Text(
                          endDate != null
                              ? DateFormat('dd/MM/yyyy').format(endDate!)
                              : 'Select end date',
                          style: TextStyle(
                            color: endDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason *',
                        hintText: 'Explain your leave request...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a reason';
                        }
                        if (value.trim().length < 10) {
                          return 'Reason must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _submitLeaveRequest(
                  dialogContext,
                  formKey,
                  selectedLeaveType,
                  startDate,
                  endDate,
                  reasonController.text,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitLeaveRequest(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    LeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String reason,
  ) async {
    if (!formKey.currentState!.validate()) return;
    if (leaveType == null || startDate == null || endDate == null) return;
    if (_userId == null || _organizationId == null) return;
    try {
      final numberOfDays = endDate.difference(startDate).inDays + 1;
      final user = _authService.currentUser;
      final request = LeaveRequest(
        userId: _userId!,
        userName: user?.displayName ?? user?.email ?? 'Unknown',
        organizationId: _organizationId!,
        leaveTypeId: leaveType.id,
        leaveTypeName: leaveType.name,
        startDate: startDate,
        endDate: endDate,
        numberOfDays: numberOfDays,
        reason: reason.trim(),
        createdAt: DateTime.now(),
      );
      await _leaveService.submitUserLeaveRequest(_userId!, request);
      if (context.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLeaveHistoryList() {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<List<LeaveRequest>>(
      stream: _leaveService.getUserLeavesStream(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading requests: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No leave requests yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Apply for Leave" to create one',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(LeaveRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  request.leaveTypeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: request.statusColor),
                  ),
                  child: Text(
                    request.statusDisplay,
                    style: TextStyle(
                      color: request.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(request.startDate)} - ${DateFormat('dd/MM/yyyy').format(request.endDate)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.reason,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            if (request.reviewComments != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Comments:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.reviewComments!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Submitted on ${DateFormat('dd/MM/yyyy').format(request.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _organizationId;
  String? _accessLevel;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizationData();
  }

  Future<void> _loadOrganizationData() async {
    try {
      // Ensure canonical user document exists and is populated
      await _firestoreService.ensureCanonicalUserDocument();
      _organizationId = await _firestoreService.getCurrentUserOrganizationId();
      _accessLevel = await _firestoreService.getCurrentUserAccessLevel();
      if (_accessLevel == null || !['Admin', 'Manager'].contains(_accessLevel)) {
        _errorMessage = 'You don\'t have permission to view organization requests.';
      } else if (_organizationId == null) {
        _errorMessage = 'Organization information is missing for your profile.';
      }
    } catch (e) {
      _errorMessage = 'Failed to load requests: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: const Color(0xFF2962FF),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _loading = true);
                            _loadOrganizationData();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                )
              : _buildRequestsList(),
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<List<LeaveRequest>>(
      stream: _leaveService.getOrganizationLeaveRequests(_organizationId!),
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
                  'No leave requests found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Group requests by status
        final pendingRequests = requests.where((r) => r.status == 'pending').toList();
        final reviewedRequests = requests.where((r) => r.status != 'pending').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pendingRequests.isNotEmpty) ...[
              _buildSectionHeader('Pending Approval', pendingRequests.length, Colors.orange),
              ...pendingRequests.map((request) => _buildRequestCard(request, isPending: true)),
              const SizedBox(height: 16),
            ],
            if (reviewedRequests.isNotEmpty) ...[
              _buildSectionHeader('Reviewed Requests', reviewedRequests.length, Colors.grey),
              ...reviewedRequests.map((request) => _buildRequestCard(request, isPending: false)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(LeaveRequest request, {required bool isPending}) {
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
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    request.userName.isNotEmpty ? request.userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.leaveTypeName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${request.numberOfDays} ${request.numberOfDays == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
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
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(request, false),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(request, true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
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

  void _showReviewDialog(LeaveRequest request, bool approve) {
    final commentsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve Leave Request' : 'Reject Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${request.userName}'),
            Text('Leave Type: ${request.leaveTypeName}'),
            Text('Duration: ${request.numberOfDays} days'),
            Text('Dates: ${DateFormat('dd/MM/yyyy').format(request.startDate)} - ${DateFormat('dd/MM/yyyy').format(request.endDate)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: 'Comments (Optional)',
                hintText: approve ? 'Approval notes...' : 'Reason for rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitReview(
              dialogContext,
              request,
              approve,
              commentsController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext dialogContext,
    LeaveRequest request,
    bool approve,
    String comments,
  ) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      await _leaveService.updateLeaveStatus(
        userId: request.userId,
        requestId: request.id!,
        status: approve ? 'approved' : 'rejected',
        reviewedBy: currentUser.uid,
        comments: comments.trim().isNotEmpty ? comments.trim() : null,
      );

      if (context.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave request ${approve ? 'approved' : 'rejected'} successfully'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
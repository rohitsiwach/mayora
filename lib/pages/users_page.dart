import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.mail_outline), text: 'Invitations'),
            Tab(icon: Icon(Icons.group), text: 'User Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildInvitationsTab(),
          _buildUserGroupsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteUserDialog(context),
        backgroundColor: const Color(0xFF673AB7),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Invite User', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getRegisteredUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading users', snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF673AB7)),
          );
        }

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outlined,
            title: 'No registered users yet',
            subtitle: 'Users will appear here once they accept invitations',
          );
        }

        return _buildUsersList(users, isInvitation: false);
      },
    );
  }

  Widget _buildInvitationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getUserInvitations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading invitations', snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF673AB7)),
          );
        }

        final invitations = snapshot.data?.docs ?? [];

        if (invitations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mail_outline,
            title: 'No pending invitations',
            subtitle: 'Tap the + button to invite team members',
          );
        }

        return _buildUsersList(invitations, isInvitation: true);
      },
    );
  }

  Widget _buildUserGroupsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getUserGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading user groups', snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF673AB7)),
          );
        }

        final groups = snapshot.data?.docs ?? [];

        return Column(
          children: [
            Expanded(
              child: groups.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.group_outlined,
                      title: 'No user groups yet',
                      subtitle: 'Create groups to organize your team members',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final groupData = group.data() as Map<String, dynamic>;
                        final groupName = groupData['name'] ?? 'Unnamed Group';
                        final description = groupData['description'] ?? '';
                        final members = List<String>.from(
                          groupData['members'] ?? [],
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF673AB7,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.group,
                                color: Color(0xFF673AB7),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              groupName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'view') {
                                  _showGroupDetailsDialog(group.id, groupData);
                                } else if (value == 'edit') {
                                  _showEditGroupDialog(group.id, groupData);
                                } else if (value == 'delete') {
                                  _confirmDeleteGroup(group.id, groupName);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, size: 20),
                                      SizedBox(width: 8),
                                      Text('View Details'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showGroupDetailsDialog(group.id, groupData),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateGroupDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Create New Group',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String title, Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(
    List<QueryDocumentSnapshot> users, {
    required bool isInvitation,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final doc = users[index];
        final user = doc.data() as Map<String, dynamic>;
        final userId = doc.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF673AB7),
              child: Text(
                (user['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user['name'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'] ?? ''),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChip(
                      user['accessLevel'] ?? 'Employee',
                      _getAccessLevelColor(user['accessLevel']),
                    ),
                    const SizedBox(width: 8),
                    if (!isInvitation)
                      _buildChip('Active', Colors.green)
                    else
                      _buildChip('Pending', Colors.orange),
                  ],
                ),
                if (user['department'] != null && user['department'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${user['department']} - ${user['position'] ?? 'No position'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                if (isInvitation) ...[
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'resend',
                    child: Row(
                      children: [
                        Icon(Icons.send, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Resend', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ] else ...[
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Deactivate',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteUser(userId, user['name']);
                } else if (value == 'edit') {
                  _showEditUserDialog(context, userId, user);
                } else if (value == 'resend') {
                  _resendInvitation(userId, user['email']);
                } else if (value == 'deactivate') {
                  _deactivateUser(userId, user['name']);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getAccessLevelColor(String? accessLevel) {
    switch (accessLevel) {
      case 'Admin':
        return Colors.red;
      case 'Manager':
        return Colors.purple;
      case 'Manager Read Only':
        return Colors.blue;
      case 'Employee':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showInviteUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UserInvitationDialog(
        firestoreService: _firestoreService,
        onInvite: (userData) async {},
      ),
    );
  }

  void _showEditUserDialog(
    BuildContext context,
    String userId,
    Map<String, dynamic> userData,
  ) {
    showDialog(
      context: context,
      builder: (context) => UserInvitationDialog(
        firestoreService: _firestoreService,
        userId: userId,
        userData: userData,
        onInvite: (updatedData) async {},
      ),
    );
  }

  Future<void> _resendInvitation(String userId, String email) async {
    try {
      // For now, just show a message that this feature is not implemented
      // You can implement this method in FirestoreService later
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resend invitation feature will be implemented soon'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deactivateUser(String userId, String userName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Are you sure you want to deactivate "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _firestoreService.deactivateUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deactivated successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_firestoreService.getErrorMessage(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteUserInvitation(userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_firestoreService.getErrorMessage(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create User Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await _firestoreService.createUserGroup({
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
          'members': [],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User group created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
        }
      }
    }
  }

  Future<void> _showEditGroupDialog(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    final nameController = TextEditingController(text: groupData['name'] ?? '');
    final descriptionController = TextEditingController(
      text: groupData['description'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await _firestoreService.updateUserGroup(groupId, {
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User group updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating group: $e')));
        }
      }
    }
  }

  Future<void> _confirmDeleteGroup(String groupId, String groupName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Group'),
        content: Text(
          'Are you sure you want to delete "$groupName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _firestoreService.deleteUserGroup(groupId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User group deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting group: $e')));
        }
      }
    }
  }

  Future<void> _showGroupDetailsDialog(
    String groupId,
    Map<String, dynamic> groupData,
  ) async {
    final members = List<String>.from(groupData['members'] ?? []);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF673AB7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Color(0xFF673AB7),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupData['name'] ?? 'Unnamed Group',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((groupData['description'] ?? '').isNotEmpty)
                          Text(
                            groupData['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members (${members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddMembersDialog(groupId, members);
                    },
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Members'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: members.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No members yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add members to this group',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: _firestoreService.getRegisteredUsers(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final allUsers = snapshot.data!.docs;
                          final memberUsers = allUsers
                              .where((user) => members.contains(user.id))
                              .toList();

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: memberUsers.length,
                            itemBuilder: (context, index) {
                              final user = memberUsers[index];
                              final userData =
                                  user.data() as Map<String, dynamic>;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF673AB7),
                                  child: Text(
                                    (userData['name'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(userData['name'] ?? 'Unknown'),
                                subtitle: Text(userData['email'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await _firestoreService
                                          .removeUserFromGroup(
                                            groupId,
                                            user.id,
                                          );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Member removed from group',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error removing member: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddMembersDialog(
    String groupId,
    List<String> currentMembers,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Members',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Select users to add to this group:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getRegisteredUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allUsers = snapshot.data!.docs;
                    final availableUsers = allUsers
                        .where((user) => !currentMembers.contains(user.id))
                        .toList();

                    if (availableUsers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'All users are already in this group',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = availableUsers[index];
                        final userData = user.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF673AB7),
                            child: Text(
                              (userData['name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(userData['name'] ?? 'Unknown'),
                          subtitle: Text(userData['email'] ?? ''),
                          trailing: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _firestoreService.addUserToGroup(
                                  groupId,
                                  user.id,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Member added to group'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error adding member: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF673AB7),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserInvitationDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final String? userId;
  final Map<String, dynamic>? userData;
  final Function(Map<String, dynamic>) onInvite;

  const UserInvitationDialog({
    super.key,
    required this.firestoreService,
    this.userId,
    this.userData,
    required this.onInvite,
  });

  @override
  State<UserInvitationDialog> createState() => _UserInvitationDialogState();
}

class _UserInvitationDialogState extends State<UserInvitationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _yearlyVacationsController = TextEditingController();

  String _accessLevel = 'Employee';
  String _paymentType = 'Monthly';
  DateTime _hireDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _emailController.text = widget.userData!['email'] ?? '';
      _departmentController.text = widget.userData!['department'] ?? '';
      _positionController.text = widget.userData!['position'] ?? '';
      _accessLevel = widget.userData!['accessLevel'] ?? 'Employee';
      _paymentType = widget.userData!['paymentType'] ?? 'Monthly';

      if (widget.userData!['monthlyIncome'] != null) {
        _monthlyIncomeController.text = widget.userData!['monthlyIncome']
            .toString();
      }
      if (widget.userData!['hourlyRate'] != null) {
        _hourlyRateController.text = widget.userData!['hourlyRate'].toString();
      }
      if (widget.userData!['yearlyVacations'] != null) {
        _yearlyVacationsController.text = widget.userData!['yearlyVacations']
            .toString();
      }

      final hireDate = widget.userData!['hireDate'];
      if (hireDate is Timestamp) {
        _hireDate = hireDate.toDate();
      } else if (hireDate is String) {
        _hireDate = DateTime.parse(hireDate);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _monthlyIncomeController.dispose();
    _hourlyRateController.dispose();
    _yearlyVacationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF673AB7), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    widget.userData == null ? 'Invite User' : 'Edit User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                          prefixIcon: Icon(Icons.work),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _accessLevel,
                        decoration: const InputDecoration(
                          labelText: 'Access Level',
                          prefixIcon: Icon(Icons.security),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'Manager',
                            child: Text('Manager'),
                          ),
                          DropdownMenuItem(
                            value: 'Manager Read Only',
                            child: Text('Manager Read Only'),
                          ),
                          DropdownMenuItem(
                            value: 'Employee',
                            child: Text('Employee'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _accessLevel = value!),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _paymentType,
                        decoration: const InputDecoration(
                          labelText: 'Payment Type',
                          prefixIcon: Icon(Icons.payment),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Monthly',
                            child: Text('Monthly Salary'),
                          ),
                          DropdownMenuItem(
                            value: 'Hourly',
                            child: Text('Hourly Rate'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _paymentType = value!),
                      ),
                      const SizedBox(height: 16),

                      if (_paymentType == 'Monthly')
                        TextFormField(
                          controller: _monthlyIncomeController,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Income',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          controller: _hourlyRateController,
                          decoration: const InputDecoration(
                            labelText: 'Hourly Rate',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return 'Please enter a valid rate';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _hireDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => _hireDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hire Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_hireDate.day}/${_hireDate.month}/${_hireDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _yearlyVacationsController,
                        decoration: const InputDecoration(
                          labelText: 'Yearly Vacation Days',
                          prefixIcon: Icon(Icons.beach_access),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _sendInvitation,
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(
                      widget.userData == null
                          ? 'Send Invitation'
                          : 'Update User',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation() async {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'accessLevel': _accessLevel,
        'department': _departmentController.text.trim(),
        'position': _positionController.text.trim(),
        'paymentType': _paymentType,
        'monthlyIncome':
            _paymentType == 'Monthly' &&
                _monthlyIncomeController.text.isNotEmpty
            ? double.parse(_monthlyIncomeController.text)
            : null,
        'hourlyRate':
            _paymentType == 'Hourly' && _hourlyRateController.text.isNotEmpty
            ? double.parse(_hourlyRateController.text)
            : null,
        'hireDate': _hireDate.toIso8601String().split('T')[0],
        'yearlyVacations': _yearlyVacationsController.text.isNotEmpty
            ? int.parse(_yearlyVacationsController.text)
            : 0,
      };

      try {
        if (widget.userId == null) {
          final invitationId = await widget.firestoreService.sendUserInvitation(
            userData,
          );
          if (invitationId != null && context.mounted) {
            Navigator.pop(context);
            _showInvitationCodeDialog(
              context,
              invitationId,
              userData['email'] as String,
            );
          }
        } else {
          await widget.firestoreService.updateUserInvitation(
            widget.userId!,
            userData,
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        widget.onInvite(userData);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.firestoreService.getErrorMessage(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showInvitationCodeDialog(
    BuildContext context,
    String invitationCode,
    String email,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Invitation Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitation sent to $email',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Invitation Code:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      invitationCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: invitationCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invitation code copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to clipboard',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Next Steps:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Share this code with the invited user\n'
                    '2. They should open the Sign Up page\n'
                    '3. Click "Sign up with Invitation Code"\n'
                    '4. Enter this code to complete registration',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This invitation expires in 14 days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

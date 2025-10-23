import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getProjects(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading projects',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _firestoreService.getErrorMessage(snapshot.error),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF673AB7)),
            );
          }

          final projects = snapshot.data?.docs ?? [];

          if (projects.isEmpty) {
            return _buildEmptyState();
          }

          return _buildProjectsList(projects);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context),
        backgroundColor: const Color(0xFF673AB7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first project',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(List<QueryDocumentSnapshot> projects) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final doc = projects[index];
        final project = doc.data() as Map<String, dynamic>;
        final projectId = doc.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: project['billableToClient'] == true
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                project['projectType'] == 'External'
                    ? Icons.business
                    : Icons.folder_special,
                color: project['billableToClient'] == true
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
              ),
            ),
            title: Text(
              project['projectName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildChip(
                      project['projectType'],
                      project['projectType'] == 'External'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    if (project['billableToClient'] == true)
                      _buildChip('Billable', Colors.green),
                  ],
                ),
                if (project['clientName'] != null &&
                    project['clientName'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Client: ${project['clientName']}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
                if (project['location'] != null &&
                    project['location'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project['location'],
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
                if (project['paymentType'] != null) ...[
                  const SizedBox(height: 4),
                  if (project['paymentType'] == 'Lump Sum' &&
                      project['lumpSumAmount'] != null)
                    Text(
                      'Lump Sum: \$${project['lumpSumAmount']}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (project['paymentType'] == 'Billable Monthly' &&
                      project['monthlyRate'] != null)
                    Text(
                      'Monthly: \$${project['monthlyRate']}/month',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (project['paymentType'] == 'Billable Hourly' &&
                      project['hourlyRate'] != null)
                    Text(
                      'Hourly: \$${project['hourlyRate']}/hr',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
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
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteProject(projectId, project['projectName']);
                } else if (value == 'edit') {
                  _showEditProjectDialog(context, projectId, project);
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
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

  void _showCreateProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProjectFormDialog(
        firestoreService: _firestoreService,
        onSave: (projectData) async {
          // Firestore service will handle saving
        },
      ),
    );
  }

  void _showEditProjectDialog(
    BuildContext context,
    String projectId,
    Map<String, dynamic> projectData,
  ) {
    showDialog(
      context: context,
      builder: (context) => ProjectFormDialog(
        firestoreService: _firestoreService,
        projectId: projectId,
        projectData: projectData,
        onSave: (updatedData) async {
          // Firestore service will handle updating
        },
      ),
    );
  }

  void _deleteProject(String projectId, String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "$projectName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.deleteProject(projectId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Project deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
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
}

class ProjectFormDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final String? projectId;
  final Map<String, dynamic>? projectData;
  final Function(Map<String, dynamic>) onSave;

  const ProjectFormDialog({
    super.key,
    required this.firestoreService,
    this.projectId,
    this.projectData,
    required this.onSave,
  });

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _lumpSumAmountController = TextEditingController();
  final _monthlyRateController = TextEditingController();
  final _projectDescriptionController = TextEditingController();

  String _projectType = 'Internal';
  bool _billableToClient = false;
  String _paymentType = 'Lump Sum';

  @override
  void initState() {
    super.initState();
    if (widget.projectData != null) {
      _projectNameController.text = widget.projectData!['projectName'] ?? '';
      _projectType = widget.projectData!['projectType'] ?? 'Internal';
      _billableToClient = widget.projectData!['billableToClient'] ?? false;
      _paymentType = widget.projectData!['paymentType'] ?? 'Lump Sum';
      _clientNameController.text = widget.projectData!['clientName'] ?? '';
      _clientEmailController.text = widget.projectData!['clientEmail'] ?? '';
      _clientPhoneController.text = widget.projectData!['clientPhone'] ?? '';
      _locationController.text = widget.projectData!['location'] ?? '';
      _hourlyRateController.text =
          widget.projectData!['hourlyRate']?.toString() ?? '';
      _lumpSumAmountController.text =
          widget.projectData!['lumpSumAmount']?.toString() ?? '';
      _monthlyRateController.text =
          widget.projectData!['monthlyRate']?.toString() ?? '';
      _projectDescriptionController.text =
          widget.projectData!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _locationController.dispose();
    _hourlyRateController.dispose();
    _lumpSumAmountController.dispose();
    _monthlyRateController.dispose();
    _projectDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF673AB7), Color(0xFF9C27B0)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.projectData == null
                        ? 'Create New Project'
                        : 'Edit Project',
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
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name
                      TextFormField(
                        controller: _projectNameController,
                        decoration: InputDecoration(
                          labelText: 'Project Name *',
                          prefixIcon: const Icon(Icons.business_center),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter project name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Project Type
                      DropdownButtonFormField<String>(
                        initialValue: _projectType,
                        decoration: InputDecoration(
                          labelText: 'Project Type *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Internal',
                            child: Text('Internal'),
                          ),
                          DropdownMenuItem(
                            value: 'External',
                            child: Text('External'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _projectType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Billable to Client
                      SwitchListTile(
                        title: const Text('Billable to Client'),
                        subtitle: const Text(
                          'Will this project be billed to a client?',
                        ),
                        value: _billableToClient,
                        activeThumbColor: const Color(0xFF673AB7),
                        onChanged: (value) {
                          setState(() {
                            _billableToClient = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Client Information (conditional)
                      if (_billableToClient) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Client Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF673AB7),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Client Name
                        TextFormField(
                          controller: _clientNameController,
                          decoration: InputDecoration(
                            labelText: 'Client Name *',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (_billableToClient &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter client name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Client Email
                        TextFormField(
                          controller: _clientEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Client Email *',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (_billableToClient &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter client email';
                            }
                            if (_billableToClient &&
                                value != null &&
                                !value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Client Phone
                        TextFormField(
                          controller: _clientPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Client Phone',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payment Type
                        DropdownButtonFormField<String>(
                          initialValue: _paymentType,
                          decoration: InputDecoration(
                            labelText: 'Payment Type *',
                            prefixIcon: const Icon(Icons.payments),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Lump Sum',
                              child: Text('Lump Sum'),
                            ),
                            DropdownMenuItem(
                              value: 'Billable Monthly',
                              child: Text('Billable Monthly'),
                            ),
                            DropdownMenuItem(
                              value: 'Billable Hourly',
                              child: Text('Billable Hourly'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _paymentType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Lump Sum Amount (conditional)
                        if (_paymentType == 'Lump Sum')
                          TextFormField(
                            controller: _lumpSumAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Lump Sum Amount (\$) *',
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText: 'Total fixed amount for the project',
                            ),
                            validator: (value) {
                              if (_billableToClient &&
                                  _paymentType == 'Lump Sum' &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter lump sum amount';
                              }
                              if (_billableToClient &&
                                  _paymentType == 'Lump Sum' &&
                                  value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),

                        // Monthly Rate (conditional)
                        if (_paymentType == 'Billable Monthly')
                          TextFormField(
                            controller: _monthlyRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Monthly Rate (\$) *',
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText: 'Fixed rate charged per month',
                            ),
                            validator: (value) {
                              if (_billableToClient &&
                                  _paymentType == 'Billable Monthly' &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter monthly rate';
                              }
                              if (_billableToClient &&
                                  _paymentType == 'Billable Monthly' &&
                                  value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),

                        // Hourly Rate (conditional)
                        if (_paymentType == 'Billable Hourly')
                          TextFormField(
                            controller: _hourlyRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Hourly Rate (\$) *',
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText: 'Rate charged per hour of work',
                            ),
                            validator: (value) {
                              if (_billableToClient &&
                                  _paymentType == 'Billable Hourly' &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter hourly rate';
                              }
                              if (_billableToClient &&
                                  _paymentType == 'Billable Hourly' &&
                                  value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                      ],

                      // Location/City
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location/City *',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Project Description
                      TextFormField(
                        controller: _projectDescriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Project Description',
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action Buttons
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
                  ElevatedButton(
                    onPressed: _saveProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.projectData == null
                          ? 'Create Project'
                          : 'Save Changes',
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

  void _saveProject() async {
    if (_formKey.currentState!.validate()) {
      final projectData = {
        'projectName': _projectNameController.text.trim(),
        'projectType': _projectType,
        'billableToClient': _billableToClient,
        'paymentType': _billableToClient ? _paymentType : null,
        'clientName': _billableToClient
            ? _clientNameController.text.trim()
            : null,
        'clientEmail': _billableToClient
            ? _clientEmailController.text.trim()
            : null,
        'clientPhone': _billableToClient
            ? _clientPhoneController.text.trim()
            : null,
        'location': _locationController.text.trim(),
        'lumpSumAmount':
            _billableToClient &&
                _paymentType == 'Lump Sum' &&
                _lumpSumAmountController.text.isNotEmpty
            ? double.parse(_lumpSumAmountController.text)
            : null,
        'monthlyRate':
            _billableToClient &&
                _paymentType == 'Billable Monthly' &&
                _monthlyRateController.text.isNotEmpty
            ? double.parse(_monthlyRateController.text)
            : null,
        'hourlyRate':
            _billableToClient &&
                _paymentType == 'Billable Hourly' &&
                _hourlyRateController.text.isNotEmpty
            ? double.parse(_hourlyRateController.text)
            : null,
        'description': _projectDescriptionController.text.trim(),
      };

      try {
        if (widget.projectId == null) {
          // Create new project
          await widget.firestoreService.addProject(projectData);
        } else {
          // Update existing project
          await widget.firestoreService.updateProject(
            widget.projectId!,
            projectData,
          );
        }

        widget.onSave(projectData);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.projectId == null
                    ? 'Project created successfully'
                    : 'Project updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
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
}

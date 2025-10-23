import 'package:flutter/material.dart';
import '../models/work_location.dart';
import '../services/location_settings_service.dart';
import '../services/firestore_service.dart';
import 'location_picker_page.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final LocationSettingsService _locationService = LocationSettingsService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _organizationId;
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _organizationId = await _firestoreService.getCurrentUserOrganizationId();

      if (_organizationId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No organization found for current user';
        });
        return;
      }

      final settings = await _locationService.getLocationSettings(
        _organizationId!,
      );

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading settings: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_organizationId == null) return;

    setState(() {
      _settings[key] = value;
    });

    try {
      await _locationService.updateLocationSettings(_organizationId!, {
        key: value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Revert on error
      setState(() {
        _settings[key] = !value;
      });
    }
  }

  Future<void> _deleteLocation(WorkLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && location.id != null) {
      try {
        await _locationService.deleteWorkLocation(location.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting location: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddLocation() async {
    if (_organizationId == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerPage(organizationId: _organizationId!),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToEditLocation(WorkLocation location) async {
    if (_organizationId == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          organizationId: _organizationId!,
          existingLocation: location,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Management'),
        backgroundColor: const Color(0xFF2962FF),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadSettings,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Location Settings Section
                  _buildLocationSettings(),

                  const SizedBox(height: 16),

                  // Work Locations Section
                  _buildWorkLocations(),
                ],
              ),
            ),
    );
  }

  Widget _buildLocationSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  'Location Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingRow(
              'Location Tracking',
              'Track employee locations during work hours',
              _settings['locationTrackingEnabled'] ?? true,
              (value) => _updateSetting('locationTrackingEnabled', value),
            ),
            const Divider(height: 1),
            _buildSettingRow(
              'Require Location for Punch',
              'Employees must enable location services to clock in/out',
              _settings['requireLocationForPunch'] ?? false,
              (value) => _updateSetting('requireLocationForPunch', value),
            ),
            const Divider(height: 1),
            _buildSettingRow(
              'Allow Punch Outside Location',
              'Allow employees to clock in/out from anywhere, not just work locations',
              _settings['allowPunchOutsideLocation'] ?? true,
              (value) => _updateSetting('allowPunchOutsideLocation', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    Color statusColor = value ? Colors.green : Colors.grey;
    String statusText = value ? 'Enabled' : 'No';

    // Special case for "Allow Punch Outside Location"
    if (title == 'Allow Punch Outside Location') {
      statusText = value ? 'Yes' : 'No';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF2962FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkLocations() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Work Locations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2962FF)),
                  onPressed: _navigateToAddLocation,
                  tooltip: 'Add Location',
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<WorkLocation>>(
              stream: _locationService.getWorkLocations(_organizationId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error loading locations: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final locations = snapshot.data ?? [];

                if (locations.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No work locations added yet.\nTap + to add a location.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: locations.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return _buildLocationTile(location);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(WorkLocation location) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade400,
        child: const Icon(Icons.location_on, color: Colors.white),
      ),
      title: Text(
        location.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(location.address, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            'Radius: ${location.radiusMeters.toInt()}m',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _navigateToEditLocation(location),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteLocation(location),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

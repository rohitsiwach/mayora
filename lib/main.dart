import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/leave_service.dart';
import 'services/firestore_service.dart';
import 'pages/projects_page.dart';
import 'pages/users_page.dart';
import 'pages/invitation_signup_page.dart';
import 'pages/settings_page.dart';
import 'pages/locations_page.dart';
import 'pages/requests_page.dart';
import 'pages/schedule_page.dart';
import 'settings/settings_controller.dart';
import 'widgets/shift_calendar_widget.dart';
import 'widgets/home/home_welcome_header.dart';
import 'models/leave_request.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MayoraApp());
}

class MayoraApp extends StatelessWidget {
  const MayoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Mayora',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF673AB7),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF673AB7),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: const [Locale('en'), Locale('de')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/home': (context) => const MayoraHomePage(title: 'Mayora'),
            '/splash': (context) => const SplashScreen(),
            '/invitation-signup': (context) => const InvitationSignUpPage(),
            '/settings': (context) => const SettingsPage(),
            '/locations': (context) => const LocationsPage(),
            '/requests': (context) => const RequestsPage(),
            '/schedules': (context) => const SchedulePage(),
          },
        );
      },
    );
  }
}

class MayoraHomePage extends StatefulWidget {
  const MayoraHomePage({super.key, required this.title});

  final String title;

  @override
  State<MayoraHomePage> createState() => _MayoraHomePageState();
}

class _MayoraHomePageState extends State<MayoraHomePage> {
  final AuthService _authService = AuthService();
  final LeaveService _leaveService = LeaveService();
  final FirestoreService _firestoreService = FirestoreService();

  String get _userName {
    final user = _authService.currentUser;
    if (user != null) {
      return user.displayName ?? user.email?.split('@')[0] ?? 'User';
    }
    return 'User';
  }

  void _showLeaveRequestDialog() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to request leave'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final userId = user.uid;
    final organizationId = await _firestoreService
        .getCurrentUserOrganizationId();

    if (organizationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load organization data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final formKey = GlobalKey<FormState>();
    LeaveType? selectedLeaveType;
    DateTime? startDate;
    DateTime? endDate;
    final reasonController = TextEditingController();

    if (!mounted) return;

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
                  userId,
                  organizationId,
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
    String userId,
    String organizationId,
  ) async {
    if (!formKey.currentState!.validate()) return;
    if (leaveType == null || startDate == null || endDate == null) return;

    try {
      final numberOfDays = endDate.difference(startDate).inDays + 1;
      final user = _authService.currentUser;
      final request = LeaveRequest(
        userId: userId,
        userName: user?.displayName ?? user?.email ?? 'Unknown',
        organizationId: organizationId,
        leaveTypeId: leaveType.id,
        leaveTypeName: leaveType.name,
        startDate: startDate,
        endDate: endDate,
        numberOfDays: numberOfDays,
        reason: reason.trim(),
        createdAt: DateTime.now(),
      );

      await _leaveService.submitUserLeaveRequest(userId, request);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload the calendar to show the new leave request
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Image.asset(
              'assets/images/mayora_logo.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.flutter_dash, size: 32);
              },
            ),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            HomeWelcomeHeader(userName: _userName),
            const SizedBox(height: 20),

            // Shift Calendar Widget
            const ShiftCalendarWidget(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLeaveRequestDialog,
        tooltip: 'Request Leave',
        icon: const Icon(Icons.add),
        label: const Text('Request Leave'),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF673AB7),
                  const Color(0xFF9C27B0),
                  const Color(0xFF00BCD4),
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/mayora_logo.png',
                    height: 60,
                    width: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.flutter_dash,
                        size: 60,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mayora',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome $_userName',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Divider(),

                // Management Section
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Text(
                    'MANAGEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Users'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsersPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Projects'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProjectsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Locations'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.approval),
                  title: const Text('Requests'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedules'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SchedulePage(),
                      ),
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              // Close the drawer first
              Navigator.pop(context);

              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout == true && context.mounted) {
                try {
                  final authService = AuthService();
                  await authService.signOut();

                  if (context.mounted) {
                    // Navigate to root and replace with AuthWrapper
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

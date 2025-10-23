import 'package:flutter/material.dart';
import '../settings/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            children: [
              // Theme section
              const ListTile(
                title: Text('Appearance'),
                subtitle: Text('Choose light or dark theme'),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: settings.isDarkMode,
                onChanged: settings.toggleDarkMode,
                secondary: const Icon(Icons.dark_mode),
              ),
              const Divider(height: 32),

              // Language section
              const ListTile(
                title: Text('Language'),
                subtitle: Text('Select application language'),
              ),
              RadioListTile<Locale>(
                title: const Text('English'),
                value: const Locale('en'),
                groupValue: settings.locale,
                onChanged: (loc) {
                  if (loc != null) settings.setLocale(loc);
                },
                secondary: const Icon(Icons.language),
              ),
              RadioListTile<Locale>(
                title: const Text('Deutsch'),
                value: const Locale('de'),
                groupValue: settings.locale,
                onChanged: (loc) {
                  if (loc != null) settings.setLocale(loc);
                },
                secondary: const Icon(Icons.language),
              ),
            ],
          );
        },
      ),
    );
  }
}

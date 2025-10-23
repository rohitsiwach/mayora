import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.settings ?? 'Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Appearance Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations?.appearance ?? 'APPEARANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(localizations?.darkMode ?? 'Dark Mode'),
                  subtitle: Text(
                    isDark
                        ? (localizations?.darkThemeEnabled ??
                              'Dark theme is enabled')
                        : (localizations?.lightThemeEnabled ??
                              'Light theme is enabled'),
                  ),
                  value: isDark,
                  onChanged: (value) {
                    themeProvider.setTheme(value);
                  },
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations?.language ?? 'LANGUAGE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(
                    localizations?.selectLanguage ?? 'Select Language',
                  ),
                  subtitle: Text(
                    localeProvider.getLanguageName(
                      localeProvider.locale.languageCode,
                    ),
                  ),
                  trailing: DropdownButton<Locale>(
                    value: localeProvider.locale,
                    underline: const SizedBox(),
                    items: localeProvider.supportedLocales.map((Locale locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Row(
                          children: [
                            Text(
                              locale.languageCode == 'en' ? '🇬🇧' : '🇩🇪',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localeProvider.getLanguageName(
                                locale.languageCode,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (Locale? locale) {
                      if (locale != null) {
                        localeProvider.setLocale(locale);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

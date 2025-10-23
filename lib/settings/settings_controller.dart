import 'package:flutter/material.dart';

/// Global settings controller for theme and locale.
/// Keeps the implementation minimal and dependency-free.
class SettingsController extends ChangeNotifier {
  SettingsController._internal();

  static final SettingsController instance = SettingsController._internal();

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isEnglish => _locale.languageCode == 'en';

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleDarkMode(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  void setLocale(Locale locale) {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
  }
}

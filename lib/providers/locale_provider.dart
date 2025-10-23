import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('en'); // Default to English
  bool _isInitialized = false;

  LocaleProvider() {
    _loadLocalePreference();
  }

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  List<Locale> get supportedLocales => const [
    Locale('en'), // English
    Locale('de'), // German
  ];

  Future<void> _loadLocalePreference() async {
    // Skip shared_preferences on web due to plugin limitations
    if (kIsWeb) {
      _locale = const Locale('en');
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey);
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading locale preference: $e');
      _locale = const Locale('en');
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    // Skip shared_preferences on web due to plugin limitations
    if (kIsWeb) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      default:
        return languageCode;
    }
  }
}

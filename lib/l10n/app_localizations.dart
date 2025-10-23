import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Translations map
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'Mayora',
      'welcome': 'Welcome',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'create': 'Create',
      'add': 'Add',
      'remove': 'Remove',
      'search': 'Search',
      'logout': 'Logout',
      'yes': 'Yes',
      'no': 'No',

      // Navigation
      'home': 'Home',
      'settings': 'Settings',
      'users': 'Users',
      'projects': 'Projects',
      'management': 'MANAGEMENT',

      // Settings Page
      'appearance': 'APPEARANCE',
      'language': 'LANGUAGE',
      'dark_mode': 'Dark Mode',
      'dark_theme_enabled': 'Dark theme is enabled',
      'light_theme_enabled': 'Light theme is enabled',
      'select_language': 'Select Language',
      'theme_preview': 'THEME PREVIEW',
      'color_scheme': 'Color Scheme',
      'sample_components': 'Sample Components',
      'about': 'ABOUT',
      'app_version': 'App Version',
      'theme_system': 'Theme System',
      'material_design': 'Material Design 3',

      // Colors
      'primary': 'Primary',
      'secondary': 'Secondary',
      'tertiary': 'Tertiary',
      'surface': 'Surface',
      'background': 'Background',

      // Buttons
      'elevated_button': 'Elevated Button',
      'outlined_button': 'Outlined Button',
      'text_button': 'Text Button',

      // Auth
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',

      // Logout
      'logout_confirmation': 'Are you sure you want to logout?',
      'logout_title': 'Logout',

      // User Management
      'invitations': 'Invitations',
      'user_groups': 'User Groups',
    },
    'de': {
      // General
      'app_name': 'Mayora',
      'welcome': 'Willkommen',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'create': 'Erstellen',
      'add': 'Hinzufügen',
      'remove': 'Entfernen',
      'search': 'Suchen',
      'logout': 'Abmelden',
      'yes': 'Ja',
      'no': 'Nein',

      // Navigation
      'home': 'Startseite',
      'settings': 'Einstellungen',
      'users': 'Benutzer',
      'projects': 'Projekte',
      'management': 'VERWALTUNG',

      // Settings Page
      'appearance': 'ERSCHEINUNGSBILD',
      'language': 'SPRACHE',
      'dark_mode': 'Dunkler Modus',
      'dark_theme_enabled': 'Dunkles Design ist aktiviert',
      'light_theme_enabled': 'Helles Design ist aktiviert',
      'select_language': 'Sprache auswählen',
      'theme_preview': 'DESIGN-VORSCHAU',
      'color_scheme': 'Farbschema',
      'sample_components': 'Beispiel-Komponenten',
      'about': 'ÜBER',
      'app_version': 'App-Version',
      'theme_system': 'Design-System',
      'material_design': 'Material Design 3',

      // Colors
      'primary': 'Primär',
      'secondary': 'Sekundär',
      'tertiary': 'Tertiär',
      'surface': 'Oberfläche',
      'background': 'Hintergrund',

      // Buttons
      'elevated_button': 'Erhöhter Button',
      'outlined_button': 'Umrandeter Button',
      'text_button': 'Text-Button',

      // Auth
      'sign_in': 'Anmelden',
      'sign_up': 'Registrieren',
      'email': 'E-Mail',
      'password': 'Passwort',

      // Logout
      'logout_confirmation': 'Möchten Sie sich wirklich abmelden?',
      'logout_title': 'Abmelden',

      // User Management
      'invitations': 'Einladungen',
      'user_groups': 'Benutzergruppen',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for commonly used strings
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get create => translate('create');
  String get add => translate('add');
  String get remove => translate('remove');
  String get search => translate('search');
  String get logout => translate('logout');
  String get yes => translate('yes');
  String get no => translate('no');
  String get home => translate('home');
  String get settings => translate('settings');
  String get users => translate('users');
  String get projects => translate('projects');
  String get management => translate('management');
  String get appearance => translate('appearance');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get darkThemeEnabled => translate('dark_theme_enabled');
  String get lightThemeEnabled => translate('light_theme_enabled');
  String get selectLanguage => translate('select_language');
  String get themePreview => translate('theme_preview');
  String get colorScheme => translate('color_scheme');
  String get sampleComponents => translate('sample_components');
  String get about => translate('about');
  String get appVersion => translate('app_version');
  String get themeSystem => translate('theme_system');
  String get materialDesign => translate('material_design');
  String get primary => translate('primary');
  String get secondary => translate('secondary');
  String get tertiary => translate('tertiary');
  String get surface => translate('surface');
  String get background => translate('background');
  String get elevatedButton => translate('elevated_button');
  String get outlinedButton => translate('outlined_button');
  String get textButton => translate('text_button');
  String get logoutConfirmation => translate('logout_confirmation');
  String get logoutTitle => translate('logout_title');
  String get invitations => translate('invitations');
  String get userGroups => translate('user_groups');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

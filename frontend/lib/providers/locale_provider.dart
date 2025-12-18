import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('id'); // Default Indonesian
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  bool get isIndonesian => _locale.languageCode == 'id';
  bool get isEnglish => _locale.languageCode == 'en';

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('id'), // Indonesian
    Locale('en'), // English
  ];

  // Language display names
  static const Map<String, String> languageNames = {
    'id': 'Bahasa Indonesia',
    'en': 'English',
  };

  LocaleProvider() {
    _loadLocalePreference();
  }

  Future<void> _loadLocalePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'id'; // Default to Indonesian
      _locale = Locale(languageCode);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }

  Future<void> toggleLocale() async {
    final newLocale = _locale.languageCode == 'id'
        ? const Locale('en')
        : const Locale('id');
    await setLocale(newLocale);
  }

  String get currentLanguageName => languageNames[_locale.languageCode] ?? 'Unknown';
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// Manages the app's locale setting.
/// Default language is English ('en').
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_locale';
  static const String _firstLaunchKey = 'language_selected';
  static const String defaultLocale = 'en';
  static const List<Map<String, String>> supportedLocales = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
  ];

  String _locale = defaultLocale;
  late AppStrings _strings;
  bool _hasSelectedLanguage = false;

  String get locale => _locale;
  AppStrings get strings => _strings;
  bool get hasSelectedLanguage => _hasSelectedLanguage;

  LocaleProvider() {
    _strings = AppStrings(_locale);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_prefKey) ?? defaultLocale;
    _hasSelectedLanguage = prefs.getBool(_firstLaunchKey) ?? false;
    _strings = AppStrings(_locale);
    notifyListeners();
  }

  Future<void> setLocale(String code, {bool markSelected = true}) async {
    _locale = code;
    _strings = AppStrings(_locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    if (markSelected && !_hasSelectedLanguage) {
      _hasSelectedLanguage = true;
      await prefs.setBool(_firstLaunchKey, true);
    }
    notifyListeners();
  }

  Future<void> markLanguageSelected() async {
    if (_hasSelectedLanguage) return;
    _hasSelectedLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }
}

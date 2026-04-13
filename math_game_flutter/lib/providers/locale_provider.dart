import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// Manages the app's locale setting.
/// Default language is English ('en').
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_locale';
  static const String defaultLocale = 'en';
  static const List<Map<String, String>> supportedLocales = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
  ];

  String _locale = defaultLocale;
  late AppStrings _strings;

  String get locale => _locale;
  AppStrings get strings => _strings;

  LocaleProvider() {
    _strings = AppStrings(_locale);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_prefKey) ?? defaultLocale;
    _strings = AppStrings(_locale);
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    if (_locale == code) return;
    _locale = code;
    _strings = AppStrings(_locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    notifyListeners();
  }
}

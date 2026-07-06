import 'dart:ui' show PlatformDispatcher;
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

  /// 지원 언어 중 기기(시스템) 언어와 일치하는 코드. 미지원 언어면 영어.
  static String deviceLocale() {
    final String dev = PlatformDispatcher.instance.locale.languageCode;
    final supported = supportedLocales.any((l) => l['code'] == dev);
    return supported ? dev : defaultLocale;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // (2026-07-02) 첫 실행: 기기 언어 자동 추종 (한국어 폰 → 한국어).
    // 사용자가 설정에서 직접 고르기 전까지는 저장하지 않고 시스템 언어를 따라간다.
    _locale = prefs.getString(_prefKey) ?? deviceLocale();
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

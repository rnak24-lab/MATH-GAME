import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';

/// 첫 실행 언어 선택 다이얼로그 — 선택 전엔 닫을 수 없음.
/// 선택 즉시 저장(language_selected 플래그) → 이후 실행에선 표시 안 됨.
class LanguageSelectDialog {
  /// 아직 언어를 선택한 적 없으면 다이얼로그 표시.
  static Future<void> showIfNeeded(
    BuildContext context,
    LocaleProvider localeProvider,
    VoidCallback onChanged,
  ) async {
    if (localeProvider.hasSelectedLanguage) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Text('🌏', style: TextStyle(fontSize: 40)),
              SizedBox(height: 8),
              Text(
                'Language · 언어',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: LocaleProvider.supportedLocales.map((loc) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await localeProvider.setLocale(loc['code']!);
                      if (ctx.mounted) Navigator.pop(ctx);
                      onChanged();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3EEFF),
                      foregroundColor: const Color(0xFF2C3E50),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(loc['flag']!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(
                          loc['name']!,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

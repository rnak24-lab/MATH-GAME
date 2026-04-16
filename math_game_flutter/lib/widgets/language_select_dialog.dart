import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';

/// First-launch language selection dialog.
/// Shown when the user first opens the app. Cannot be dismissed until a
/// language is chosen. Stores the choice via LocaleProvider.setLocale which
/// also flips the `language_selected` flag so it doesn't show again.
class LanguageSelectDialog extends StatefulWidget {
  final LocaleProvider localeProvider;

  const LanguageSelectDialog({
    super.key,
    required this.localeProvider,
  });

  /// Shows the dialog if the user has never picked a language.
  /// Returns the code they picked, or null if already selected.
  static Future<String?> showIfNeeded(
    BuildContext context,
    LocaleProvider localeProvider,
  ) async {
    if (localeProvider.hasSelectedLanguage) return null;
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LanguageSelectDialog(localeProvider: localeProvider),
    );
  }

  @override
  State<LanguageSelectDialog> createState() => _LanguageSelectDialogState();
}

class _LanguageSelectDialogState extends State<LanguageSelectDialog> {
  String? _hoverCode;

  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🌐',
                style: TextStyle(fontSize: 44),
              ),
              const SizedBox(height: 12),
              Text(
                s.get('selectLanguage'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.get('selectLanguageDesc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ...LocaleProvider.supportedLocales.map((loc) {
                final code = loc['code']!;
                final isHover = _hoverCode == code;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isHover
                        ? const Color(0xFF7C4DFF).withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 1.5,
                    shadowColor: const Color(0xFF7C4DFF).withOpacity(0.2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onHover: (h) =>
                          setState(() => _hoverCode = h ? code : null),
                      onTap: () async {
                        await widget.localeProvider.setLocale(code);
                        if (context.mounted) {
                          Navigator.of(context).pop(code);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Text(
                              loc['flag']!,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                loc['name']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF7C4DFF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final LocaleProvider localeProvider;
  final VoidCallback onChanged;

  const SettingsScreen({
    super.key,
    required this.localeProvider,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = widget.localeProvider.strings;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.get('settings'),
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Languages section
          _buildSectionTitle(s.get('languageSettings')),
          const SizedBox(height: 12),
          ...LocaleProvider.supportedLocales.map((loc) {
            final isSelected =
                widget.localeProvider.locale == loc['code'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? const Color(0xFF7C4DFF).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: isSelected ? 2 : 1,
                shadowColor: const Color(0xFF7C4DFF).withOpacity(0.2),
                child: InkWell(
                  onTap: () async {
                    await widget.localeProvider
                        .setLocale(loc['code']!);
                    widget.onChanged();
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          loc['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            loc['name']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF7C4DFF)
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF7C4DFF),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          _buildSectionTitle(s.get('aboutSettings')),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 1,
            shadowColor: const Color(0xFF7C4DFF).withOpacity(0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivacyPolicyScreen(
                      localeProvider: widget.localeProvider,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined,
                        color: Color(0xFF7C4DFF)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        s.get('privacyPolicy'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF7C4DFF)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2C3E50),
      ),
    );
  }
}

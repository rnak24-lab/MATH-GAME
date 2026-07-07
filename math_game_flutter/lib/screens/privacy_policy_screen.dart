import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/locale_provider.dart';

/// GitHub Pages에 호스팅된 개인정보처리방침 HTML을 WebView로 로드.
/// URL은 rnak24-lab/nim-privacy 저장소의 GitHub Pages.
class PrivacyPolicyScreen extends StatefulWidget {
  final LocaleProvider localeProvider;
  const PrivacyPolicyScreen({super.key, required this.localeProvider});

  static const String policyUrl = 'https://rnak24-lab.github.io/nim-privacy/';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFF3E0))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(PrivacyPolicyScreen.policyUrl));
  }

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
          s.get('privacyPolicy'),
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
              ),
            ),
        ],
      ),
    );
  }
}

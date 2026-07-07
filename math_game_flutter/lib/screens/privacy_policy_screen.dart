import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/locale_provider.dart';

/// GitHub Pages에 호스팅된 개인정보처리방침 HTML을 WebView로 로드.
/// URL은 rnak24-lab/nim-privacy 저장소의 GitHub Pages.
/// WebView 미지원 플랫폼(웹 미리보기 등)에서는 크래시 대신 URL 안내로 폴백.
class PrivacyPolicyScreen extends StatefulWidget {
  final LocaleProvider localeProvider;
  const PrivacyPolicyScreen({super.key, required this.localeProvider});

  static const String policyUrl = 'https://rnak24-lab.github.io/nim-privacy/';

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  WebViewController? _controller;
  bool _loading = true;

  /// webview_flutter는 Android/iOS만 지원 — 그 외(웹 등)는 폴백 UI.
  bool get _webViewSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_webViewSupported) {
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
    } else {
      _loading = false;
    }
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
      body: _webViewSupported
          ? Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
                    ),
                  ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.privacy_tip_outlined,
                        size: 48, color: Color(0xFF7C4DFF)),
                    const SizedBox(height: 16),
                    Text(
                      s.get('privacyPolicy'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SelectableText(
                      PrivacyPolicyScreen.policyUrl,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7C4DFF),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

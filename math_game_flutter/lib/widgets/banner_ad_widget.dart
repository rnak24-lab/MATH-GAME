import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// 하단 배너 광고 위젯. 로드 실패 또는 로딩 중에는 빈 공간 표시.
/// 결과 화면(승/패) 하단에 배치 권장.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = AdService.instance.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _loaded = false);
      },
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) {
      // 배너 영역은 고정 높이 유지 (레이아웃 점프 방지)
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

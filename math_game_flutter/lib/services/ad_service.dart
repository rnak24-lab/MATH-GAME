import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 ID 관리 — 테스트 ID로 배포한 뒤, 대표님이 실제 ID 주시면
/// [_realBannerId], [_realInterstitialId] 만 교체하면 된다.
/// `useTestIds = true` 이면 강제로 테스트 ID 사용 (현재 기본).
class AdIds {
  static const bool useTestIds = true;

  // Google 공식 테스트 ID (Android)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  // TODO: 대표님 실제 AdMob ID 확정 시 여기만 교체
  static const String _realBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _realInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _realRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  static String get banner => useTestIds ? _testBannerId : _realBannerId;
  static String get interstitial =>
      useTestIds ? _testInterstitialId : _realInterstitialId;
  static String get rewarded => useTestIds ? _testRewardedId : _realRewardedId;
}

/// 전면 광고 빈도 제한 + 로딩/표시 추상화.
/// 사용:
///   await AdService.instance.init();
///   AdService.instance.maybeShowInterstitial();
///   AdService.instance.createBannerAd(onLoaded: ...);
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _loadingInterstitial = false;

  /// 전면 광고 빈도 제한: 3 스테이지 클리어마다 1회.
  int _stageClearCount = 0;
  static const int interstitialEvery = 3;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('[AdService] init 실패: $e');
    }
  }

  /// 배너 광고 위젯 생성용 BannerAd 반환. 호출자가 dispose 책임.
  BannerAd createBannerAd({
    required VoidCallback onLoaded,
    VoidCallback? onFailed,
  }) {
    return BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, err) {
          debugPrint('[AdService] banner fail: $err');
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (_loadingInterstitial || _interstitialAd != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _loadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (a, err) {
              debugPrint('[AdService] interstitial show fail: $err');
              a.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdService] interstitial load fail: $err');
          _loadingInterstitial = false;
        },
      ),
    );
  }

  /// 스테이지 클리어 카운트를 증가시키고, [interstitialEvery]의 배수일 때만 전면 광고 표시.
  /// 반환값은 실제로 광고를 보여주려 시도했는지 여부.
  bool maybeShowInterstitialOnStageClear() {
    _stageClearCount++;
    if (_stageClearCount % interstitialEvery != 0) return false;
    return _showInterstitial();
  }

  bool _showInterstitial() {
    final ad = _interstitialAd;
    if (!_initialized || ad == null) {
      _loadInterstitial();
      return false;
    }
    ad.show();
    _interstitialAd = null;
    return true;
  }

  // ── 리워드 광고 (힌트 보기용) ──
  RewardedAd? _rewardedAd;
  bool _loadingRewarded = false;

  void _loadRewarded() {
    if (_loadingRewarded || _rewardedAd != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          debugPrint('[AdService] rewarded load fail: $err');
          _loadingRewarded = false;
        },
      ),
    );
  }

  /// 리워드 광고를 표시하고, 시청 완료 시 [onReward] 호출.
  /// 광고가 준비 안 됐으면 false 반환 (호출자가 폴백 처리 — 예: 그냥 힌트 제공).
  bool showRewardedAd({required VoidCallback onReward}) {
    final ad = _rewardedAd;
    if (!_initialized || ad == null) {
      _loadRewarded();
      return false;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewardedAd = null;
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        debugPrint('[AdService] rewarded show fail: $err');
        a.dispose();
        _rewardedAd = null;
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onReward());
    _rewardedAd = null;
    return true;
  }
}

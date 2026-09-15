import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 ID 관리 — 2026-07-24 실제 AdMob ID 발급 완료 (앱: 방과후 님게임).
/// 디버그 빌드에서 테스트하려면 `useTestIds = true` 로 잠깐 바꿀 것.
///
/// (2026-09-15 대표님) 광고 정책:
///  - 배너: **폐지**. 위젯·유닛 사용 코드 삭제. AdMob 콘솔의 banner_main 유닛만 남아 있음.
///  - 전면(스테이지 클리어): 테스터 기간 동안 OFF → [AdService.kInterstitialEnabled]
///  - 보상형(힌트): 유지
class AdIds {
  static const bool useTestIds = false;

  // Google 공식 테스트 ID (Android)
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  // 실제 AdMob ID (2026-07-24 발급 — interstitial_stageclear / rewarded_hint)
  // banner_main(ca-app-pub-2700643196600577/8295264277) 은 2026-09-15 배너 폐지로 미사용.
  static const String _realInterstitialId =
      'ca-app-pub-2700643196600577/1610702355';
  static const String _realRewardedId =
      'ca-app-pub-2700643196600577/8483232460';

  static String get interstitial =>
      useTestIds ? _testInterstitialId : _realInterstitialId;
  static String get rewarded => useTestIds ? _testRewardedId : _realRewardedId;
}

/// 전면 광고 빈도 제한 + 로딩/표시 추상화.
/// 사용:
///   await AdService.instance.init();
///   AdService.instance.maybeShowInterstitialOnStageClear();
///   AdService.instance.showRewardedAd(onReward: ...);
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// 전면 광고 스위치. **테스터 기간(2026-09-15~)에는 false** — 보상형(힌트)만 나간다.
  /// 정식 출시 때 true 로 되돌린다. false 면 로드조차 하지 않는다.
  static const bool kInterstitialEnabled = false;

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
      if (kInterstitialEnabled) _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('[AdService] init 실패: $e');
    }
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
    if (!kInterstitialEnabled) return false; // 테스터 기간: 전면 광고 없음
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

  // ── 리워드 광고 (힌트 보기용) — 테스터 기간에도 유지 ──
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

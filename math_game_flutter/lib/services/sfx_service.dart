import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';

/// 효과음 서비스 — 연속 재생을 위해 플레이어 3개 라운드로빈.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  final List<AudioPlayer> _pool = List.generate(3, (_) => AudioPlayer());
  int _i = 0;

  /// 돌 가져가기 "슉!"
  Future<void> playTake() async {
    if (!AppSettings.instance.sfx) return;
    final p = _pool[_i = (_i + 1) % _pool.length];
    try {
      await p.stop();
      await p.play(AssetSource('audio/sfx_take.wav'), volume: 0.8);
    } catch (_) {}
  }
}

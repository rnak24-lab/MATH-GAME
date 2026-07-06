import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';

/// 배경음악 서비스 — 고전 퍼즐게임풍 칩튠 루프 (tool/gen_bgm.dart로 생성한 자체 제작곡).
/// 설정의 배경음악 토글과 연동. 실패해도 앱 흐름엔 영향 없음.
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer _player = AudioPlayer();
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(AppSettings.instance.musicVolume);
      await _player.play(AssetSource('audio/bgm_main.wav'));
    } catch (_) {
      // 웹 자동재생 차단 등 — 조용히 무시 (다음 setEnabled(true)에서 재시도)
      _started = false;
    }
  }

  /// 음량 즉시 반영 (0.0 ~ 1.0) — 슬라이더 드래그 중 실시간 호출.
  Future<void> setVolume(double v) async {
    try {
      await _player.setVolume(v.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> setEnabled(bool on) async {
    try {
      if (on) {
        if (_started) {
          await _player.resume();
        } else {
          await start();
        }
      } else {
        await _player.pause();
      }
    } catch (_) {}
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';

/// 배경음악 서비스 — 아늑한 오르골 자장가 루프 (Suno Pro 생성, 상업적 이용 가능).
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
      await _player.play(AssetSource('audio/bgm_main.mp3'));
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

  /// 앱이 뒤로 가면 멈추고, 돌아오면 (배경음악 설정이 켜져 있을 때만) 다시 튼다.
  bool _inBackground = false;
  Future<void> onBackground() async {
    _inBackground = true;
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> onForeground() async {
    if (!_inBackground) return;
    _inBackground = false;
    if (_started && AppSettings.instance.music) {
      try {
        await _player.resume();
      } catch (_) {}
    }
  }

  Future<void> setEnabled(bool on) async {
    if (on && _inBackground) return;
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

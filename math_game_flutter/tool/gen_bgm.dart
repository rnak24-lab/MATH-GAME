// NIM GAME — 아늑한 오르골풍 BGM 생성기 (v2: 짜치는 사각파 → 포근한 사인파).
// 실행: flutter/bin/dart tool/gen_bgm.dart  →  assets/audio/bgm_main.wav
//
// 설계 (귀여움 규칙 준수: 차분함·반복·저자극):
// - A단조, 66 BPM, 8마디 루프(~29초), 심리스 루프
// - 오르골 톤 멜로디(사인+옥타브 배음, 지수 감쇠) — 드럼·사각파 없음
// - 따뜻한 사인 패드 코드 + 낮은 사인 베이스, 전체 피크 0.5로 조용하게
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sr = 22050; // 22.05kHz 모노 16비트
const double bpm = 66.0;
final double beat = 60.0 / bpm;
final double eighth = beat / 2;

double midiFreq(int m) => 440.0 * pow(2, (m - 69) / 12.0).toDouble();

/// (midi, 길이[8분음표 단위]) — midi 0 = 쉼표
class Ev {
  final int midi;
  final int len;
  const Ev(this.midi, this.len);
}

// ── 멜로디 (8마디 × 8분음표 8개) — 자장가처럼 띄엄띄엄, 쉼표 많이 ──
const melody = <Ev>[
  // Bar 1 (Am)
  Ev(69, 3), Ev(72, 1), Ev(76, 4),
  // Bar 2 (F)
  Ev(74, 3), Ev(72, 1), Ev(69, 4),
  // Bar 3 (C)
  Ev(67, 3), Ev(64, 1), Ev(67, 2), Ev(72, 2),
  // Bar 4 (G) — 숨 고르기
  Ev(71, 6), Ev(0, 2),
  // Bar 5 (Am)
  Ev(76, 3), Ev(74, 1), Ev(72, 4),
  // Bar 6 (F)
  Ev(69, 3), Ev(72, 1), Ev(74, 4),
  // Bar 7 (Em)
  Ev(71, 3), Ev(67, 1), Ev(64, 4),
  // Bar 8 (Am) — 루프 처음으로 사뿐히
  Ev(69, 6), Ev(0, 2),
];

// ── 코드 패드 (마디당 1개, 3화음) — Am F C G / Am F Em Am ──
const chords = <List<int>>[
  [57, 60, 64], // Am
  [53, 57, 60], // F
  [55, 60, 64], // C  (2전위로 부드럽게)
  [55, 59, 62], // G
  [57, 60, 64], // Am
  [53, 57, 60], // F
  [52, 55, 59], // Em
  [57, 60, 64], // Am
];

// ── 베이스 (마디당 온음표 1개, 낮은 루트) ──
const bassRoots = <int>[45, 41, 36, 43, 45, 41, 40, 45];

/// 오르골 톤: 기음 + 옥타브 위 배음이 살짝, 자연스러운 지수 감쇠.
void renderMusicBox(List<double> buf, List<Ev> evs, double unitSec, double vol) {
  double t0 = 0;
  for (final e in evs) {
    final dur = e.len * unitSec;
    if (e.midi > 0) {
      final f = midiFreq(e.midi);
      final n0 = (t0 * sr).round();
      // 감쇠 꼬리는 음길이보다 살짝 길게 — 오르골처럼 여운
      final n1 = ((t0 + dur * 1.4) * sr).round();
      for (int n = n0; n < n1 && n < buf.length; n++) {
        final t = n / sr - t0;
        final atk = t < 0.012 ? t / 0.012 : 1.0; // 살짝 부드러운 시작
        final env = atk * exp(-t * 2.2);
        final ph = f * t;
        final s = sin(2 * pi * ph) +
            0.25 * sin(2 * pi * ph * 2) * exp(-t * 4.0) +
            0.08 * sin(2 * pi * ph * 3) * exp(-t * 6.0);
        buf[n] += s * vol * env;
      }
    }
    t0 += dur;
  }
}

/// 따뜻한 패드: 사인 3화음, 아주 느린 어택/릴리즈로 뭉게뭉게.
void renderPad(List<double> buf, double vol) {
  for (int bar = 0; bar < chords.length; bar++) {
    final t0 = bar * 4 * beat;
    final dur = 4 * beat;
    final n0 = (t0 * sr).round();
    final n1 = ((t0 + dur) * sr).round();
    for (int n = n0; n < n1 && n < buf.length; n++) {
      final t = n / sr - t0;
      double env = 1.0;
      if (t < 0.6) env = t / 0.6; // 느린 어택
      final tail = dur - t;
      if (tail < 0.8) env = min(env, max(0, tail / 0.8)); // 느린 릴리즈
      double s = 0;
      for (final m in chords[bar]) {
        s += sin(2 * pi * midiFreq(m) * (n / sr));
      }
      buf[n] += s / chords[bar].length * vol * env;
    }
  }
}

/// 베이스: 낮은 사인, 온음표로 바닥만 받쳐줌.
void renderBass(List<double> buf, double vol) {
  for (int bar = 0; bar < bassRoots.length; bar++) {
    final t0 = bar * 4 * beat;
    final dur = 4 * beat;
    final n0 = (t0 * sr).round();
    final n1 = ((t0 + dur) * sr).round();
    final f = midiFreq(bassRoots[bar]);
    for (int n = n0; n < n1 && n < buf.length; n++) {
      final t = n / sr - t0;
      double env = 1.0;
      if (t < 0.05) env = t / 0.05;
      final tail = dur - t;
      if (tail < 0.3) env = min(env, max(0, tail / 0.3));
      buf[n] += sin(2 * pi * f * (n / sr)) * vol * env;
    }
  }
}

void main() {
  final total = (8 * 4 * beat * sr).round(); // 8마디
  final buf = List<double>.filled(total, 0.0);

  renderMusicBox(buf, melody, eighth, 0.30);
  renderPad(buf, 0.10);
  renderBass(buf, 0.14);

  // 피크 정규화 — 아늑하게 0.5까지만
  double peak = 0;
  for (final v in buf) {
    if (v.abs() > peak) peak = v.abs();
  }
  final g = peak > 0 ? 0.5 / peak : 1.0;

  final pcm = Int16List(total);
  for (int i = 0; i < total; i++) {
    pcm[i] = (buf[i] * g * 32767).round().clamp(-32768, 32767);
  }

  // WAV 헤더 (PCM 16bit mono)
  final dataLen = pcm.lengthInBytes;
  final header = BytesBuilder();
  void s(String x) => header.add(x.codeUnits);
  void u32(int x) =>
      header.add(Uint8List(4)..buffer.asByteData().setUint32(0, x, Endian.little));
  void u16(int x) =>
      header.add(Uint8List(2)..buffer.asByteData().setUint16(0, x, Endian.little));
  s('RIFF');
  u32(36 + dataLen);
  s('WAVE');
  s('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sr);
  u32(sr * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  s('data');
  u32(dataLen);

  final out = File('assets/audio/bgm_main.wav');
  out.parent.createSync(recursive: true);
  out.writeAsBytesSync(header.toBytes() + pcm.buffer.asUint8List());
  print('OK ${out.path} ${out.lengthSync()} bytes, ${total / sr}s loop');
}

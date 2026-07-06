// NIM GAME — 고전 퍼즐게임풍 칩튠 BGM 생성기.
// 실행: flutter/bin/dart tool/gen_bgm.dart  →  assets/audio/bgm_main.wav
//
// 설계 (귀여움 규칙 준수: 차분함·반복·저자극):
// - A단조, 96 BPM, 8마디 루프(20초), 심리스 루프
// - 사각파 멜로디(부드러운 볼륨) + 삼각파 베이스, 드럼 없음
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sr = 22050; // 22.05kHz 모노 16비트 → 약 0.9MB
const double bpm = 96.0;
final double beat = 60.0 / bpm; // 0.625s
final double eighth = beat / 2;

double midiFreq(int m) => 440.0 * pow(2, (m - 69) / 12.0).toDouble();

double squareWave(double ph) => (ph % 1.0) < 0.5 ? 1.0 : -1.0;
double triangleWave(double ph) {
  final p = ph % 1.0;
  return p < 0.5 ? 4 * p - 1 : 3 - 4 * p;
}

/// (midi, 길이[8분음표 단위]) — midi 0 = 쉼표
class Ev {
  final int midi;
  final int len;
  const Ev(this.midi, this.len);
}

// ── 멜로디 (8마디, 각 마디 8분음표 8개 분량) ──
const melody = <Ev>[
  // Bar 1
  Ev(69, 2), Ev(72, 2), Ev(76, 2), Ev(74, 1), Ev(72, 1),
  // Bar 2
  Ev(71, 4), Ev(69, 4),
  // Bar 3
  Ev(65, 1), Ev(69, 1), Ev(72, 2), Ev(69, 2), Ev(74, 1), Ev(72, 1),
  // Bar 4
  Ev(71, 2), Ev(67, 2), Ev(64, 4),
  // Bar 5
  Ev(69, 2), Ev(72, 2), Ev(76, 2), Ev(79, 1), Ev(76, 1),
  // Bar 6
  Ev(77, 2), Ev(76, 1), Ev(74, 1), Ev(72, 2), Ev(69, 2),
  // Bar 7
  Ev(71, 1), Ev(72, 1), Ev(74, 2), Ev(71, 2), Ev(67, 2),
  // Bar 8 (턴어라운드 → 루프 처음으로 자연 연결)
  Ev(69, 4), Ev(0, 2), Ev(64, 1), Ev(67, 1),
];

// ── 베이스 (4분음표, 마디당 4개) — Am Am F G | Am F G Em ──
const bass = <int>[
  45, 52, 45, 52, // Am
  45, 52, 45, 52, // Am
  41, 48, 41, 48, // F
  43, 50, 43, 50, // G
  45, 52, 45, 52, // Am
  41, 48, 41, 48, // F
  43, 50, 43, 50, // G
  40, 47, 40, 47, // Em
];

void render(List<double> buf, List<Ev> evs, double unitSec, double vol,
    double Function(double) osc) {
  double t0 = 0;
  for (final e in evs) {
    final dur = e.len * unitSec;
    if (e.midi > 0) {
      final f = midiFreq(e.midi);
      final n0 = (t0 * sr).round();
      final n1 = ((t0 + dur) * sr).round();
      const atk = 0.004, rel = 0.045;
      for (int n = n0; n < n1 && n < buf.length; n++) {
        final t = n / sr - t0;
        double env = 1.0;
        if (t < atk) env = t / atk;
        final tail = dur - t;
        if (tail < rel) env = min(env, max(0, tail / rel));
        buf[n] += osc(f * (n / sr)) * vol * env;
      }
    }
    t0 += dur;
  }
}

void main() {
  final total = (8 * 4 * beat * sr).round(); // 8마디
  final buf = List<double>.filled(total, 0.0);

  render(buf, melody, eighth, 0.14, squareWave);
  render(buf, bass.map((m) => Ev(m, 1)).toList(), beat, 0.18, triangleWave);

  // 소프트 클립 + 피크 정규화 (0.7)
  double peak = 0;
  for (final v in buf) {
    if (v.abs() > peak) peak = v.abs();
  }
  final g = peak > 0 ? 0.7 / peak : 1.0;

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

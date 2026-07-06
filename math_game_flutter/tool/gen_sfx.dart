// NIM GAME — "슉!" 돌 가져가기 효과음 생성기 (노이즈 스윕 whoosh).
// 실행: flutter/bin/dart tool/gen_sfx.dart → assets/audio/sfx_take.wav
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sr = 22050;

void main() {
  const double dur = 0.18;
  final int n = (sr * dur).round();
  final rng = Random(7);
  final buf = List<double>.filled(n, 0.0);

  double phase = 0;
  for (int i = 0; i < n; i++) {
    final t = i / sr;
    final env = exp(-t * 22); // 빠른 감쇠
    double f = 1500 - 6500 * t; // 고음 → 저음 스윕
    if (f < 250) f = 250;
    phase += 2 * pi * f / sr;
    final noise = rng.nextDouble() * 2 - 1;
    buf[i] = (noise * 0.55 + sin(phase) * 0.45) * env;
  }

  double peak = 0;
  for (final v in buf) {
    if (v.abs() > peak) peak = v.abs();
  }
  final g = peak > 0 ? 0.65 / peak : 1.0;
  final pcm = Int16List(n);
  for (int i = 0; i < n; i++) {
    pcm[i] = (buf[i] * g * 32767).round().clamp(-32768, 32767);
  }

  final dataLen = pcm.lengthInBytes;
  final h = BytesBuilder();
  void s(String x) => h.add(x.codeUnits);
  void u32(int x) =>
      h.add(Uint8List(4)..buffer.asByteData().setUint32(0, x, Endian.little));
  void u16(int x) =>
      h.add(Uint8List(2)..buffer.asByteData().setUint16(0, x, Endian.little));
  s('RIFF');
  u32(36 + dataLen);
  s('WAVE');
  s('fmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(sr);
  u32(sr * 2);
  u16(2);
  u16(16);
  s('data');
  u32(dataLen);

  final out = File('assets/audio/sfx_take.wav');
  out.writeAsBytesSync(h.toBytes() + pcm.buffer.asUint8List());
  print('OK ${out.path} ${out.lengthSync()} bytes');
}

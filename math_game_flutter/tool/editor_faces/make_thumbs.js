// 예린 표정 PNG → 대본 편집 페이지용 얼굴 썸네일 160px. 표정 그림을 바꾸면 다시 돌린다 (npm i pngjs 필요).
//   node tool/editor_faces/make_thumbs.js
const fs = require('fs');
const { PNG } = require('pngjs');
const SRC = 'C:/Users/leeyuseok/Desktop/dev-setup/MATH-GAME/math_game_flutter/assets/yerin';
const OUT = __dirname;
fs.mkdirSync(OUT, { recursive: true });
const N = 160, SIZE = 540, SX = 270;
const OFF = { smug: 230 };
const BG = [246, 239, 226];
for (const name of ['default', 'happy', 'worried', 'upset', 'smug', 'thinking']) {
  const img = PNG.sync.read(fs.readFileSync(`${SRC}/${name}.png`));
  const { width: W, height: H, data } = img;
  let top = 0;
  find: for (let y = 0; y < H; y += 2) for (let x = 300; x < 780; x += 4) if (data[(y * W + x) * 4 + 3] > 40) { top = y; break find; }
  const sy = Math.max(0, top + (OFF[name] ?? 70));
  const out = new PNG({ width: N, height: N });
  const k = SIZE / N;
  for (let oy = 0; oy < N; oy++) for (let ox = 0; ox < N; ox++) {
    const acc = [0, 0, 0]; let cnt = 0;
    for (let yy = Math.floor(sy + oy * k); yy < Math.floor(sy + (oy + 1) * k); yy++) for (let xx = Math.floor(SX + ox * k); xx < Math.floor(SX + (ox + 1) * k); xx++) {
      if (yy >= H || xx >= W) continue;
      const i = (yy * W + xx) * 4, a = data[i + 3] / 255;
      for (let c = 0; c < 3; c++) acc[c] += data[i + c] * a + BG[c] * (1 - a);
      cnt++;
    }
    const o = (oy * N + ox) * 4;
    for (let c = 0; c < 3; c++) out.data[o + c] = cnt ? Math.round(acc[c] / cnt) : BG[c];
    out.data[o + 3] = 255;
  }
  fs.writeFileSync(`${OUT}/${name}.png`, PNG.sync.write(out));
  console.log(name, 'top', top);
}

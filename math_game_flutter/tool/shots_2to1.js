// 스토어 스크린샷 1080x2400 → 상태바·제스처바 잘라내고 좌우 가장자리 늘려 2:1 (1125x2250)
const fs = require('fs');
const { PNG } = require('pngjs');
const SRC = 'C:/Users/leeyuseok/Desktop/dev-setup/MATH-GAME/math_game_flutter/store_assets/screenshots_v4/';
const OUT = 'C:/Users/leeyuseok/Desktop/dev-setup/MATH-GAME/math_game_flutter/store_assets/screenshots_v4_play/';
fs.mkdirSync(OUT, { recursive: true });
const TOP = 90, BOT = 60;
for (const f of fs.readdirSync(SRC).filter(f => f.endsWith('.png'))) {
  const p = PNG.sync.read(fs.readFileSync(SRC + f));
  const h = p.height - TOP - BOT, w = h / 2, pad = Math.round((w - p.width) / 2);
  const o = new PNG({ width: p.width + pad * 2, height: h });
  for (let y = 0; y < h; y++) for (let x = 0; x < o.width; x++) {
    const sx = Math.min(p.width - 1, Math.max(0, x - pad));
    const s = ((y + TOP) * p.width + sx) * 4, t = (y * o.width + x) * 4;
    for (let c = 0; c < 3; c++) o.data[t + c] = p.data[s + c];
    o.data[t + 3] = 255;
  }
  fs.writeFileSync(OUT + f, PNG.sync.write(o));
  console.log(f, o.width + 'x' + o.height);
}

// 대본 편집 페이지 생성 (엑셀 없이 브라우저에서 집필) — 2026-10-06
//   node tool/story_template.js export   (story_sheets.json 최신화, 엑셀이 없어도 json 은 먼저 써짐)
//   node tool/story_editor.js             → 볼트에 NIM_대본_편집.html
// 페이지에서 "파일로 저장" → 다운로드 폴더에 NIM_대본_수정.json
//   node tool/story_template.js importjson <그 파일>  → app_strings.dart ko 반영 + story_changed.txt
const fs = require('fs');
const path = require('path');

const sheets = JSON.parse(fs.readFileSync(path.join(__dirname, 'story_sheets.json'), 'utf8'));
const OUT = 'C:/Users/leeyuseok/Desktop/endolphin/03_프로젝트/NIM_GAME/NIM_대본_편집.html';
const data = sheets.filter(s => s.name !== '안내').map(s => ({ name: s.name, cols: s.cols, rows: s.rows }));
const json = JSON.stringify(data).replace(/</g, '\\u003c');

const html = `<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>님게임 대본 편집</title>
<style>
:root{--bg:#f6f1e7;--card:#fffdf8;--ink:#2b2418;--soft:#7a6c55;--line:#e3d8c4;--gold:#b8892f;--hi:#fff3cf;--me:#2e63b5;--yr:#a2452f}
@media (prefers-color-scheme:dark){:root{--bg:#1d1a15;--card:#26221b;--ink:#efe6d4;--soft:#a99a80;--line:#3a3328;--gold:#d6a84a;--hi:#3a321d;--me:#7fa6e8;--yr:#e08a72}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 "Pretendard","Malgun Gothic",system-ui,sans-serif}
header{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);padding:12px 16px}
h1{font-size:18px;margin:0 0 8px}
.bar{display:flex;flex-wrap:wrap;gap:8px;align-items:center}
.tab{border:1px solid var(--line);background:var(--card);color:var(--ink);padding:6px 12px;border-radius:999px;cursor:pointer;font:inherit}
.tab.on{background:var(--gold);border-color:var(--gold);color:#fff}
select,input[type=search]{font:inherit;padding:6px 10px;border:1px solid var(--line);border-radius:8px;background:var(--card);color:var(--ink)}
.save{margin-left:auto;background:var(--ink);color:var(--bg);border:0;padding:8px 16px;border-radius:8px;font:inherit;font-weight:700;cursor:pointer}
.count{color:var(--soft);font-size:13px}
.notes{color:var(--soft);font-size:13px;margin:8px 0 0;padding-left:18px}
main{max-width:860px;margin:0 auto;padding:12px 16px 80px}
.scene{margin:20px 0 6px;font-weight:700;color:var(--gold)}
.row{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:8px 10px;margin:6px 0}
.row.changed{background:var(--hi)}
.meta{font-size:12px;color:var(--soft);display:flex;gap:8px;flex-wrap:wrap}
.who-예린{color:var(--yr);font-weight:700}.who-나{color:var(--me);font-weight:700}
textarea{width:100%;border:0;background:transparent;color:var(--ink);font:inherit;resize:vertical;min-height:2.2em;padding:4px 0;outline:none}
.orig{font-size:12px;color:var(--soft);text-decoration:line-through}
.len{font-size:11px;color:var(--soft);text-align:right}.len.over{color:#c0392b}
</style></head><body>
<header>
  <h1>방과후 님게임 대본</h1>
  <div class="bar" id="tabs"></div>
  <div class="bar" style="margin-top:8px">
    <select id="world"><option value="">전체 수업</option></select>
    <input type="search" id="q" placeholder="찾기">
    <span class="count" id="count"></span>
    <button class="save" id="save">파일로 저장</button>
  </div>
  <ul class="notes">
    <li>문장 칸만 고치면 된다. 쓰는 대로 이 브라우저에 자동 저장.</li>
    <li>한 줄로, 60자 안쪽. 예린은 반말·무뚝뚝·속은 따뜻. 상표 과자 이름 금지. 공략(이기는 법)은 쓰지 않기.</li>
    <li>빈 칸을 채우면 새 대사로 추가. 다 쓰면 "파일로 저장" → "대본 반영해 줘".</li>
  </ul>
</header>
<main id="list"></main>
<script>
const DATA = ${json};
const KEY = 'nim_script_edits_v1';
let edits = {};
try { edits = JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { edits = {}; }
const persist = () => { try { localStorage.setItem(KEY, JSON.stringify(edits)); } catch (e) {} };
let cur = 0;
const $ = id => document.getElementById(id);
const last = s => s.cols.length - 1;
const worldCol = s => s.cols.indexOf('수업');
function worlds() {
  const set = new Set();
  for (const s of DATA) { const w = worldCol(s); if (w >= 0) for (const r of s.rows) if (r[w]) set.add(String(r[w]).split(' (')[0]); }
  return [...set].sort((a, b) => parseInt(a) - parseInt(b));
}
function changedCount() { return Object.keys(edits).filter(k => edits[k] !== undefined).length; }
function renderTabs() {
  $('tabs').innerHTML = '';
  DATA.forEach((s, i) => {
    const b = document.createElement('button');
    b.className = 'tab' + (i === cur ? ' on' : '');
    b.textContent = s.name;
    b.onclick = () => { cur = i; renderTabs(); render(); };
    $('tabs').appendChild(b);
  });
}
function render() {
  const s = DATA[cur], L = last(s), w = worldCol(s);
  const wf = $('world').value, q = $('q').value.trim();
  const list = $('list'); list.innerHTML = '';
  let lastScene = '';
  s.rows.forEach((r, ri) => {
    const key = r[0] || (s.name + '#' + ri);
    const orig = String(r[L] || '');
    const val = edits[key] !== undefined ? edits[key] : orig;
    if (wf && w >= 0 && !String(r[w]).startsWith(wf)) return;
    if (q && !(val + ' ' + r.join(' ')).includes(q)) return;
    if (s.name === '이야기') {
      const sc = r[2] + ' · ' + r[3];
      if (sc !== lastScene) { const h = document.createElement('div'); h.className = 'scene'; h.textContent = r[1] + ' — ' + sc; list.appendChild(h); lastScene = sc; }
    }
    const box = document.createElement('div');
    box.className = 'row' + (edits[key] !== undefined ? ' changed' : '');
    const meta = document.createElement('div'); meta.className = 'meta';
    const parts = s.name === '이야기' ? [r[4], r[5], r[6]] : r.slice(1, L);
    parts.forEach(p => { if (!p) return; const sp = document.createElement('span'); sp.textContent = p; if (p === '예린' || p === '나') sp.className = 'who-' + p; meta.appendChild(sp); });
    const ta = document.createElement('textarea'); ta.value = val; ta.rows = 1;
    const len = document.createElement('div'); len.className = 'len';
    const ol = document.createElement('div'); ol.className = 'orig';
    const upd = () => {
      len.textContent = ta.value.length + '자'; len.classList.toggle('over', ta.value.length > 60);
      ol.textContent = edits[key] !== undefined && orig ? orig : '';
    };
    ta.oninput = () => {
      const v = ta.value.replace(/\\n/g, ' ');
      if (v !== ta.value) ta.value = v;
      if (v === orig) delete edits[key]; else edits[key] = v;
      box.classList.toggle('changed', edits[key] !== undefined);
      persist(); upd(); $('count').textContent = '고친 줄 ' + changedCount();
    };
    upd();
    box.append(meta, ta, ol, len); list.appendChild(box);
  });
  $('count').textContent = '고친 줄 ' + changedCount();
}
worlds().forEach(w => { const o = document.createElement('option'); o.value = w.split('.')[0] + '.'; o.textContent = w; $('world').appendChild(o); });
$('world').onchange = render; $('q').oninput = render;
$('save').onclick = () => {
  const out = {};
  for (const s of DATA) {
    const L = last(s);
    out[s.name] = [s.cols].concat(s.rows.map((r, ri) => { const key = r[0] || (s.name + '#' + ri); const c = r.slice(); if (edits[key] !== undefined) c[L] = edits[key]; return c; }));
  }
  const blob = new Blob([JSON.stringify(out, null, 1)], { type: 'application/json' });
  const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'NIM_대본_수정.json'; a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
};
renderTabs(); render();
</script></body></html>`;
fs.writeFileSync(OUT, html, 'utf8');
console.log('WROTE ' + OUT + ' (' + (html.length / 1024 | 0) + 'KB)');

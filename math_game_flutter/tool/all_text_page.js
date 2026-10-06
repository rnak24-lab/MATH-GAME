// 게임 글 전체 편집 페이지 (엑셀 대신 브라우저) — node tool/all_text.js export 뒤에 실행
//   node tool/all_text_page.js → 볼트 NIM_GAME/NIM_게임글_전체_편집.html
// 페이지 "파일로 저장" → 다운로드 NIM_게임글_수정.json → node tool/all_text.js importjson <파일>
const fs = require('fs');
const path = require('path');
const sheets = JSON.parse(fs.readFileSync(path.join(__dirname, 'all_text_sheets.json'), 'utf8')).filter(s => s.name !== '안내');
const OUT = 'C:/Users/leeyuseok/Desktop/endolphin/03_프로젝트/NIM_GAME/NIM_게임글_전체_편집.html';
const data = sheets.map(s => ({ name: s.name, rows: s.rows.map(r => [r[0], r[1], r[2]]) }));
const json = JSON.stringify(data).replace(/</g, '\\u003c');

const html = `<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>님게임 게임 글 전체</title>
<style>
:root{--bg:#f6f1e7;--card:#fffdf8;--ink:#2b2418;--soft:#7a6c55;--line:#e3d8c4;--gold:#b8892f;--hi:#fff3cf}
@media (prefers-color-scheme:dark){:root{--bg:#1d1a15;--card:#26221b;--ink:#efe6d4;--soft:#a99a80;--line:#3a3328;--gold:#d6a84a;--hi:#3a321d}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 "Pretendard","Malgun Gothic",system-ui,sans-serif}
header{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);padding:12px 16px}
h1{font-size:18px;margin:0 0 8px}.bar{display:flex;flex-wrap:wrap;gap:8px;align-items:center}
.tab{border:1px solid var(--line);background:var(--card);color:var(--ink);padding:6px 12px;border-radius:999px;cursor:pointer;font:inherit}
.tab.on{background:var(--gold);border-color:var(--gold);color:#fff}
input[type=search]{font:inherit;padding:6px 10px;border:1px solid var(--line);border-radius:8px;background:var(--card);color:var(--ink);min-width:180px}
.save{margin-left:auto;background:var(--ink);color:var(--bg);border:0;padding:8px 16px;border-radius:8px;font:inherit;font-weight:700;cursor:pointer}
.count{color:var(--soft);font-size:13px}.notes{color:var(--soft);font-size:13px;margin:8px 0 0;padding-left:18px}
main{max-width:980px;margin:0 auto;padding:8px 16px 100px}
.row{display:grid;grid-template-columns:minmax(140px,36%) 1fr;gap:10px;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:8px 10px;margin:6px 0}
.row.changed{background:var(--hi)}
.sit{font-size:13px;color:var(--soft)}
textarea{width:100%;border:0;background:transparent;color:var(--ink);font:inherit;resize:vertical;min-height:2.2em;padding:2px 0;outline:none}
.orig{font-size:12px;color:var(--soft);text-decoration:line-through}
@media (max-width:640px){.row{grid-template-columns:1fr}}
</style></head><body>
<header>
  <h1>방과후 님게임 — 게임 안 모든 글</h1>
  <div class="bar" id="tabs"></div>
  <div class="bar" style="margin-top:8px">
    <input type="search" id="q" placeholder="찾기">
    <span class="count" id="count"></span>
    <button class="save" id="save">파일로 저장</button>
  </div>
  <ul class="notes">
    <li>왼쪽은 언제 나오는 글인지, 오른쪽 글만 고친다. 쓰는 대로 이 브라우저에 자동 저장.</li>
    <li>{0} {1} 은 게임이 숫자나 간식 이름을 넣는 자리라 지우지 않는다.</li>
    <li>다 고치면 "파일로 저장" → "게임글 반영해 줘".</li>
  </ul>
</header>
<main id="list"></main>
<script>
const DATA = ${json};
const KEY = 'nim_all_text_v1';
let edits = {};
try { edits = JSON.parse(localStorage.getItem(KEY) || '{}') || {}; } catch (e) { edits = {}; }
const persist = () => { try { localStorage.setItem(KEY, JSON.stringify(edits)); } catch (e) {} };
let cur = 0;
const $ = id => document.getElementById(id);
const count = () => { $('count').textContent = '고친 줄 ' + Object.keys(edits).length; };
function renderTabs() {
  $('tabs').innerHTML = '';
  DATA.forEach((s, i) => { const b = document.createElement('button'); b.className = 'tab' + (i === cur ? ' on' : ''); b.textContent = s.name + ' ' + s.rows.length;
    b.onclick = () => { cur = i; renderTabs(); render(); window.scrollTo(0, 0); }; $('tabs').appendChild(b); });
}
function render() {
  const q = $('q').value.trim(); const list = $('list'); list.innerHTML = '';
  for (const [sit, orig, key] of DATA[cur].rows) {
    const val = edits[key] !== undefined ? edits[key] : orig;
    if (q && !(sit + ' ' + val).includes(q)) continue;
    const row = document.createElement('div'); row.className = 'row' + (edits[key] !== undefined ? ' changed' : '');
    const s = document.createElement('div'); s.className = 'sit'; s.textContent = sit;
    const box = document.createElement('div');
    const ta = document.createElement('textarea'); ta.value = val; ta.rows = Math.max(1, val.split('\\n').length);
    const ol = document.createElement('div'); ol.className = 'orig';
    const upd = () => { ol.textContent = edits[key] !== undefined ? orig : ''; };
    ta.oninput = () => { if (ta.value === orig) delete edits[key]; else edits[key] = ta.value; row.classList.toggle('changed', edits[key] !== undefined); persist(); upd(); count(); };
    upd(); box.append(ta, ol); row.append(s, box); list.appendChild(row);
  }
  count();
}
$('q').oninput = render;
$('save').onclick = () => {
  const blob = new Blob([JSON.stringify({ version: 'all_text_1', edits }, null, 1)], { type: 'application/json' });
  const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'NIM_게임글_수정.json'; a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
};
renderTabs(); render();
</script></body></html>`;
fs.writeFileSync(OUT, html, 'utf8');
console.log('WROTE ' + OUT + ' (' + (html.length / 1024 | 0) + 'KB)');

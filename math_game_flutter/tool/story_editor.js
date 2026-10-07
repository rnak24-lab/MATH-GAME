// 대본 편집 페이지 v2 (2026-10-06) — 엑셀 없이 브라우저에서 집필, 줄 추가·삭제·화자·표정
//   node tool/story_editor.js   → 볼트에 NIM_대본_편집.html
// 페이지 "파일로 저장" → 다운로드 폴더 NIM_대본_수정.json
//   node tool/story_template.js importjson <그 파일>
const fs = require('fs');
const crypto = require('crypto');
const T = require('./story_template.js');

const OUT = 'C:/Users/leeyuseok/Desktop/endolphin/03_프로젝트/NIM_GAME/NIM_대본_편집.html';
const ko = T.readMap();
const g = k => ko[k] ?? '';
// 규칙 설명은 줄바꿈을 살려서 읽는다
const SRC = fs.readFileSync(require('path').join(__dirname, '../lib/l10n/app_strings.dart'), 'utf8').replace(/\r\n/g, '\n');
const gRaw = k => {
  const m = new RegExp("^    '" + k + "': \\{\\n[\\s\\S]*?^      'ko': '((?:[^'\\\\]|\\\\.)*)',", 'm').exec(SRC);
  return m ? m[1].replace(/\\(.)/g, (_, c) => (c === 'n' ? '\n' : c)) : g(k);
};
const script = T.readSceneScript();

const scenes = [];
for (const [n, name] of T.WORLDS) {
  for (let k = 1; k <= 4; k++) {
    const id = `sc_w${n}_${k}`;
    const lay = T.sceneLayout(n, k, script);
    scenes.push({
      id, world: n, label: `${n}-${k}`, wname: `${n}. ${name}`,
      kind: k === 4 ? '긴 장면 · 20판 다 깨면' : `${k * 5}판째`,
      title: g(`${id}_title`),
      lines: lay.map((l, i) => ({ who: l.who, face: l.face, text: g(`${id}_${i + 1}`) })),
    });
  }
}
const contiguous = base => { const a = []; for (let i = 1; i <= 30 && (`${base}_${i}` in ko); i++) a.push(g(`${base}_${i}`)); return a; };
const pools = [];
for (const [n, name] of T.WORLDS) pools.push({ base: `dc_w${n}`, label: `클리어 한마디 — ${n}. ${name}`, tab: 'clear', items: contiguous(`dc_w${n}`) });
for (const [base, label] of T.POOLS) pools.push({ base, label, tab: 'pool', items: contiguous(base) });
const singles = T.SINGLES.map(([key, label]) => ({ key, label, text: g(key) }));
const rules = [];
for (const [n, name] of T.WORLDS) {
  rules.push({ key: T.RULE_KEYS[n - 1], label: `${n}. ${name} — 규칙 본문 ({0}·{1} 은 그대로)`, text: gRaw(T.RULE_KEYS[n - 1]) });
  rules.push({ key: `rx_w${n}_1`, label: `${n}. ${name} — 보충 1`, text: gRaw(`rx_w${n}_1`) });
  rules.push({ key: `rx_w${n}_2`, label: `${n}. ${name} — 보충 2`, text: gRaw(`rx_w${n}_2`) });
  if (n === 4) for (let i = 1; i <= 4; i++) rules.push({ key: `ri_w4_${i}`, label: `4. 막대과자 규칙 화면 ${i}쪽`, text: gRaw(`ri_w4_${i}`) });
}
const BASE = { scenes, pools, singles, rules };
const hash = crypto.createHash('md5').update(JSON.stringify(BASE)).digest('hex').slice(0, 10);
const json = JSON.stringify({ ...BASE, hash }).replace(/</g, '\\u003c');
// 표정 고르기용 얼굴 그림 (tool/editor_faces/make_thumbs.js 로 만든 160px 썸네일)
const thumb = f => 'data:image/png;base64,' + fs.readFileSync(require('path').join(__dirname, 'editor_faces', f + '.png')).toString('base64');
const FACE_FILE = { neutral: 'default', happy1: 'happy', happy2: 'happy', worried1: 'worried', worried2: 'upset', confident: 'smug', thinking: 'thinking' };
const fimg = JSON.stringify(Object.fromEntries(Object.entries(FACE_FILE).map(([k, f]) => [k, thumb(f)])));

const html = `<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>님게임 대본 편집</title>
<style>
:root{--bg:#f6f1e7;--card:#fffdf8;--ink:#2b2418;--soft:#7a6c55;--line:#e3d8c4;--gold:#b8892f;--hi:#fff3cf;--me:#2e63b5;--yr:#a2452f;--bad:#c0392b}
@media (prefers-color-scheme:dark){:root{--bg:#1d1a15;--card:#26221b;--ink:#efe6d4;--soft:#a99a80;--line:#3a3328;--gold:#d6a84a;--hi:#3a321d;--me:#7fa6e8;--yr:#e08a72}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 "Pretendard","Malgun Gothic",system-ui,sans-serif}
header{position:sticky;top:0;z-index:5;background:var(--bg);border-bottom:1px solid var(--line);padding:12px 16px}
h1{font-size:18px;margin:0 0 8px}
.bar{display:flex;flex-wrap:wrap;gap:8px;align-items:center}
.tab{border:1px solid var(--line);background:var(--card);color:var(--ink);padding:6px 12px;border-radius:999px;cursor:pointer;font:inherit}
.tab.on{background:var(--gold);border-color:var(--gold);color:#fff}
select,input[type=search],input.title{font:inherit;padding:6px 10px;border:1px solid var(--line);border-radius:8px;background:var(--card);color:var(--ink)}
.save{margin-left:auto;background:var(--ink);color:var(--bg);border:0;padding:8px 16px;border-radius:8px;font:inherit;font-weight:700;cursor:pointer}
.ghost{background:transparent;border:1px solid var(--line);color:var(--soft);padding:6px 10px;border-radius:8px;font:inherit;cursor:pointer}
.count{color:var(--soft);font-size:13px}
.notes{color:var(--soft);font-size:13px;margin:8px 0 0;padding-left:18px}
main{max-width:880px;margin:0 auto;padding:12px 16px 120px}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px;margin:16px 0}
.card h2{font-size:15px;margin:0 0 8px;display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.card h2 .k{color:var(--gold)}
.card h2 .sub{color:var(--soft);font-weight:400;font-size:13px}
input.title{flex:1;min-width:160px}
.line{display:grid;grid-template-columns:auto auto 1fr auto;gap:6px;align-items:start;border-top:1px dashed var(--line);padding:6px 0}
.line.changed{background:var(--hi);border-radius:6px}
.who{border:0;border-radius:6px;padding:4px 8px;font:inherit;font-weight:700;cursor:pointer;color:#fff;min-width:48px}
.who.y{background:var(--yr)}.who.m{background:var(--me)}
.face{position:relative;border:1px solid var(--line);background:var(--card);border-radius:8px;padding:2px;cursor:pointer;display:flex;flex-direction:column;align-items:center;width:58px;font:inherit;color:var(--soft)}
.face img,.fopt img{display:block;border-radius:6px}
.face img{width:52px;height:52px}
.face span{font-size:10px;line-height:1.3}
.spark{position:absolute;top:0;right:2px;font-size:13px}
.fpop{position:absolute;z-index:20;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:8px;box-shadow:0 8px 24px rgba(0,0,0,.18);display:grid;grid-template-columns:repeat(4,84px);gap:6px}
.fopt{position:relative;border:2px solid transparent;background:transparent;border-radius:10px;padding:3px;cursor:pointer;display:flex;flex-direction:column;align-items:center;font:inherit;font-size:12px;color:var(--ink)}
.fopt img{width:72px;height:72px}
.fopt:hover{border-color:var(--line)}.fopt.on{border-color:var(--gold)}
textarea{width:100%;border:0;background:transparent;color:var(--ink);font:inherit;resize:vertical;min-height:2.2em;padding:4px 0;outline:none}
.tools{display:flex;gap:4px}
.tools button{border:1px solid var(--line);background:var(--card);color:var(--soft);border-radius:6px;width:30px;height:30px;cursor:pointer;font:inherit}
.add{margin-top:8px;border:1px dashed var(--gold);background:transparent;color:var(--gold);border-radius:8px;padding:6px 12px;font:inherit;font-weight:700;cursor:pointer}
.info{grid-column:3;font-size:11px;color:var(--soft)}.over{color:var(--bad)}
.item{display:grid;grid-template-columns:1fr auto;gap:6px;border-top:1px dashed var(--line);padding:6px 0}
.item.changed{background:var(--hi);border-radius:6px}
.lbl{font-size:12px;color:var(--soft)}
</style></head><body>
<header>
  <h1>방과후 님게임 대본</h1>
  <div class="bar" id="tabs"></div>
  <div class="bar" style="margin-top:8px">
    <select id="world"><option value="0">전체 수업</option></select>
    <input type="search" id="q" placeholder="찾기">
    <span class="count" id="count"></span>
    <button class="ghost" id="reset">처음 상태로</button>
    <button class="save" id="save">파일로 저장</button>
  </div>
  <ul class="notes">
    <li>예린/나 버튼을 누르면 화자가 바뀐다. 표정은 그 줄에서 예린 얼굴.</li>
    <li>＋ 는 바로 아래에 새 줄, ✕ 는 줄 삭제, ↑↓ 는 순서 이동. 쓰는 대로 자동 저장.</li>
    <li>한 줄 60자 안쪽 권장. 예린은 반말·무뚝뚝·속은 따뜻. 이기는 법(공략)은 쓰지 않기.</li>
  </ul>
</header>
<main id="list"></main>
<script>
const BASE = ${json};
const KEY = 'nim_script_v2';
const FACES = {neutral:'평온',happy1:'미소',happy2:'활짝',worried1:'살짝 곤란',worried2:'당황',confident:'자신만만',thinking:'생각 중'};
const FIMG = ${fimg};
// 표정은 그림으로 고른다 — 활짝은 미소 그림에 반짝이(게임에서도 반짝이가 붙음)
const faceImg = (f, cls) => { const w = document.createElement('span'); w.style.position = 'relative'; w.style.display = 'block';
  const im = document.createElement('img'); im.src = FIMG[f] || FIMG.neutral; im.alt = FACES[f] || f; w.append(im);
  if (f === 'happy2') w.append(el('span','spark','✨')); return w; };
let openPop = null;
const closePop = () => { if (openPop) { openPop.remove(); openPop = null; } };
document.addEventListener('click', e => { if (openPop && !openPop.contains(e.target)) closePop(); });
function facePicker(ln) {
  const b = el('button','face'); b.type = 'button'; b.title = '표정 바꾸기';
  b.append(faceImg(ln.face), el('span','',FACES[ln.face] || ln.face));
  b.onclick = e => {
    e.stopPropagation(); const was = openPop && openPop._for === b; closePop(); if (was) return;
    const pop = el('div','fpop'); pop._for = b;
    Object.keys(FACES).forEach(f => {
      const o = el('button','fopt' + (f === ln.face ? ' on' : '')); o.type = 'button';
      o.append(faceImg(f), el('span','',FACES[f]));
      o.onclick = ev => { ev.stopPropagation(); closePop(); if (ln.face !== f) { ln.face = f; bump(); render(); } };
      pop.append(o);
    });
    const r = b.getBoundingClientRect();
    pop.style.left = (r.left + window.scrollX) + 'px'; pop.style.top = (r.bottom + window.scrollY + 4) + 'px';
    document.body.append(pop); openPop = pop;
    const pr = pop.getBoundingClientRect();
    if (pr.right > window.innerWidth - 8) pop.style.left = Math.max(8, window.innerWidth - pr.width - 8 + window.scrollX) + 'px';
  };
  return b;
}
const clone = o => JSON.parse(JSON.stringify(o));
let S = null;
try { const sv = JSON.parse(localStorage.getItem(KEY) || 'null'); if (sv && sv.hash === BASE.hash) S = sv; } catch (e) {}
if (!S) {
  S = clone(BASE);
  // 앞 버전 페이지(nim_script_edits_v1)에서 쓴 내용이 있으면 옮겨 온다
  try {
    const v1 = JSON.parse(localStorage.getItem('nim_script_edits_v1') || '{}') || {};
    for (const [k, v] of Object.entries(v1)) {
      let m;
      if ((m = /^(sc_w\\d+_\\d)_(title|\\d+)$/.exec(k))) {
        const sc = S.scenes.find(s => s.id === m[1]); if (!sc) continue;
        if (m[2] === 'title') sc.title = v; else { const i = +m[2] - 1; if (sc.lines[i]) sc.lines[i].text = v; }
      } else if ((m = /^(.+)_(\\d+)$/.exec(k)) && S.pools.find(p => p.base === m[1])) {
        const p = S.pools.find(p => p.base === m[1]); const i = +m[2] - 1;
        while (p.items.length <= i) p.items.push(''); p.items[i] = v;
      } else {
        const x = S.singles.find(s => s.key === k) || S.rules.find(s => s.key === k); if (x) x.text = v;
      }
    }
  } catch (e) {}
}
const persist = () => { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} };
const TABS = [['story','이야기'],['clear','클리어 한마디'],['pool','상황별 대사'],['rules','규칙 설명']];
let tab = 'story';
const $ = id => document.getElementById(id);
const el = (t, c, txt) => { const e = document.createElement(t); if (c) e.className = c; if (txt !== undefined) e.textContent = txt; return e; };

function origScene(id){ return BASE.scenes.find(s => s.id === id); }
function origPool(b){ return BASE.pools.find(p => p.base === b); }
function countChanges(){
  let n = 0;
  S.scenes.forEach(sc => { const o = origScene(sc.id); if (sc.title !== o.title) n++;
    const L = Math.max(sc.lines.length, o.lines.length);
    for (let i = 0; i < L; i++) { const a = sc.lines[i], b = o.lines[i]; if (!a || !b || a.text !== b.text || a.who !== b.who || a.face !== b.face) n++; } });
  S.pools.forEach(p => { const o = origPool(p.base); const L = Math.max(p.items.length, o.items.length); for (let i = 0; i < L; i++) if (p.items[i] !== o.items[i]) n++; });
  ['singles','rules'].forEach(k => S[k].forEach((x, i) => { if (x.text !== BASE[k][i].text) n++; }));
  return n;
}
function bump(){ persist(); $('count').textContent = '고친 곳 ' + countChanges(); }
function ta(value, onchange, multi){
  const t = el('textarea'); t.value = value; t.rows = multi ? 3 : 1;
  t.oninput = () => { const v = multi ? t.value : t.value.replace(/\\n/g, ' '); if (v !== t.value) t.value = v; onchange(v); };
  return t;
}
function info(t){ const d = el('div','info'); const up = () => { d.textContent = t.value.length + '자'; d.classList.toggle('over', t.value.length > 60); }; t.addEventListener('input', up); up(); return d; }
function match(text){ const q = $('q').value.trim(); return !q || text.includes(q); }

function renderStory(list){
  const wf = +$('world').value;
  S.scenes.forEach(sc => {
    if (wf && sc.world !== wf) return;
    if (!match(sc.title + ' ' + sc.lines.map(l => l.text).join(' ') + ' ' + sc.wname)) return;
    const o = origScene(sc.id);
    const card = el('div','card');
    const h = el('h2'); h.append(el('span','k',sc.label), el('span','sub',sc.wname + ' · ' + sc.kind));
    const ti = el('input','title'); ti.value = sc.title; ti.placeholder = '장면 제목';
    ti.oninput = () => { sc.title = ti.value; bump(); };
    h.append(ti); card.append(h);
    sc.lines.forEach((ln, i) => {
      const ob = o.lines[i];
      const row = el('div','line' + (!ob || ob.text !== ln.text || ob.who !== ln.who || ob.face !== ln.face ? ' changed' : ''));
      const who = el('button','who ' + ln.who, ln.who === 'y' ? '예린' : '나');
      who.onclick = () => { ln.who = ln.who === 'y' ? 'm' : 'y'; bump(); render(); };
      const face = facePicker(ln);
      const t = ta(ln.text, v => { ln.text = v; row.classList.add('changed'); bump(); });
      const tools = el('div','tools');
      const mk = (txt, title, fn) => { const b = el('button','',txt); b.title = title; b.onclick = fn; tools.append(b); };
      mk('↑','위로',() => { if (i > 0) { [sc.lines[i-1], sc.lines[i]] = [sc.lines[i], sc.lines[i-1]]; bump(); render(); } });
      mk('↓','아래로',() => { if (i < sc.lines.length - 1) { [sc.lines[i+1], sc.lines[i]] = [sc.lines[i], sc.lines[i+1]]; bump(); render(); } });
      mk('＋','아래에 새 줄',() => { sc.lines.splice(i + 1, 0, { who: ln.who === 'y' ? 'm' : 'y', face: ln.face, text: '' }); bump(); render(); });
      mk('✕','이 줄 삭제',() => { if (sc.lines.length <= 1) return; if (ln.text && !confirm('이 줄을 지울까?')) return; sc.lines.splice(i, 1); bump(); render(); });
      row.append(who, face, t, tools, info(t));
      card.append(row);
    });
    const add = el('button','add','＋ 줄 추가');
    add.onclick = () => { const last = sc.lines[sc.lines.length - 1]; sc.lines.push({ who: last && last.who === 'y' ? 'm' : 'y', face: last ? last.face : 'neutral', text: '' }); bump(); render(); };
    card.append(el('div','lbl', sc.lines.length + '줄'), add);
    list.append(card);
  });
}
function renderPools(list, which){
  const wf = +$('world').value;
  S.pools.filter(p => p.tab === which).forEach(p => {
    if (which === 'clear' && wf && p.base !== 'dc_w' + wf) return;
    if (!match(p.label + ' ' + p.items.join(' '))) return;
    const o = origPool(p.base);
    const card = el('div','card'); card.append(el('h2','',p.label));
    p.items.forEach((t0, i) => {
      const row = el('div','item' + (o.items[i] !== t0 ? ' changed' : ''));
      const t = ta(t0, v => { p.items[i] = v; row.classList.add('changed'); bump(); });
      const tools = el('div','tools'); const x = el('button','','✕'); x.title = '삭제';
      x.onclick = () => { if (p.items.length <= 1) return; if (t0 && !confirm('이 대사를 지울까?')) return; p.items.splice(i, 1); bump(); render(); };
      tools.append(x); row.append(t, tools); card.append(row);
    });
    const add = el('button','add','＋ 대사 추가'); add.onclick = () => { p.items.push(''); bump(); render(); };
    card.append(add); list.append(card);
  });
  if (which === 'pool') {
    const card = el('div','card'); card.append(el('h2','','한 줄짜리 대사'));
    S.singles.forEach((x, i) => {
      if (!match(x.label + ' ' + x.text)) return;
      const row = el('div','item' + (x.text !== BASE.singles[i].text ? ' changed' : ''));
      const box = el('div'); box.append(el('div','lbl',x.label));
      const t = ta(x.text, v => { x.text = v; row.classList.add('changed'); bump(); }); box.append(t);
      row.append(box, el('div')); card.append(row);
    });
    list.append(card);
  }
}
function renderRules(list){
  const card = el('div','card');
  S.rules.forEach((x, i) => {
    if (!match(x.label + ' ' + x.text)) return;
    const row = el('div','item' + (x.text !== BASE.rules[i].text ? ' changed' : ''));
    const box = el('div'); box.append(el('div','lbl',x.label));
    box.append(ta(x.text, v => { x.text = v; row.classList.add('changed'); bump(); }, true));
    row.append(box, el('div')); card.append(row);
  });
  list.append(card);
}
function render(){
  const y = window.scrollY;
  const list = $('list'); list.innerHTML = '';
  if (tab === 'story') renderStory(list); else if (tab === 'rules') renderRules(list); else renderPools(list, tab);
  $('count').textContent = '고친 곳 ' + countChanges();
  window.scrollTo(0, y);
}
function renderTabs(){
  $('tabs').innerHTML = '';
  TABS.forEach(([k, n]) => { const b = el('button','tab' + (k === tab ? ' on' : ''), n); b.onclick = () => { tab = k; renderTabs(); render(); window.scrollTo(0,0); }; $('tabs').append(b); });
}
BASE.scenes.filter((s, i, a) => a.findIndex(x => x.world === s.world) === i).forEach(s => { const o = el('option','',s.wname); o.value = s.world; $('world').append(o); });
$('world').onchange = render; $('q').oninput = render;
$('reset').onclick = () => { if (confirm('고친 내용을 전부 지우고 처음 상태로 돌릴까?')) { S = clone(BASE); persist(); render(); } };
$('save').onclick = () => {
  const out = { version: 2, hash: BASE.hash,
    scenes: S.scenes.map(sc => ({ id: sc.id, title: sc.title, lines: sc.lines.map(l => ({ who: l.who, face: l.face, text: l.text })) })),
    pools: Object.fromEntries(S.pools.map(p => [p.base, p.items])),
    singles: Object.fromEntries(S.singles.map(x => [x.key, x.text])),
    rules: Object.fromEntries(S.rules.map(x => [x.key, x.text])) };
  const blob = new Blob([JSON.stringify(out, null, 1)], { type: 'application/json' });
  const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'NIM_대본_수정.json'; a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
};
renderTabs(); render();
</script></body></html>`;
fs.writeFileSync(OUT, html, 'utf8');
console.log('WROTE ' + OUT + ' (' + (html.length / 1024 | 0) + 'KB) hash ' + hash);

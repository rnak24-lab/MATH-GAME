// 이야기 대본 템플릿 생성 / 가져오기
//   node tool/story_template.js export  → 볼트에 NIM_이야기_대본.md (현재 ko 문장으로 채워짐)
//   node tool/story_template.js import  → md 의 문장을 app_strings.dart 의 'ko' 에 반영, 바뀐 키 목록을 tool/story_changed.txt 에 기록
// 규칙: 표의 마지막 칸(문장)만 고치세요. 키 칸은 건드리지 마세요. 문장 안에 | 는 쓰지 마세요.
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const STRINGS = path.join(ROOT, 'lib/l10n/app_strings.dart');
const OUT_MD = 'C:/Users/leeyuseok/Desktop/endolphin/03_프로젝트/NIM_GAME/NIM_이야기_대본.md';
const CHANGED = path.join(__dirname, 'story_changed.txt');

const WORLDS = [
  [1, '등교길', '사탕 · 한 줄 님게임'],
  [2, '점심시간 옥상', '초콜릿 · 두 줄 님게임'],
  [3, '방과후 교실', '쿠키 · 세 줄 님게임'],
  [4, '밤의 도서관', '막대과자 · 쪼개기 게임'],
  [5, '체육관', '마카롱 · 카일즈'],
  [6, '과학실', '도넛 · 위토프'],
  [7, '뒤뜰 토끼장', '젤리 · 피보나치 님'],
  [8, '매점', '춉 (독 초콜릿)'],
  [9, '미술실', '점과 상자'],
  [10, '수학 동아리실', '심 (삼각형 피하기)'],
  [11, '온실', '스프라우트'],
  [12, '보드게임부', '헥스'],
];
// 표정은 코드(lib/l10n/dialogue.dart)에 고정. 대본에는 참고로만 표시.
const FACE = {
  dc: ['자신만만', '미소', '살짝 곤란'],
  a: ['평온', '살짝 곤란'],
  b: ['자신만만', '미소'],
  mid: ['평온', '자신만만', '살짝 곤란', '미소'],
  end: ['평온', '생각 중', '살짝 곤란', '당황', '미소', '활짝'],
};

function readKo() {
  const src = fs.readFileSync(STRINGS, 'utf8').replace(/\r\n/g, '\n');
  const map = {};
  const re = /^    '([A-Za-z0-9_]+)': \{\n([\s\S]*?)^    \},/gm;
  let m;
  while ((m = re.exec(src))) {
    const ko = /^      'ko': '((?:[^'\\]|\\.)*)',/m.exec(m[2]);
    if (ko) map[m[1]] = ko[1].replace(/\\'/g, "'").replace(/\\n/g, '\n').replace(/\\\\/g, '\\');
  }
  return map;
}

function exportMd() {
  const ko = readKo();
  const g = k => (ko[k] ?? '').replace(/\|/g, '｜');
  const L = [];
  L.push('---');
  L.push('작성자: 대표님 (초안: Claude)');
  L.push('용도: 방과후 님게임 이야기 대본. 문장 칸만 고치면 됨.');
  L.push('반영: `node tool/story_template.js import` → ko 반영 + 바뀐 키 목록 → 번역은 Claude 가 이어서');
  L.push('---');
  L.push('');
  L.push('# 방과후 님게임 — 이야기 대본');
  L.push('');
  L.push('## 쓰는 법');
  L.push('- **문장 칸만** 고치세요. 키·표정 칸은 그대로 두세요. (표정은 코드에 고정되어 있고, 바꾸고 싶으면 따로 말씀해 주세요)');
  L.push('- 한 문장은 **60자 안쪽**이 좋습니다. 대화 상자가 세 줄까지 보이고, 그 이상은 잘립니다. 줄바꿈은 안 됩니다.');
  L.push('- 예린 말투: 반말, 무뚝뚝, 속은 따뜻함. 플레이어를 "너"라고 부릅니다. 상표명(브랜드 과자 이름)은 쓰지 마세요.');
  L.push('- 순서: 한마디 3개(클리어마다 번갈아) → 5판째 짧은 이야기 → 10판째 큰 이야기 → 15판째 짧은 이야기 → 20판째 긴 이야기(그 수업 마무리).');
  L.push('- 큰/긴 이야기의 **제목**은 노트 화면에 보입니다.');
  L.push('- 문장 안에 `|` 는 쓰지 마세요.');
  L.push('');
  for (const [n, name, sub] of WORLDS) {
    L.push(`## ${n}. ${name} (${sub})`);
    L.push('');
    L.push('### 클리어 한마디 (3개, 번갈아 나옴)');
    L.push('| 키 | 표정 | 문장 |');
    L.push('|---|---|---|');
    for (let i = 1; i <= 3; i++) L.push(`| dc_w${n}_${i} | ${FACE.dc[i - 1]} | ${g(`dc_w${n}_${i}`)} |`);
    L.push('');
    L.push('### 짧은 이야기 ① — 5판째');
    L.push('| 키 | 표정 | 문장 |');
    L.push('|---|---|---|');
    for (let i = 1; i <= 2; i++) L.push(`| st_w${n}_a_${i} | ${FACE.a[i - 1]} | ${g(`st_w${n}_a_${i}`)} |`);
    L.push('');
    L.push('### 큰 이야기 — 10판째');
    L.push('| 키 | 표정 | 문장 |');
    L.push('|---|---|---|');
    L.push(`| mid_w${n}_title | (제목) | ${g(`mid_w${n}_title`)} |`);
    for (let i = 1; i <= 4; i++) L.push(`| mid_w${n}_${i} | ${FACE.mid[i - 1]} | ${g(`mid_w${n}_${i}`)} |`);
    L.push('');
    L.push('### 짧은 이야기 ② — 15판째');
    L.push('| 키 | 표정 | 문장 |');
    L.push('|---|---|---|');
    for (let i = 1; i <= 2; i++) L.push(`| st_w${n}_b_${i} | ${FACE.b[i - 1]} | ${g(`st_w${n}_b_${i}`)} |`);
    L.push('');
    L.push('### 긴 이야기 — 20판 다 깼을 때');
    L.push('| 키 | 표정 | 문장 |');
    L.push('|---|---|---|');
    L.push(`| end_w${n}_title | (제목) | ${g(`end_w${n}_title`)} |`);
    for (let i = 1; i <= 6; i++) L.push(`| end_w${n}_${i} | ${FACE.end[i - 1]} | ${g(`end_w${n}_${i}`)} |`);
    L.push('');
  }
  L.push('## 그 밖에 예린이 말하는 것 (참고 — 여기서도 고칠 수 있음)');
  L.push('| 키 | 상황 | 문장 |');
  L.push('|---|---|---|');
  const extra = [
    ['midnightGreeting', '홈 화면 인사'], ['turnPlayerFirst', '판 시작'], ['yourTurnNow', '내 차례'],
    ['midnightThinking', '예린 생각 중'], ['midnightLost', '예린이 짐'], ['midnightWon', '예린이 이김'],
    ['midnightWinEarly1', '내가 지고 있을 때 1'], ['midnightWinEarly2', '내가 지고 있을 때 2'], ['midnightWinEarly3', '내가 지고 있을 때 3'],
    ['midnightWinLate1', '계속 지고 있을 때 1'], ['midnightWinLate2', '계속 지고 있을 때 2'], ['midnightWinLate3', '계속 지고 있을 때 3'],
    ['daily_win_1', '오늘의 한 판 승리 1'], ['daily_win_2', '오늘의 한 판 승리 2'], ['daily_win_3', '오늘의 한 판 승리 3'],
    ['simOpening', '심 시작(예린이 먼저 한 줄)'], ['hintLosingRetry', '힌트: 이미 진 판'], ['replayNone', '되감기: 결정적 실수 없음'],
  ];
  for (const [k, sit] of extra) L.push(`| ${k} | ${sit} | ${g(k)} |`);
  L.push('');
  fs.writeFileSync(OUT_MD, L.join('\n'), 'utf8');
  console.log('exported →', OUT_MD);
}

function escKo(v) {
  return v.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$');
}

function importMd() {
  const md = fs.readFileSync(OUT_MD, 'utf8').replace(/\r\n/g, '\n');
  const ko = readKo();
  const raw = fs.readFileSync(STRINGS, 'utf8');
  const crlf = raw.includes('\r\n');
  let src = raw.replace(/\r\n/g, '\n');
  const changed = [];
  const missing = [];
  for (const line of md.split('\n')) {
    const m = /^\|\s*([A-Za-z0-9_]+)\s*\|[^|]*\|\s*(.*?)\s*\|\s*$/.exec(line);
    if (!m || m[1] === '키') continue;
    const key = m[1];
    const text = m[2].replace(/｜/g, '|').trim();
    if (!(key in ko)) { missing.push(key); continue; }
    if (text === ko[key] || text === '') continue;
    const blockRe = new RegExp(`(^    '${key}': \\{\\n[\\s\\S]*?^      'ko': ')((?:[^'\\\\]|\\\\.)*)(',)`, 'm');
    if (!blockRe.test(src)) { missing.push(key); continue; }
    src = src.replace(blockRe, (_, a, __, c) => a + escKo(text) + c);
    changed.push(`${key}\t${text}`);
  }
  fs.writeFileSync(STRINGS, crlf ? src.replace(/\n/g, '\r\n') : src, 'utf8');
  fs.writeFileSync(CHANGED, changed.join('\n') + (changed.length ? '\n' : ''), 'utf8');
  console.log(`changed ${changed.length} keys → ${CHANGED}`);
  if (missing.length) console.log('unknown keys (ignored):', missing.join(', '));
}

const cmd = process.argv[2];
if (cmd === 'export') exportMd();
else if (cmd === 'import') importMd();
else console.log('usage: node tool/story_template.js export|import');

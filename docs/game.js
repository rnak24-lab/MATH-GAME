// ═══════════════════════════════════════════════════════
//  수학 님 게임 - Web Version
//  Flutter 로직을 JavaScript로 포팅
// ═══════════════════════════════════════════════════════

// ─── Save Service (localStorage) ───
const Save = {
  get maxStage() { return parseInt(localStorage.getItem('max_stage') || '0'); },
  set maxStage(v) { if (v > this.maxStage) localStorage.setItem('max_stage', v); },

  get worldUnlocked() { return parseInt(localStorage.getItem('world_unlocked') || '0'); },
  set worldUnlocked(v) { if (v > this.worldUnlocked) localStorage.setItem('world_unlocked', v); },

  get tutorialDone() { return localStorage.getItem('tutorial_done') === 'true'; },
  set tutorialDone(v) { localStorage.setItem('tutorial_done', v); },

  get hintKeys() { return parseInt(localStorage.getItem('hint_keys') || '3'); },
  set hintKeys(v) { localStorage.setItem('hint_keys', v); },

  getWorldClearCount(world) {
    const max = this.maxStage;
    const start = world * 20 + 1;
    const end = (world + 1) * 20;
    if (max < start) return 0;
    if (max >= end) return 20;
    return max - start + 1;
  },

  canUnlockNextWorld(world) { return this.getWorldClearCount(world) >= 3; },
};

// ─── Black Cat Character ───
const Cat = {
  emotions: { happy: '😺', confident: '😼', neutral: '🐱', worried: '🙀', sad: '😿', sleepy: '😸' },
  emotion: 'neutral',
  lastInputTime: Date.now(),
  sleepTimer: null,
  isSleeping: false,

  get emoji() { return this.isSleeping ? '😴' : this.emotions[this.emotion]; },

  resetSleepTimer() {
    this.lastInputTime = Date.now();
    if (this.isSleeping) {
      this.isSleeping = false;
      // 화들짝 깨어남
      this._showAction('❗ *화들짝!*');
    }
    this._startSleepWatch();
  },

  _startSleepWatch() {
    if (this.sleepTimer) clearTimeout(this.sleepTimer);
    this.sleepTimer = setTimeout(() => {
      if (!this.isSleeping) {
        this.isSleeping = true;
        this._showAction('💤 *꾸벅... 꾸벅...*');
        // 10초 후 코골기
        this.sleepTimer = setTimeout(() => {
          if (this.isSleeping) {
            this._showAction('💤💤 *드르렁...*');
          }
        }, 5000);
      }
    }, 5000);
  },

  _showAction(text) {
    const el = document.getElementById('game-dialogue') || document.getElementById('choice-dialogue');
    if (el) el.textContent = text;
    const faceEl = document.getElementById('game-face') || document.getElementById('choice-face');
    if (faceEl) faceEl.textContent = this.emoji;
  },

  updateEmotion({ isCatTurn, catIsWinning, isGameOver, catWon }) {
    if (isGameOver) { this.emotion = catWon ? 'happy' : 'sad'; return; }
    if (isCatTurn) { this.emotion = catIsWinning ? 'confident' : 'worried'; }
    else { this.emotion = catIsWinning ? 'confident' : 'neutral'; }
  },

  getDialogue({ isCatTurn, catIsWinning, isGameOver, catWon, isGameStart }) {
    const pick = arr => arr[Math.floor(Math.random() * arr.length)];

    if (isGameStart) return pick([
      '*꼬리 살랑살랑* 냐~',
      '*앞발로 돌 톡톡* ...!',
      '*눈 반짝* 냐아~',
    ]);
    if (isGameOver) {
      return catWon
        ? pick(['*기지개 쭈욱~* 냐하~', '*앞발 핥기* 당연하지~', '*꼬리 흔들흔들*'])
        : pick(['*시무룩... 등 돌림*', '*꼬리 축...* 냥...', '*귀 쫑긋* ...다음엔!']);
    }
    if (isCatTurn) {
      return catIsWinning
        ? pick(['*눈 반짝반짝* 냐핫!', '*꼬리 흔들* 이거지~', '*의기양양 앞발 핥기*'])
        : pick(['*귀 눕힘* 냥...?', '*꼬리 바닥 탁탁*', '*불안한 눈* ...음냐']);
    }
    return catIsWinning
      ? pick(['*도도하게 앉아서* ...', '*꼬리로 돌 가리킴*', '*하품* 빨리해~'])
      : pick(['*꼬리 살랑*', '*고개 갸웃*', '*앞발 꾹꾹*']);
  },
};

// Backward compat alias
const Sua = Cat;

// ─── Game Modes ───
const MODES = {
  singleRow:  { title: '🪨 한 줄 님게임', desc: '돌 1줄에서 1~k개 가져가기\n마지막 돌을 가져가면 짐!', emoji: '🪨' },
  doubleRow:  { title: '🔮 두 줄 님게임', desc: '돌 2줄에서 한 줄씩 가져가기\n마지막 돌을 가져가면 짐!', emoji: '🔮' },
  pepero:     { title: '🍫 빼빼로 게임', desc: '묶음을 서로 다른 두 수로 나누기\n못 나누면 짐!', emoji: '🍫' },
  tripleRow:  { title: '💎 세 줄 님게임', desc: '돌 3줄에서 한 줄씩 가져가기\n마지막 돌을 가져가면 짐!', emoji: '💎' },
};

const WORLDS = [
  { name: '🌿 초원 마을', color: '#66BB6A', emoji: '🌿' },
  { name: '🌊 바다 왕국', color: '#42A5F5', emoji: '🌊' },
  { name: '🍫 빼빼로 숲', color: '#8D6E63', emoji: '🍫' },
  { name: '💎 수정 궁전', color: '#AB47BC', emoji: '💎' },
  { name: '🐉 드래곤 성', color: '#EF5350', emoji: '🐉' },
];

// ─── Game State ───
function getModeForStage(stage) {
  if (stage <= 20) return 'singleRow';
  if (stage <= 40) return 'doubleRow';
  if (stage <= 60) return 'pepero';
  if (stage <= 80) return 'tripleRow';
  const modes = ['singleRow', 'doubleRow', 'pepero', 'tripleRow'];
  return modes[(stage - 81) % 4];
}

function getWorldForStage(stage) {
  if (stage <= 20) return 0;
  if (stage <= 40) return 1;
  if (stage <= 60) return 2;
  if (stage <= 80) return 3;
  return 4;
}

function createGameState(stageNumber) {
  const mode = getModeForStage(stageNumber);
  const state = { mode, stageNumber, rows: [], maxTake: 3, isPlayerTurn: true, isGameOver: false, playerWon: null };

  switch (mode) {
    case 'singleRow': {
      const n = 5 + (stageNumber - 1) % 16;
      const k = Math.min(Math.max(2 + Math.floor((stageNumber - 1) / 5), 2), 5);
      state.rows = [n];
      state.maxTake = k;
      break;
    }
    case 'doubleRow': {
      const ls = stageNumber <= 40 ? stageNumber - 20 : (stageNumber - 80);
      state.rows = [3 + ls % 8, 2 + (ls + 3) % 7];
      break;
    }
    case 'pepero': {
      const ls = stageNumber <= 60 ? stageNumber - 40 : (stageNumber - 80);
      state.rows = [4 + ls % 12];
      break;
    }
    case 'tripleRow': {
      const ls = stageNumber <= 80 ? stageNumber - 60 : (stageNumber - 80);
      state.rows = [2 + ls % 6, 3 + (ls + 2) % 5, 1 + (ls + 1) % 7];
      break;
    }
  }
  return state;
}

function totalRemaining(state) { return state.rows.reduce((a, b) => a + b, 0); }

function checkGameOver(state) {
  if (state.mode === 'pepero') return state.rows.every(r => r <= 1);
  return totalRemaining(state) === 0;
}

function makeMove(state, rowIndex, count) {
  if (state.isGameOver) return false;
  if (state.mode === 'pepero') return makePeperoMove(state, rowIndex, count);
  if (rowIndex < 0 || rowIndex >= state.rows.length) return false;
  if (count < 1 || count > state.rows[rowIndex]) return false;
  if (state.mode === 'singleRow' && count > state.maxTake) return false;

  state.rows[rowIndex] -= count;
  if (checkGameOver(state)) {
    state.isGameOver = true;
    state.playerWon = !state.isPlayerTurn;
  }
  state.isPlayerTurn = !state.isPlayerTurn;
  return true;
}

function makePeperoMove(state, rowIndex, count) {
  if (rowIndex < 0 || rowIndex >= state.rows.length) return false;
  const original = state.rows[rowIndex];
  const other = original - count;
  if (count <= 0 || other <= 0 || count === other) return false;

  state.rows[rowIndex] = count;
  state.rows.push(other);
  state.rows.sort((a, b) => a - b);
  if (checkGameOver(state)) {
    state.isGameOver = true;
    state.playerWon = !state.isPlayerTurn;
  }
  state.isPlayerTurn = !state.isPlayerTurn;
  return true;
}

// ─── AI Engine ───
const AI = {
  getBestMove(state) {
    switch (state.mode) {
      case 'singleRow': return this._singleRow(state);
      case 'doubleRow':
      case 'tripleRow': return this._multiRow(state);
      case 'pepero': return this._pepero(state);
    }
  },

  _singleRow(state) {
    const n = state.rows[0], k = state.maxTake;
    const rem = (n - 1) % (k + 1);
    if (rem === 0) return { rowIndex: 0, count: 1 };
    return { rowIndex: 0, count: Math.min(Math.max(rem, 1), k) };
  },

  _multiRow(state) {
    const rows = state.rows;
    let nimSum = 0;
    for (const r of rows) nimSum ^= r;

    const allSmall = rows.every(r => r <= 1);
    if (allSmall) {
      const onesCount = rows.filter(r => r === 1).length;
      const idx = rows.findIndex(r => r === 1);
      if (idx < 0) return { rowIndex: 0, count: 1 };
      return { rowIndex: idx, count: 1 };
    }

    if (nimSum === 0) {
      let maxIdx = 0;
      for (let i = 1; i < rows.length; i++) if (rows[i] > rows[maxIdx]) maxIdx = i;
      return { rowIndex: maxIdx, count: 1 };
    }

    for (let i = 0; i < rows.length; i++) {
      const target = rows[i] ^ nimSum;
      if (target < rows[i]) {
        let take = rows[i] - target;
        const remaining = [...rows];
        remaining[i] -= take;
        if (remaining.every(r => r <= 1)) {
          const onesAfter = remaining.filter(r => r === 1).length;
          if (onesAfter % 2 === 0) {
            if (take > 1) take -= 1;
            else if (rows[i] - take - 1 >= 0) take += 1;
          }
        }
        return { rowIndex: i, count: take };
      }
    }
    return { rowIndex: 0, count: 1 };
  },

  _grundyCache: {},
  _peperoGrundy(n) {
    if (n <= 2) return 0;
    if (this._grundyCache[n] !== undefined) return this._grundyCache[n];
    const reachable = new Set();
    for (let a = 1; a < n; a++) {
      const b = n - a;
      if (a < b) reachable.add(this._peperoGrundy(a) ^ this._peperoGrundy(b));
    }
    let mex = 0;
    while (reachable.has(mex)) mex++;
    this._grundyCache[n] = mex;
    return mex;
  },

  _pepero(state) {
    const piles = state.rows;
    let totalG = 0;
    for (const p of piles) totalG ^= this._peperoGrundy(p);

    for (let i = 0; i < piles.length; i++) {
      if (piles[i] <= 2) continue;
      for (let a = 1; a < piles[i]; a++) {
        const b = piles[i] - a;
        if (a >= b) continue;
        const newG = totalG ^ this._peperoGrundy(piles[i]) ^ this._peperoGrundy(a) ^ this._peperoGrundy(b);
        if (newG === 0) return { rowIndex: i, count: a };
      }
    }
    for (let i = 0; i < piles.length; i++) {
      if (piles[i] >= 3) return { rowIndex: i, count: 1 };
    }
    return { rowIndex: 0, count: 1 };
  },

  isAIWinning(state) {
    switch (state.mode) {
      case 'singleRow': {
        const rem = (state.rows[0] - 1) % (state.maxTake + 1);
        return state.isPlayerTurn ? rem === 0 : rem !== 0;
      }
      case 'doubleRow':
      case 'tripleRow': {
        let ns = 0;
        for (const r of state.rows) ns ^= r;
        return state.isPlayerTurn ? ns === 0 : ns !== 0;
      }
      case 'pepero': {
        let tg = 0;
        for (const p of state.rows) tg ^= this._peperoGrundy(p);
        return state.isPlayerTurn ? tg === 0 : tg !== 0;
      }
    }
  },

  getHint(state) {
    const m = this.getBestMove(state);
    switch (state.mode) {
      case 'singleRow': return `${m.count}개를 가져가세요!`;
      case 'doubleRow':
      case 'tripleRow': return `${m.rowIndex + 1}번째 줄에서 ${m.count}개를 가져가세요!`;
      case 'pepero': {
        const pile = state.rows[m.rowIndex];
        return `${pile}을 ${m.count}와 ${pile - m.count}로 나누세요!`;
      }
    }
  },
};

// ─── Tutorial Steps ───
const TUTORIAL_STEPS = [
  { emoji: '🐱', title: '냐~ 반가워!', desc: '이 검은 고양이와 함께\n수학 님(NIM) 게임을 해보자!\n두뇌싸움 준비됐어?' },
  { emoji: '🪨', title: '님 게임이 뭐야?', desc: '돌이 놓여있어.\n번갈아가면서 돌을 가져가는 거야.\n마지막 돌을 가져가는 사람이 지는 거야!' },
  { emoji: '🎯', title: '한 줄 님게임', desc: '돌이 한 줄로 놓여있어.\n한 번에 1~k개까지 가져갈 수 있어.\n마지막 돌을 가져가면 지는 거야!' },
  { emoji: '💡', title: '전략을 세워봐!', desc: '그냥 가져가면 안 돼!\n고양이가 마지막 돌을 가져가도록\n전략적으로 생각해야 해!' },
  { emoji: '🗺️', title: '5개의 월드', desc: '초원 마을 → 바다 왕국 → 빼빼로 숲\n→ 수정 궁전 → 드래곤 성\n\n월드마다 다른 규칙이 있어!' },
  { emoji: '🔑', title: '힌트도 있어!', desc: '어려우면 힌트를 사용해봐!\n최적의 수를 알려줄게.\n라운드당 3번까지 쓸 수 있어!' },
  { emoji: '🐾', title: '자, 시작하자!', desc: '3스테이지를 클리어하면\n다음 월드가 열려!\n\n고양이를 이겨보자! 화이팅!' },
];

// ─── Main Game Controller ───
const Game = {
  state: null,
  currentWorld: 0,
  tutorialStep: 0,
  selectedRowIndex: 0,
  selectedCount: 0,
  selectedPeperoIndex: -1,
  splitValueA: 1,
  hintsUsed: 0,

  // ─── Screen Navigation ───
  showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(`screen-${id}`).classList.add('active');
  },

  goHome() {
    document.getElementById('clear-info').textContent = `클리어: ${Save.maxStage}/100 스테이지`;
    this.showScreen('home');
  },

  goWorld() {
    this.renderWorldList();
    this.showScreen('world');
  },

  goStageSelect() {
    this.renderStageGrid(this.currentWorld);
    this.showScreen('stage');
  },

  // ─── Start ───
  startGame() {
    if (!Save.tutorialDone) {
      this.tutorialStep = 0;
      this.renderTutorial();
      this.showScreen('tutorial');
    } else {
      this.goWorld();
    }
  },

  // ─── Tutorial ───
  renderTutorial() {
    const step = TUTORIAL_STEPS[this.tutorialStep];
    const isLast = this.tutorialStep === TUTORIAL_STEPS.length - 1;

    document.getElementById('tutorial-emoji').textContent = step.emoji;
    document.getElementById('tutorial-title').textContent = step.title;
    document.getElementById('tutorial-desc').textContent = step.desc;

    const nextBtn = document.getElementById('tutorial-next-btn');
    nextBtn.textContent = isLast ? '게임 시작하기!' : '다음';
    nextBtn.className = isLast ? 'btn btn-primary btn-full' : 'btn btn-secondary btn-full';

    document.getElementById('tutorial-skip-btn').style.display = isLast ? 'none' : '';

    // Dots
    const dotsEl = document.getElementById('tutorial-dots');
    dotsEl.innerHTML = TUTORIAL_STEPS.map((_, i) => {
      let cls = 'tutorial-dot';
      if (i === this.tutorialStep) cls += ' active';
      else if (i < this.tutorialStep) cls += ' done';
      return `<div class="${cls}"></div>`;
    }).join('');
  },

  tutorialNext() {
    if (this.tutorialStep < TUTORIAL_STEPS.length - 1) {
      this.tutorialStep++;
      this.renderTutorial();
    } else {
      this.tutorialSkip();
    }
  },

  tutorialSkip() {
    Save.tutorialDone = true;
    this.goWorld();
  },

  // ─── World Select ───
  renderWorldList() {
    const list = document.getElementById('world-list');
    list.innerHTML = WORLDS.map((w, i) => {
      const unlocked = i <= Save.worldUnlocked;
      const clearCount = Save.getWorldClearCount(i);
      return `
        <div class="world-card ${unlocked ? '' : 'locked'}"
             style="${unlocked ? `border-color: ${w.color}; box-shadow: 0 4px 12px ${w.color}33` : ''}"
             onclick="${unlocked ? `Game.openWorld(${i})` : ''}">
          <div class="world-icon" style="background: ${unlocked ? w.color + '33' : '#ccc'}">
            ${unlocked ? w.emoji : '🔒'}
          </div>
          <div class="world-info">
            <h3>${unlocked ? w.name : '??? (잠김)'}</h3>
            <span class="stages-label">스테이지 ${i * 20 + 1}~${(i + 1) * 20}</span>
            <div class="progress-bar">
              <div class="progress-fill" style="width: ${(clearCount / 20) * 100}%; background: ${w.color}"></div>
            </div>
            <div class="world-clear-label" style="color: ${w.color}">${clearCount}/20 클리어</div>
          </div>
          ${unlocked ? '<span class="world-arrow">›</span>' : ''}
        </div>
      `;
    }).join('');
  },

  openWorld(index) {
    this.currentWorld = index;
    this.renderStageGrid(index);
    this.showScreen('stage');
  },

  // ─── Stage Select ───
  renderStageGrid(worldIndex) {
    const w = WORLDS[worldIndex];
    document.getElementById('stage-world-title').textContent = w.name;
    const grid = document.getElementById('stage-grid');
    const start = worldIndex * 20 + 1;

    grid.innerHTML = Array.from({ length: 20 }, (_, i) => {
      const num = start + i;
      const cleared = num <= Save.maxStage;
      const playable = num <= Save.maxStage + 1;
      const mode = getModeForStage(num);
      const modeInfo = MODES[mode];

      let cls = 'stage-cell';
      if (cleared) cls += ' cleared';
      else if (playable) cls += ' playable';
      else cls += ' locked';

      let emoji = '🔒';
      if (cleared) emoji = '⭐';
      else if (playable) emoji = modeInfo.emoji;

      return `
        <div class="${cls}" style="${playable ? `border-color: ${w.color}` : ''}"
             onclick="${playable ? `Game.openStage(${num})` : ''}">
          <span class="emoji">${emoji}</span>
          <span class="num">${num}</span>
        </div>
      `;
    }).join('');
  },

  // ─── Open Stage / Game ───
  openStage(stageNum) {
    this.state = createGameState(stageNum);
    this.selectedRowIndex = 0;
    this.selectedCount = 0;
    this.selectedPeperoIndex = -1;
    this.splitValueA = 1;
    this.hintsUsed = 0;

    Cat.emotion = 'neutral';
    const world = getWorldForStage(stageNum);
    const color = WORLDS[world].color;

    document.getElementById('game-stage-title').textContent = `Stage ${stageNum}`;
    document.getElementById('game-stage-title').style.color = color;

    // Show turn choice
    const dialogue = Cat.getDialogue({ isCatTurn: false, catIsWinning: false, isGameOver: false, catWon: false, isGameStart: true });
    document.getElementById('choice-dialogue').textContent = dialogue;
    document.getElementById('choice-face').textContent = Cat.emoji;

    // Game info card
    const modeInfo = MODES[this.state.mode];
    let detail = '';
    switch (this.state.mode) {
      case 'singleRow': detail = `돌: ${this.state.rows[0]}개 | 최대 ${this.state.maxTake}개 가져가기`; break;
      case 'doubleRow':
      case 'tripleRow': detail = this.state.rows.map((r, i) => `${i + 1}줄: ${r}개`).join(' | '); break;
      case 'pepero': detail = `빼빼로 묶음: ${this.state.rows[0]}개`; break;
    }
    document.getElementById('game-info-card').innerHTML = `
      <h3>${modeInfo.title}</h3>
      <p>${modeInfo.desc}</p>
      <div class="info-detail">${detail}</div>
    `;

    document.getElementById('turn-choice').classList.remove('hidden');
    document.getElementById('game-board').classList.add('hidden');
    document.getElementById('btn-hint').disabled = false;

    this.showScreen('game');
  },

  chooseTurn(playerFirst) {
    this.state.isPlayerTurn = playerFirst;
    document.getElementById('turn-choice').classList.add('hidden');
    document.getElementById('game-board').classList.remove('hidden');

    this.updateCatState();
    this.renderBoard();

    if (!playerFirst) {
      setTimeout(() => this.aiMove(), 1000);
    }
  },

  // ─── Render Board ───
  renderBoard() {
    const s = this.state;
    const boardArea = document.getElementById('board-area');
    const actionArea = document.getElementById('action-area');
    const turnEl = document.getElementById('turn-indicator');

    // Update Cat
    Cat.resetSleepTimer();
    document.getElementById('game-dialogue').textContent = Cat.getDialogue({
      isCatTurn: !s.isPlayerTurn,
      catIsWinning: AI.isAIWinning(s),
      isGameOver: s.isGameOver,
      catWon: s.playerWon === false,
      isGameStart: false,
    });
    document.getElementById('game-face').textContent = Cat.emoji;

    // Turn indicator
    if (s.isGameOver) {
      if (s.playerWon) {
        turnEl.textContent = '🎉 승리!';
        turnEl.className = 'turn-indicator win';
      } else {
        turnEl.textContent = '😢 패배...';
        turnEl.className = 'turn-indicator lose';
      }
    } else if (s.isPlayerTurn) {
      turnEl.textContent = '🎯 내 차례';
      turnEl.className = 'turn-indicator player';
    } else {
      turnEl.textContent = '🐾 고양이 차례';
      turnEl.className = 'turn-indicator ai';
    }

    // Hint button
    document.getElementById('btn-hint').disabled = s.isGameOver || !s.isPlayerTurn || this.hintsUsed >= 3;

    // Board
    if (s.mode === 'pepero') {
      this.renderPeperoBoard(boardArea);
    } else {
      this.renderStoneBoard(boardArea);
    }

    // Actions
    if (s.isGameOver) {
      const winLose = s.playerWon
        ? '<div class="game-over-msg win">🎉 축하해! 고양이를 이겼어!</div>'
        : '<div class="game-over-msg lose">😿 고양이한테 졌다...</div>';
      actionArea.innerHTML = `
        ${winLose}
        <div class="game-over-buttons">
          <button class="btn btn-secondary" onclick="Game.goStageSelect()">돌아가기</button>
          <button class="btn btn-primary" onclick="Game.openStage(${s.stageNumber})">다시 하기</button>
        </div>
      `;
    } else if (s.isPlayerTurn) {
      let btnLabel = '';
      let disabled = true;
      if (s.mode === 'pepero') {
        btnLabel = '나누기!';
        disabled = this.selectedPeperoIndex < 0;
      } else {
        btnLabel = `${this.selectedCount}개 가져가기!`;
        disabled = this.selectedCount <= 0;
      }
      actionArea.innerHTML = `
        <button class="btn btn-primary" style="width:100%" ${disabled ? 'disabled' : ''} onclick="Game.playerMove()">${btnLabel}</button>
      `;
    } else {
      actionArea.innerHTML = '<p style="text-align:center;color:var(--text2);padding:16px">고양이가 생각하는 중... 🐾</p>';
    }
  },

  renderStoneBoard(container) {
    const s = this.state;
    const isInteractive = s.isPlayerTurn && !s.isGameOver;
    const modeEmoji = MODES[s.mode].emoji;

    container.innerHTML = s.rows.map((count, rowIdx) => {
      const showLabel = s.mode !== 'singleRow';
      const selected = rowIdx === this.selectedRowIndex ? this.selectedCount : 0;

      const stones = Array.from({ length: count }, (_, i) => {
        const isSel = isInteractive && i >= (count - selected);
        return `<div class="stone ${isSel ? 'selected' : ''}" onclick="${isInteractive ? `Game.selectStone(${rowIdx}, ${count - i})` : ''}">${modeEmoji}</div>`;
      }).join('');

      return `
        <div class="stone-row ${isInteractive ? 'interactive' : ''}">
          ${showLabel ? `<div class="stone-row-label">${rowIdx + 1}번째 줄</div>` : ''}
          <div class="stones-wrap">${stones}</div>
          <div class="stone-count">${count}개</div>
          ${isInteractive && selected > 0 ? `<div class="stone-selected-info">가져갈 수: <span>${selected}개</span></div>` : ''}
        </div>
      `;
    }).join('');
  },

  renderPeperoBoard(container) {
    const s = this.state;
    const isInteractive = s.isPlayerTurn && !s.isGameOver;

    let html = '<div class="pepero-wrap">';
    html += s.rows.map((size, i) => {
      const canSplit = size >= 3;
      const isSel = i === this.selectedPeperoIndex;
      let cls = 'pepero-pile';
      if (isSel) cls += ' selected';
      if (!canSplit || !isInteractive) cls += ' disabled';

      const items = Array.from({ length: size }, () => '🍫').join('');
      return `
        <div class="${cls}" onclick="${isInteractive && canSplit ? `Game.selectPepero(${i})` : ''}">
          <div class="pepero-items">${items}</div>
          <div class="pepero-label">${size}개</div>
        </div>
      `;
    }).join('');
    html += '</div>';

    // Split slider
    if (this.selectedPeperoIndex >= 0 && this.selectedPeperoIndex < s.rows.length && isInteractive) {
      const pile = s.rows[this.selectedPeperoIndex];
      const maxA = Math.floor(pile / 2);
      const a = this.splitValueA;
      const b = pile - a;

      html += `
        <div class="split-slider-card">
          <h4>${pile}를 어떻게 나눌까?</h4>
          <input type="range" class="split-slider" min="1" max="${maxA}" value="${a}"
                 oninput="Game.updateSplit(parseInt(this.value))">
          <div class="split-result">${a}와 ${b}로 나누기</div>
        </div>
      `;
    }

    container.innerHTML = html;
  },

  // ─── User Interactions ───
  selectStone(rowIndex, count) {
    const s = this.state;
    if (!s.isPlayerTurn || s.isGameOver) return;

    this.selectedRowIndex = rowIndex;
    const maxAllowed = s.mode === 'singleRow' ? s.maxTake : s.rows[rowIndex];
    this.selectedCount = Math.min(Math.max(count, 1), maxAllowed);
    this.renderBoard();
  },

  selectPepero(index) {
    this.selectedPeperoIndex = index;
    this.splitValueA = 1;
    this.renderBoard();
  },

  updateSplit(val) {
    const pile = this.state.rows[this.selectedPeperoIndex];
    if (val !== pile - val) {
      this.splitValueA = val;
    }
    // Update display without full re-render
    const result = document.querySelector('.split-result');
    if (result) result.textContent = `${val}와 ${pile - val}로 나누기`;
  },

  // ─── Player Move ───
  playerMove() {
    const s = this.state;
    let success;

    if (s.mode === 'pepero') {
      success = makeMove(s, this.selectedPeperoIndex, this.splitValueA);
      this.selectedPeperoIndex = -1;
    } else {
      success = makeMove(s, this.selectedRowIndex, this.selectedCount);
      this.selectedCount = 0;
    }

    if (!success) return;

    this.updateCatState();
    this.renderBoard();

    if (s.isGameOver) {
      this.handleGameOver();
    } else {
      setTimeout(() => this.aiMove(), 800 + Math.random() * 400);
    }
  },

  // ─── AI Move ───
  aiMove() {
    const s = this.state;
    if (s.isGameOver) return;

    const move = AI.getBestMove(s);
    makeMove(s, move.rowIndex, move.count);

    this.updateCatState();
    this.renderBoard();

    if (s.isGameOver) {
      this.handleGameOver();
    }
  },

  // ─── Cat State ───
  updateCatState() {
    const s = this.state;
    const catIsWinning = AI.isAIWinning(s);
    Cat.updateEmotion({
      isCatTurn: !s.isPlayerTurn,
      catIsWinning,
      isGameOver: s.isGameOver,
      catWon: s.playerWon === false,
    });
  },

  // ─── Game Over ───
  handleGameOver() {
    const s = this.state;
    if (s.playerWon) {
      Save.maxStage = s.stageNumber;
      const world = getWorldForStage(s.stageNumber);
      if (Save.canUnlockNextWorld(world) && world < 4) {
        Save.worldUnlocked = world + 1;
      }
    }
  },

  // ─── Hint ───
  useHint() {
    if (this.hintsUsed >= 3 || !this.state || this.state.isGameOver || !this.state.isPlayerTurn) return;
    this.hintsUsed++;
    const hint = AI.getHint(this.state);
    document.getElementById('hint-text').textContent = hint;
    document.getElementById('modal-hint').classList.remove('hidden');
    document.getElementById('btn-hint').disabled = this.hintsUsed >= 3;
  },

  closeHint() {
    document.getElementById('modal-hint').classList.add('hidden');
  },
};

// ─── Init ───
document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('clear-info').textContent = `클리어: ${Save.maxStage}/100 스테이지`;
});

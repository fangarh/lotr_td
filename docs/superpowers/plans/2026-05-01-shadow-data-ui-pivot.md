# Shadow Data/UI Pivot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the playable prototype read as Shadow conquest against the Free Peoples by changing data catalogs, campaign wave ids, and UI text while preserving current combat mechanics.

**Architecture:** Keep the pivot data-oriented. `src/gameData.js` remains the catalog source for towers, enemies, campaign levels, and wave ids; `src/gameLogic.js` keeps portable derived rules such as enemy traits; `index.html` and `src/main.js` keep browser UI text. Do not change simulation APIs or renderer drawing functions in this slice.

**Tech Stack:** Static browser app using JavaScript ES modules, Canvas 2D renderer, DOM UI adapter, and Node's built-in `node:test` runner through `npm.cmd test`.

---

## Files And Responsibilities

- Modify `tests/gameLogic.test.mjs`: add failing faction-pivot assertions and update existing tests to use new ids.
- Modify `src/gameData.js`: rename tower families to Shadow-aligned families, replace enemy ids with Free Peoples ids, and update campaign wave entries.
- Modify `src/gameLogic.js`: update `getEnemyTrait` to classify the new enemy ids.
- Modify `index.html`: update title, heading, labels, and static control copy to Shadow conquest language.
- Modify `src/main.js`: update dynamic status/HUD/selection strings to Shadow conquest language.
- Modify `docs/vision.md`, `docs/mechanics.md`, `docs/lore-and-factions.md`, `docs/roadmap.md`, and `docs/changelog.md`: record the completed data/UI pivot and leave renderer/mechanics follow-ups explicit.

Known repository state:
- `D:\Projects\Games\TD` is not a git repository. Do not run commit commands in this workspace.
- Some shell output can show mojibake for Cyrillic; edit files as UTF-8 and preserve existing UTF-8 content.

---

### Task 1: Add Failing Faction Catalog Tests

**Files:**
- Modify: `tests/gameLogic.test.mjs`

- [ ] **Step 1: Import `enemyTypes` into the test file**

Change the top import from:

```js
import { campaignLevels, towerFamilies } from '../src/gameData.js';
```

to:

```js
import { campaignLevels, enemyTypes, towerFamilies } from '../src/gameData.js';
```

- [ ] **Step 2: Add the Shadow tower catalog test**

Insert this test after `tower catalog has 4 families, 5 tiers, and 3 tier-four branches per family`:

```js
test('tower catalog uses Shadow conquest families instead of heroic families', () => {
  const ids = towerFamilies.map((family) => family.id);

  assert.deepEqual(ids, [
    'eye-of-sauron',
    'orc-war-camp',
    'morgul-sorcery',
    'mordor-forge',
  ]);
  assert.equal(ids.some((id) => ['gondor-archer', 'rohan-spear', 'elven-light', 'dwarven-forge'].includes(id)), false);
  assert.deepEqual(
    towerFamilies.map((family) => family.name),
    ['Око Саурона', 'Военный лагерь орков', 'Моргульское колдовство', 'Кузня Мордора']
  );
});
```

- [ ] **Step 3: Add the Free Peoples enemy catalog test**

Insert this test after the Shadow tower catalog test:

```js
test('enemy catalog uses Free Peoples resistance instead of Shadow attackers', () => {
  const ids = Object.keys(enemyTypes);

  assert.deepEqual(ids, [
    'gondor-soldier',
    'hobbit-scout',
    'gondor-guard',
    'rohirrim-rider',
    'dwarf-warrior',
    'dwarven-sapper',
    'elven-warden',
  ]);
  assert.equal(ids.some((id) => ['orc', 'goblin', 'uruk', 'warg', 'troll', 'siege', 'nazgul'].includes(id)), false);
  assert.deepEqual(
    Object.values(enemyTypes).map((enemy) => enemy.name),
    ['Воин Гондора', 'Хоббит-разведчик', 'Страж Гондора', 'Всадник Рохана', 'Воин гномов', 'Гном-сапёр', 'Эльфийский хранитель']
  );
});
```

- [ ] **Step 4: Add the campaign wave id integrity test**

Insert this test after the enemy catalog test:

```js
test('campaign waves reference only defined Free Peoples enemy ids', () => {
  const enemyIds = new Set(Object.keys(enemyTypes));

  for (const level of campaignLevels) {
    for (const waveEntries of level.waves) {
      for (const entry of waveEntries) {
        assert.equal(enemyIds.has(entry.type), true, `${level.name} uses unknown enemy ${entry.type}`);
      }
    }
  }
});
```

- [ ] **Step 5: Run the focused test and verify it fails for the new pivot assertions**

Run:

```powershell
npm.cmd test -- tests\gameLogic.test.mjs
```

Expected: failure showing old ids such as `gondor-archer` or old enemy ids such as `orc` do not match the new expected ids.

If sandbox returns `spawn EPERM`, rerun the same command with escalated permissions.

---

### Task 2: Replace Tower Family Data With Shadow Families

**Files:**
- Modify: `src/gameData.js`
- Modify: `tests/gameLogic.test.mjs`

- [ ] **Step 1: Update tower family ids and primary labels**

In `src/gameData.js`, keep the four existing tower object positions and their numeric stats/costs. Replace only ids, names, short names, descriptions, branch labels, and tier labels according to this mapping:

```js
const towerFamilyIdentityMap = {
  'gondor-archer': {
    id: 'eye-of-sauron',
    name: 'Око Саурона',
    shortName: 'Око',
    description: 'Дальняя магическая башня, отмечающая и сжигающая ключевые цели.',
    attackLabel: 'Всевидящий удар',
    attackDescription: 'Дальняя одиночная атака с усиленным первым попаданием по свежей цели.',
    tiers: ['Тлеющий знак', 'Красный взор', 'Башня наблюдения', 'Пылающее око', 'Воля Саурона'],
    branches: {
      citadel: ['Чёрная цитадель', 'Дозор Барад-дура', 'Неусыпный взор'],
      ranger: ['Ищейки Тени', 'Метка охотника', 'Тропа страха'],
      beacon: ['Сигнальные огни', 'Костёр покорения', 'Пламя Ородруина'],
    },
  },
  'rohan-spear': {
    id: 'orc-war-camp',
    name: 'Военный лагерь орков',
    shortName: 'Орки',
    description: 'Быстрые грубые залпы против лёгких отрядов сопротивления.',
    attackLabel: 'Град чёрных стрел',
    attackDescription: 'Стрелы и копья пробивают цель и ранят врагов рядом по линии дороги.',
    tiers: ['Сторожевой костёр', 'Частокол', 'Лагерь налётчиков', 'Военный вождь', 'Орда Мордора'],
    branches: {
      charge: ['Натиск', 'Рёв варбанды', 'Последний напор'],
      marshal: ['Командиры', 'Знамя Чёрной земли', 'Сбор орды'],
      horsebow: ['Стрелки-налётчики', 'Лёгкие застрельщики', 'Ветер пепла'],
    },
  },
  'elven-light': {
    id: 'morgul-sorcery',
    name: 'Моргульское колдовство',
    shortName: 'Моргул',
    description: 'Проклятия, цепная магия и замедляющий страх.',
    attackLabel: 'Цепь ужаса',
    attackDescription: 'Моргульская сила перескакивает между близкими врагами и усиливает контроль.',
    tiers: ['Зелёный огонь', 'Проклятая печать', 'Круг могил', 'Моргульский алтарь', 'Чёрное дыхание'],
    branches: {
      starlight: ['Призрачный свет', 'Зеркало страха', 'Сияние нежити'],
      roots: ['Порча земли', 'Сплетённые корни', 'Лес под властью Тени'],
      moon: ['Лунная порча', 'Бледные стрелы', 'Дуга мёртвого света'],
    },
  },
  'dwarven-forge': {
    id: 'mordor-forge',
    name: 'Кузня Мордора',
    shortName: 'Кузня',
    description: 'Медленный тяжёлый обстрел, огонь и ударные волны.',
    attackLabel: 'Тяжёлый огонь',
    attackDescription: 'Медленный удар по площади с заметной ударной волной.',
    tiers: ['Угольная яма', 'Железная плавильня', 'Осадный молот', 'Чёрная кузня', 'Сердце Ородруина'],
    branches: {
      mithril: ['Чёрное железо', 'Железный пресс', 'Молот Гронда'],
      magma: ['Магма', 'Жила лавы', 'Печь Роковой горы'],
      rune: ['Руны Тени', 'Рунный резец', 'Синие руны Мордора'],
    },
  },
};
```

Apply each mapping like this:
- object `id`, `name`, `shortName`, and `description` become mapped values.
- `attackProfile.label` and `attackProfile.description` become `attackLabel` and `attackDescription`.
- `tiers[index].name` uses the mapped `tiers[index]`; keep `tier`, `cost`, and `stats`.
- each branch `name` uses tuple item 0, `tier4.name` uses tuple item 1, `tier5.name` uses tuple item 2; keep branch keys, colors, costs, and stats for now.

- [ ] **Step 2: Update test tower ids used by game logic tests**

In `tests/gameLogic.test.mjs`, replace:

```js
createTower('gondor-archer', { x: 2, y: 4 })
createTower('elven-light', { x: 3, y: 3 })
createTower('rohan-spear', { x: 2, y: 2 })
```

with:

```js
createTower('eye-of-sauron', { x: 2, y: 4 })
createTower('morgul-sorcery', { x: 3, y: 3 })
createTower('orc-war-camp', { x: 2, y: 2 })
```

- [ ] **Step 3: Run the focused test and verify remaining failures are enemy/wave related**

Run:

```powershell
npm.cmd test -- tests\gameLogic.test.mjs
```

Expected: tower catalog assertions pass; failures remain for enemy ids, wave references, or `getEnemyTrait`.

---

### Task 3: Replace Enemy Data, Wave Ids, And Enemy Traits

**Files:**
- Modify: `src/gameData.js`
- Modify: `src/gameLogic.js`
- Modify: `tests/gameLogic.test.mjs`

- [ ] **Step 1: Replace `enemyTypes` with Free Peoples ids**

In `src/gameData.js`, replace the whole `enemyTypes` object with:

```js
export const enemyTypes = {
  'gondor-soldier': { name: 'Воин Гондора', hp: 58, speed: 0.74, reward: 8, damage: 1, color: '#9ca3af', size: 0.72 },
  'hobbit-scout': { name: 'Хоббит-разведчик', hp: 38, speed: 1.05, reward: 6, damage: 1, color: '#c8b27a', size: 0.58 },
  'gondor-guard': { name: 'Страж Гондора', hp: 132, speed: 0.62, reward: 14, damage: 2, color: '#d8dde6', size: 0.86 },
  'rohirrim-rider': { name: 'Всадник Рохана', hp: 94, speed: 1.18, reward: 12, damage: 1, color: '#d7b35f', size: 0.82 },
  'dwarf-warrior': { name: 'Воин гномов', hp: 420, speed: 0.42, reward: 35, damage: 4, color: '#b9713f', size: 1.2 },
  'dwarven-sapper': { name: 'Гном-сапёр', hp: 520, speed: 0.36, reward: 42, damage: 5, color: '#8b6f47', size: 1.16 },
  'elven-warden': { name: 'Эльфийский хранитель', hp: 720, speed: 0.82, reward: 70, damage: 7, color: '#bff7e1', size: 1.05 },
};
```

- [ ] **Step 2: Replace wave ids by role**

In `src/gameData.js`, replace wave entry ids using this exact mapping:

```text
goblin -> hobbit-scout
orc -> gondor-soldier
uruk -> gondor-guard
warg -> rohirrim-rider
troll -> dwarf-warrior
siege -> dwarven-sapper
nazgul -> elven-warden
```

Example:

```js
wave([['goblin', 10]])
```

becomes:

```js
wave([['hobbit-scout', 10]])
```

- [ ] **Step 3: Update `getEnemyTrait` for Free Peoples ids**

In `src/gameLogic.js`, replace the current `getEnemyTrait` body with:

```js
export function getEnemyTrait(type, campaignLevel) {
  if (type === 'elven-warden' || type === 'dwarf-warrior') {
    return { kind: 'boss', label: 'Лидер', color: '#d45f4c' };
  }
  if (type === 'dwarven-sapper') {
    return { kind: 'siege', label: 'Сапёр', color: '#d8ad45' };
  }
  if ((type === 'gondor-guard' || type === 'rohirrim-rider') && campaignLevel >= 7) {
    return { kind: 'elite', label: 'Элита', color: '#c6a4ff' };
  }
  if (type === 'hobbit-scout') {
    return { kind: 'swarm', label: 'Разведка', color: '#8fd694' };
  }
  return { kind: 'standard', label: '', color: '#b9b29e' };
}
```

- [ ] **Step 4: Update the enemy trait test**

In `tests/gameLogic.test.mjs`, replace the body of `enemy traits describe encounter roles by type and campaign level` with:

```js
assert.equal(getEnemyTrait('hobbit-scout', 2).kind, 'swarm');
assert.equal(getEnemyTrait('gondor-soldier', 2).kind, 'standard');
assert.equal(getEnemyTrait('gondor-guard', 7).kind, 'elite');
assert.equal(getEnemyTrait('rohirrim-rider', 7).kind, 'elite');
assert.equal(getEnemyTrait('dwarven-sapper', 8).kind, 'siege');
assert.equal(getEnemyTrait('dwarf-warrior', 9).kind, 'boss');
assert.equal(getEnemyTrait('elven-warden', 9).kind, 'boss');
```

- [ ] **Step 5: Run the focused test and verify it passes**

Run:

```powershell
npm.cmd test -- tests\gameLogic.test.mjs
```

Expected: all `tests/gameLogic.test.mjs` tests pass.

---

### Task 4: Update Campaign And UI Framing Text

**Files:**
- Modify: `src/gameData.js`
- Modify: `index.html`
- Modify: `src/main.js`

- [ ] **Step 1: Rename campaign level names in `src/gameData.js`**

Keep level ids, themes, path data, gold, lives, and waves. Replace only `name` strings:

```js
[
  'Тень у Бри',
  'Дорога к Ривенделлу',
  'Перевал Карадрас',
  'Врата Мории',
  'Порча Лориэна',
  'Броды Изена',
  'Осада Хельмовой Пади',
  'Поля Пеленнора',
  'Перевал Кирит Унгол',
  'Чёрные врата',
]
```

Use the names in order for levels 1 through 10.

- [ ] **Step 2: Update static HTML text in `index.html`**

Replace static UI copy with these strings:

```html
<title>Тень над Средиземьем</title>
<section class="stage" aria-label="Поле завоевания">
<p class="eyebrow">Завоевание</p>
<h1>Поход Тени</h1>
<div id="status" class="status">Выбери оплот Тени и закрепись на свободной земле.</div>
<span><strong id="gold">0</strong> золото</span>
<span><strong id="lives">0</strong> воля</span>
<span><strong id="wave">0/0</strong> натиск</span>
<span><strong id="unlock">II</strong> предел</span>
<span>Регион кампании</span>
<div class="section-title">Оплоты</div>
<button id="startWave" class="primary" aria-label="Начать натиск" data-tooltip="Вызвать следующую волну сопротивления.">Начать натиск</button>
<button id="restart" class="secondary" aria-label="Переиграть регион" data-tooltip="Начать выбранный регион заново без изменения сохранённого прогресса.">Переиграть регион</button>
<div class="section-title">Тестер</div>
<button id="testerUnlockAll" type="button" data-tooltip="Открывает все регионы и все ветки усилений для текущей сессии.">Открыть всё</button>
<button id="testerAddGold" type="button" data-tooltip="Добавляет 1000 золота на текущий регион.">+1000 золота</button>
<button id="testerAddWaves" type="button" data-tooltip="Добавляет две повторные волны к текущему региону.">+2 волны</button>
<button id="testerInfiniteGold" type="button" aria-pressed="false" data-tooltip="Оплоты и усиления перестают тратить золото.">Деньги: обычные</button>
<div id="testerStatus" class="tester-status">Тест: кампания · волн 0</div>
<div class="section-title">Выбранный объект</div>
<div id="selection" class="selection">Клетка не выбрана.</div>
```

Keep all existing element ids, classes, script tag, stylesheet link, and button structure.

- [ ] **Step 3: Update dynamic strings in `src/main.js`**

Replace the dynamic status and HUD strings with the following exact Russian copy:

```js
setStatus(`Выбран оплот: ${family.name}.`);
campaignProgressHtml: `<strong>${completedCount}/${campaignLevels.length}</strong> регионов подавлено<br>Открыт путь до региона ${highestUnlocked}; предел оплотов: ${unlockedUpgradeTier}<br>Прогресс сохраняется в браузере.`,
infiniteGoldText: state.testerInfiniteGold ? 'Деньги: ∞' : 'Деньги: обычные',
testerStatusText: `Тест: ${state.testerAllUpgrades ? 'все усиления' : 'кампания'} · волн ${currentLevel().waves.length}`,
setStatus(`Натиск ${state.waveIndex + 1}: сопротивление выходит на дорогу.`);
setStatus('Тестер: открыты все регионы и ветки усилений.');
setStatus('Тестер: добавлено 1000 золота.');
setStatus('Тестер: добавлены 2 дополнительные волны на текущий регион.');
setStatus(state.testerInfiniteGold ? 'Тестер: золото больше не тратится.' : 'Тестер: обычный расход золота включён.');
setStatus(`Нужно ${family.baseCost} золота для ${family.name}.`);
setStatus(`${family.name} возведён.`);
contentHtml: `<strong>Клетка ${selectedTile.x}:${selectedTile.y}</strong><br>${placement.ok ? 'Можно возвести оплот.' : placement.reason}`,
contentText: 'Клетка не выбрана.',
upgradeNoteText: options.length === 0
  ? tower.tier >= 5 ? 'Оплот достиг максимума.' : 'Следующая ступень ещё закрыта кампанией.'
  : '',
text: `Разобрать за ${getTowerSellValue(tower)}`,
setStatus(`Не хватает золота: нужно ${option.cost}.`);
setStatus(`Усилено: ${option.name}.`);
setStatus('Оплот разобран.');
setStatus('Сопротивление прорвалось. Перезапусти регион и измени построение.');
setStatus('Сопротивление подавлено. Можно возводить и усиливать оплоты.');
setStatus(next ? `Регион покорён. Открыт путь: ${next.name}.` : 'Кампания завершена. Чёрные врата удержаны, Средиземье склоняется перед Тенью.');
```

Apply these replacements at the existing call sites. Preserve function names and control flow.

- [ ] **Step 4: Run full tests**

Run:

```powershell
npm.cmd test
```

Expected: all tests pass. There may be no test coverage for copy-only changes; visual inspection comes after docs if the text changed enough to risk layout.

---

### Task 5: Update Obsidian Notes

**Files:**
- Modify: `docs/vision.md`
- Modify: `docs/mechanics.md`
- Modify: `docs/lore-and-factions.md`
- Modify: `docs/roadmap.md`
- Modify: `docs/changelog.md`

- [ ] **Step 1: Update `docs/vision.md` implementation status**

Replace the current caveat that says code still uses heroic tower families and Shadow/Mordor enemies with:

```markdown
## Current Implementation Status

The first Shadow conquest data/UI pivot is complete.

Current playable content now uses:
- player tower families themed around the Eye of Sauron, Orc war camps, Morgul sorcery, and Mordor forges;
- enemy types themed around Free Peoples resistance: Men, Hobbits, Rohirrim, Dwarves, and Elves;
- campaign and UI language focused on Shadow conquest.

Remaining temporary content:
- canvas tower silhouettes still reuse older heroic renderer functions;
- tower attacks and balance still mostly preserve the pre-pivot prototype roles;
- terrain corruption is not yet a gameplay or full visual system.
```

- [ ] **Step 2: Update `docs/mechanics.md` current implementation caveat**

Replace the old tower/enemy caveat bullets with:

```markdown
Current implementation caveat:
- Tower and enemy catalogs have completed the first Shadow data/UI pivot.
- Tower behavior still preserves the pre-pivot prototype roles: precision, pierce, chain, and bombard.
- Obstacle towers are not implemented yet.
- Detailed dark tower visuals are deferred to the dark tower visual pass.
```

- [ ] **Step 3: Update `docs/lore-and-factions.md` implementation status**

Set player and enemy implementation status paragraphs to:

```markdown
Implementation status: the first playable catalog now follows this direction. Current player towers are Eye of Sauron, Orc War Camp, Morgul Sorcery, and Mordor Forge families. Detailed visuals and final branch names can still change during the dark tower visual and mechanics passes.
```

and:

```markdown
Implementation status: the first playable enemy catalog now uses Free Peoples resistance roles: Gondor soldiers and guards, Hobbits, Rohirrim, Dwarves, Dwarven sappers, and Elven wardens. Stats still reuse the old role structure until balance work resumes.
```

- [ ] **Step 4: Update `docs/roadmap.md` faction pivot section**

Change the first faction-pivot bullets to:

```markdown
2. Faction pivot.
   - Rename UI and campaign framing from defense of Middle-earth to conquest by Shadow. Done for the first data/UI slice.
   - Replace enemy catalog with Free Peoples. Done for the first data/UI slice.
   - Replace tower families with dark factions and structures. Done for the first data/UI slice.
   - Next: dark tower visual pass and later obstacle mechanics.
```

- [ ] **Step 5: Add a changelog entry**

At the top of `docs/changelog.md` under `## 2026-05-01`, add:

```markdown
- Completed the first Shadow data/UI pivot: tower families now use Shadow structures, enemy types now represent Free Peoples resistance, campaign waves use the new ids, and UI text frames play as conquest by Shadow while preserving current combat mechanics.
```

- [ ] **Step 6: Run stale-note scan**

Run:

```powershell
rg -n "has not fully migrated|Current code still uses|temporary prototype content|Gondor Archer|Rohan Spear|Elven Light|Dwarven Forge|Orc, Goblin|Nazgul-like" docs
```

Expected: no active project-source notes still claim the data/UI catalog is unpivoted. Historical specs under `docs/superpowers/specs/2026-04-30-isometric-middle-earth-td-design.md` may still contain old design names; do not rewrite history unless the search points at current source-of-truth notes.

---

### Task 6: Final Verification And Optional Browser QA

**Files:**
- Verify: all modified files

- [ ] **Step 1: Run full automated verification**

Run:

```powershell
npm.cmd test
```

Expected: `# fail 0` and all tests pass.

- [ ] **Step 2: Search for old runtime ids in active source**

Run:

```powershell
rg -n "gondor-archer|rohan-spear|elven-light|dwarven-forge|\\borc\\b|\\bgoblin\\b|\\buruk\\b|\\bwarg\\b|\\btroll\\b|\\bsiege\\b|\\bnazgul\\b" src tests index.html
```

Expected:
- no old tower family ids in `src/gameData.js`, `src/main.js`, or tests;
- no old enemy ids in `src/gameData.js`, `src/main.js`, or tests;
- renderer function names such as `drawGondorTower` may remain in `src/renderer.js` because renderer redesign is outside this slice.

- [ ] **Step 3: Decide on browser QA**

If `index.html` or `src/main.js` text changes cause layout concerns, run a local static server or existing app command and inspect the UI in browser. For this static app, a simple browser load of `index.html` is enough if local file access works.

Expected visual check:
- heading reads as Shadow conquest;
- panel labels fit in the right panel;
- tower button names fit without obvious overflow;
- status text does not overlap the canvas or panel.

- [ ] **Step 4: Final response checklist**

Report:
- changed files;
- tests run and pass/fail count;
- whether browser QA was run;
- that renderer art is intentionally unchanged;
- that docs were updated.

Do not claim completion if `npm.cmd test` has not passed after the final docs update.

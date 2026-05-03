import { campaignLevels, enemyTypes, towerFamilies } from './gameData.js';
import {
  baseTileSize,
  clampCamera as clampCameraValue,
  getObjectScale,
  getOrigin,
  getScaledTileSize,
  getViewScale,
  getVisibleTileBounds,
  pickTileAt,
  projectTile,
} from './camera.js';
import { createAudio } from './audio.js';
import { createRenderer } from './renderer.js';
import {
  loadCampaignProgress,
  loadSoundPreference,
  saveCampaignProgress,
  saveSoundPreference,
} from './storage.js';
import { attachInputHandlers } from './input.js';
import {
  createEnemy,
  getTowerSellValue,
  placeTower as placeSimulationTower,
  sellTower as sellSimulationTower,
  upgradeTower as upgradeSimulationTower,
  updateEffects,
  updateEnemies,
  updateOutcome,
  updateProjectiles,
  updateSpawning,
  updateTowers as updateSimulationTowers,
} from './simulation.js';
import { createUi } from './ui.js';
import {
  applyUpgrade,
  canPlaceTower,
  completeCampaignLevel,
  createDefaultProgress,
  createTesterProgress,
  createTower,
  extendWavesForTesting,
  getAvailableUpgrades,
  getEnemyTrait,
  getHighestUnlockedLevel,
  getLevelPresentation,
  getTowerAttackProfile,
  getTowerFamily,
  getTowerStats,
  getTowerTierDefinition,
  getUnlockedUpgradeTier,
  isLevelUnlocked,
  sameTile,
  tileKey,
} from './gameLogic.js';

const canvas = document.querySelector('#game');
const ctx = canvas.getContext('2d');
const levelSelect = document.querySelector('#levelSelect');
const towerButtons = document.querySelector('#towerButtons');
const upgradeButtons = document.querySelector('#upgradeButtons');
const selectionBox = document.querySelector('#selection');
const startWaveButton = document.querySelector('#startWave');
const restartButton = document.querySelector('#restart');
const statusBox = document.querySelector('#status');
const goldEl = document.querySelector('#gold');
const livesEl = document.querySelector('#lives');
const waveEl = document.querySelector('#wave');
const unlockEl = document.querySelector('#unlock');
const campaignProgressEl = document.querySelector('#campaignProgress');
const soundToggleButton = document.querySelector('#soundToggle');
const unlockAllButton = document.querySelector('#testerUnlockAll');
const addGoldButton = document.querySelector('#testerAddGold');
const addWavesButton = document.querySelector('#testerAddWaves');
const infiniteGoldButton = document.querySelector('#testerInfiniteGold');
const testerStatusEl = document.querySelector('#testerStatus');

let origin = { x: 520, y: 145 };
let camera = { x: 0, y: 0 };
let viewScale = 1;
let lastTime = performance.now();
let selectedTowerType = towerFamilies[0].id;
let selectedTile = null;
let selectedTowerId = null;
let hoverTile = null;
let nextEnemyId = 1;

const state = {
  levelIndex: 0,
  gold: 0,
  lives: 0,
  towers: [],
  enemies: [],
  projectiles: [],
  effects: [],
  waveIndex: 0,
  spawnQueue: [],
  spawnTimer: 0,
  runningWave: false,
  message: '',
  outcome: 'playing',
  progress: createDefaultProgress(),
  soundEnabled: false,
  clock: 0,
  testerAllUpgrades: false,
  testerInfiniteGold: false,
  testerWaveOverrides: new Map(),
};

const renderer = createRenderer({
  ctx,
  getViewport: () => canvas.getBoundingClientRect(),
  getCurrentLevel: currentLevel,
  getCameraView: cameraView,
  getRenderState: () => state,
  getLevelPresentation,
  getVisibleTileBounds,
  tileKey,
  sameTile,
  getSelectedTile: () => selectedTile,
  getSelectedTowerId: () => selectedTowerId,
  getHoverTile: () => hoverTile,
  getSelectedTowerType: () => selectedTowerType,
  getTowerAt,
  getTowerFamily,
  getTowerAttackProfile,
  canPlaceTower,
  project,
  getObjectScale: objectScale,
  getScaledTileSize: scaledTileSize,
});

const ui = createUi({
  levelSelect,
  towerButtons,
  upgradeButtons,
  selectionBox,
  soundToggleButton,
  goldEl,
  livesEl,
  waveEl,
  unlockEl,
  campaignProgressEl,
  startWaveButton,
  statusBox,
  infiniteGoldButton,
  testerStatusEl,
  getSoundEnabled: () => state.soundEnabled,
});

const audio = createAudio({
  getSoundEnabled: () => state.soundEnabled,
  getWindow: () => window,
});

function init() {
  state.progress = loadCampaignProgress(localStorage, campaignLevels);
  state.soundEnabled = loadSoundPreference(localStorage);
  renderLevelSelect();
  renderTowerButtons();
  attachEvents();
  ui.syncSoundToggle();
  resize();
  resetLevel(0);
  requestAnimationFrame(loop);
}

function attachEvents() {
  attachInputHandlers({
    targetWindow: window,
    canvas,
    controls: {
      levelSelect,
      startWaveButton,
      restartButton,
      soundToggleButton,
      unlockAllButton,
      addGoldButton,
      addWavesButton,
      infiniteGoldButton,
    },
    onResize: resize,
    onLevelChange: selectLevelById,
    onStartWave: startNextWave,
    onRestart: () => resetLevel(state.levelIndex),
    onToggleSound: toggleSound,
    onUnlockTesterCampaign: unlockTesterCampaign,
    onAddTesterGold: addTesterGold,
    onAddTesterWaves: addTesterWaves,
    onToggleTesterInfiniteGold: toggleTesterInfiniteGold,
    onPan: panCameraBy,
    onHover: updateHoverFromEvent,
    onHoverClear: clearHover,
    onCanvasClick: handleCanvasClick,
  });
}

function selectLevelById(id) {
  if (!isLevelUnlocked(state.progress, id)) {
    renderLevelSelect();
    setStatus('Этот путь ещё закрыт. Подави предыдущий регион кампании.');
    return;
  }
  resetLevel(campaignLevels.findIndex((level) => level.id === id));
}

function panCameraBy({ dx, dy }) {
  camera.x += dx;
  camera.y += dy;
  clampCamera();
}

function updateHoverFromEvent(event) {
  hoverTile = pickTile(event);
}

function clearHover() {
  hoverTile = null;
}

function handleCanvasClick(event) {
  const tile = pickTile(event);
  if (!tile) return;

  const tower = getTowerAt(tile);
  selectedTile = tile;

  if (tower) {
    selectedTowerId = tower.id;
    setStatus(`${tower.name}: ступень ${tower.tier}.`);
    renderSelection();
    return;
  }

  selectedTowerId = null;
  placeTower(tile);
  renderSelection();
}

function resize() {
  const rect = canvas.getBoundingClientRect();
  const dpr = Math.max(1, window.devicePixelRatio || 1);
  canvas.width = Math.floor(rect.width * dpr);
  canvas.height = Math.floor(rect.height * dpr);
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

  const level = currentLevel();
  viewScale = getViewScale({ viewport: rect, map: level });
  origin = getOrigin({ viewport: rect, map: level, tileSize: scaledTileSize() });
  clampCamera();
}

function resetLevel(index) {
  const requestedIndex = Math.max(0, index);
  const requestedLevel = campaignLevels[requestedIndex] ?? campaignLevels[0];
  state.levelIndex = isLevelUnlocked(state.progress, requestedLevel.id) ? requestedIndex : 0;
  const level = currentLevel();
  state.gold = level.startingGold;
  state.lives = level.lives;
  state.towers = [];
  state.enemies = [];
  state.projectiles = [];
  state.effects = [];
  state.waveIndex = 0;
  state.spawnQueue = [];
  state.spawnTimer = 0;
  state.runningWave = false;
  state.outcome = 'playing';
  selectedTile = null;
  selectedTowerId = null;
  camera = { x: 0, y: 0 };
  nextEnemyId = 1;
  renderLevelSelect();
  resize();
  setStatus(`${level.name}: выбери оплот Тени и закрепись на земле.`);
  syncHud();
  syncTesterHud();
  renderSelection();
}

function renderLevelSelect() {
  ui.renderLevelSelect(getLevelSelectViewModel());
}

function getLevelSelectViewModel() {
  return {
    selectedLevelId: String(currentLevel().id),
    levels: campaignLevels.map((level) => {
      const completed = state.progress.completedLevelIds.includes(level.id);
      const unlocked = isLevelUnlocked(state.progress, level.id);
      return {
        value: String(level.id),
        disabled: !unlocked,
        label: `${level.id}. ${level.name}${completed ? ' - пройдено' : unlocked ? '' : ' - закрыто'}`,
      };
    }),
  };
}

function saveProgress() {
  if (!saveCampaignProgress(localStorage, state.progress)) {
    setStatus('Прогресс открыт в этой сессии, но браузер не дал сохранить кампанию.');
  }
}

function saveSoundPreferenceState() {
  saveSoundPreference(localStorage, state.soundEnabled);
}

function toggleSound() {
  state.soundEnabled = !state.soundEnabled;
  saveSoundPreferenceState();
  ui.syncSoundToggle();
  if (state.soundEnabled) {
    playSound('toggle');
  }
}

function currentLevel() {
  const level = campaignLevels[state.levelIndex];
  return {
    ...level,
    waves: state.testerWaveOverrides.get(level.id) ?? level.waves,
  };
}

function renderTowerButtons() {
  ui.renderTowerButtons({
    towers: getTowerButtonViewModels(),
    onSelectTower: selectTowerType,
  });
}

function getTowerButtonViewModels() {
  return towerFamilies.map((family) => ({
    id: family.id,
    name: family.name,
    shortName: family.shortName,
    description: family.description,
    baseCost: family.baseCost,
    active: family.id === selectedTowerType,
  }));
}

function selectTowerType(towerType) {
  const family = getTowerFamily(towerType);
  if (!family) {
    return;
  }

  selectedTowerType = family.id;
  selectedTowerId = null;
  renderTowerButtons();
  renderSelection();
  setStatus(`Выбран оплот: ${family.name}.`);
}

function syncHud() {
  ui.syncHud(getHudViewModel());
}

function getHudViewModel() {
  const level = currentLevel();
  const completedCount = state.progress.completedLevelIds.length;
  const highestUnlocked = getHighestUnlockedLevel(state.progress);
  const unlockedUpgradeTier = roman(getUnlockedUpgradeTier(effectiveUpgradeLevel()));

  return {
    goldText: state.testerInfiniteGold ? '∞' : String(state.gold),
    livesText: String(state.lives),
    waveText: `${Math.min(state.waveIndex + (state.runningWave ? 1 : 0), level.waves.length)}/${level.waves.length}`,
    unlockText: unlockedUpgradeTier,
    campaignProgressHtml: `<strong>${completedCount}/${campaignLevels.length}</strong> регионов подавлено<br>Открыт путь до региона ${highestUnlocked}; предел оплотов: ${unlockedUpgradeTier}<br>Прогресс сохраняется в браузере.`,
    startWaveDisabled: state.runningWave || state.outcome !== 'playing' || state.waveIndex >= level.waves.length,
  };
}

function syncTesterHud() {
  ui.syncTesterHud(getTesterHudViewModel());
}

function getTesterHudViewModel() {
  return {
    infiniteGoldPressed: state.testerInfiniteGold,
    infiniteGoldText: state.testerInfiniteGold ? 'Деньги: ∞' : 'Деньги: обычные',
    testerStatusText: `Тест: ${state.testerAllUpgrades ? 'все усиления' : 'кампания'} · волн ${currentLevel().waves.length}`,
  };
}

function startNextWave() {
  if (state.runningWave || state.outcome !== 'playing') return;
  const level = currentLevel();
  const wave = level.waves[state.waveIndex];
  if (!wave) return;

  state.spawnQueue = wave.flatMap((entry) =>
    Array.from({ length: entry.count }, () => ({ type: entry.type, delay: entry.delay }))
  );
  state.spawnTimer = 0;
  state.runningWave = true;
  playSound('wave');
  setStatus(`Натиск ${state.waveIndex + 1}: сопротивление выходит на дорогу.`);
  syncHud();
}

function unlockTesterCampaign() {
  state.progress = createTesterProgress(campaignLevels);
  state.testerAllUpgrades = true;
  saveProgress();
  renderLevelSelect();
  setStatus('Тестер: открыты все регионы и ветки усилений.');
  syncHud();
  syncTesterHud();
  renderSelection();
}

function addTesterGold() {
  state.gold += 1000;
  setStatus('Тестер: добавлено 1000 золота.');
  syncHud();
  syncTesterHud();
}

function addTesterWaves() {
  const baseLevel = campaignLevels[state.levelIndex];
  const currentWaves = currentLevel().waves;
  state.testerWaveOverrides.set(baseLevel.id, extendWavesForTesting({ ...baseLevel, waves: currentWaves }, 2));
  setStatus('Тестер: добавлены 2 дополнительные волны на текущий регион.');
  syncHud();
  syncTesterHud();
}

function toggleTesterInfiniteGold() {
  state.testerInfiniteGold = !state.testerInfiniteGold;
  setStatus(state.testerInfiniteGold ? 'Тестер: золото больше не тратится.' : 'Тестер: обычный расход золота включён.');
  syncHud();
  syncTesterHud();
}

function placeTower(tile) {
  const placement = placeSimulationTower(state, tile, {
    level: currentLevel(),
    towerTypeId: selectedTowerType,
    getTowerFamily,
    canPlaceTower,
    createTower,
  });

  if (placement.kind === 'invalid-placement') {
    setStatus(placement.reason);
    return;
  }

  const { family } = placement;
  if (placement.kind === 'unaffordable') {
    setStatus(`Нужно ${family.baseCost} золота для ${family.name}.`);
    return;
  }

  selectedTowerId = placement.tower.id;
  playSound('build');
  setStatus(`${family.name} возведён.`);
  syncHud();
}

function effectiveUpgradeLevel() {
  return state.testerAllUpgrades ? campaignLevels.at(-1).id : currentLevel().id;
}

function renderSelection() {
  ui.renderSelection(getSelectionViewModel(), {
    onUpgradeTower: upgradeTower,
    onSellTower: sellTower,
  });
}

function getSelectionViewModel() {
  const tower = selectedTower();

  if (tower) {
    const family = getTowerFamily(tower.typeId);
    const attackProfile = getTowerAttackProfile(tower.typeId);
    const stats = getTowerStats(tower);
    const tier = getTowerTierDefinition(tower);
    const branch = tower.branchId ? family.branches[tower.branchId] : null;
    const options = getAvailableUpgrades(tower, effectiveUpgradeLevel());
    return {
      contentHtml: `
        <strong>${family.name}</strong><br>
        ${tier.name}${branch ? ` · ${branch.name}` : ''}<br>
        ${attackProfile.label}: ${attackProfile.description}<br>
        Ступень ${tower.tier} · урон ${stats.damage} · дальность ${stats.range} · темп ${stats.fireRate}/с
      `,
      upgradeNoteText: options.length === 0
        ? tower.tier >= 5 ? 'Оплот достиг максимума.' : 'Следующая ступень ещё закрыта кампанией.'
        : '',
      upgrades: options.map((option) => ({
        towerId: tower.id,
        payload: option,
        name: option.name,
        branchName: option.branchName,
        cost: option.cost,
        damage: option.stats.damage,
        range: option.stats.range,
      })),
      sell: {
        towerId: tower.id,
        text: `Разобрать за ${getTowerSellValue(tower)}`,
      },
    };
  }

  if (selectedTile) {
    const placement = canPlaceTower(selectedTile, currentLevel(), state.towers);
    return {
      contentHtml: `<strong>Клетка ${selectedTile.x}:${selectedTile.y}</strong><br>${placement.ok ? 'Можно возвести оплот.' : placement.reason}`,
      upgrades: [],
      sell: null,
    };
  }

  return {
    contentText: 'Клетка не выбрана.',
    upgrades: [],
    sell: null,
  };
}

function upgradeTower(towerId, option) {
  const result = upgradeSimulationTower(state, towerId, option, {
    applyUpgrade,
    getTowerFamily,
  });

  if (result.kind === 'tower-not-found') return;
  if (result.kind === 'unaffordable') {
    setStatus(`Не хватает золота: нужно ${option.cost}.`);
    return;
  }

  selectedTowerId = result.tower.id;
  playSound('upgrade');
  setStatus(`Усилено: ${option.name}.`);
  syncHud();
  renderSelection();
}

function sellTower(towerId) {
  const result = sellSimulationTower(state, towerId);
  if (result.kind === 'tower-not-found') return;

  selectedTowerId = null;
  setStatus('Оплот разобран.');
  syncHud();
  renderSelection();
}

function update(dt) {
  if (state.outcome !== 'playing') return;
  state.clock += dt;
  updateSpawning(state, dt, spawnEnemy);
  updateEnemies(state, currentLevel(), dt, () => playSound('breach'));
  updateSimulationTowers(state, dt, {
    getTowerStats,
    getTowerFamily,
    getTowerAttackProfile,
    onKill: (enemy) => {
      playSound(enemy.trait.kind === 'boss' ? 'bossDown' : 'kill');
    },
  });
  updateProjectiles(state, dt);
  updateEffects(state, dt);
  updateOutcome(state, {
    level: currentLevel(),
    campaignLevels,
    completeCampaignLevel,
    onLost: () => {
      playSound('lost');
      setStatus('Сопротивление прорвалось. Перезапусти регион и измени построение.');
    },
    onWaveCleared: () => {
      setStatus('Сопротивление подавлено. Можно возводить и усиливать оплоты.');
    },
    onLevelWon: ({ next, nextLevelIndex }) => {
      saveProgress();
      renderLevelSelect();
      playSound('victory');
      setStatus(next ? `Регион покорён. Открыт путь: ${next.name}.` : 'Кампания завершена. Чёрные врата удержаны, Средиземье склоняется перед Тенью.');
      if (next) {
        setTimeout(() => resetLevel(nextLevelIndex), 1600);
      }
    },
  });
  syncHud();
}

function spawnEnemy(type) {
  const level = currentLevel();
  const base = enemyTypes[type];
  const trait = getEnemyTrait(type, level.id);
  state.enemies.push(createEnemy({
    id: nextEnemyId++,
    type,
    base,
    trait,
    level,
  }));
}

function loop(time) {
  const dt = Math.min(0.05, (time - lastTime) / 1000);
  lastTime = time;
  update(dt);
  renderer.draw();
  requestAnimationFrame(loop);
}

function pickTile(event) {
  const rect = canvas.getBoundingClientRect();
  return pickTileAt({ x: event.clientX - rect.left, y: event.clientY - rect.top }, currentLevel(), cameraView());
}

function getTowerAt(tile) {
  return state.towers.find((tower) => sameTile(tower.tile, tile)) ?? null;
}

function selectedTower() {
  return state.towers.find((tower) => tower.id === selectedTowerId) ?? null;
}

function project(x, y) {
  return projectTile({ x, y }, cameraView());
}

function clampCamera() {
  const rect = canvas.getBoundingClientRect();
  camera = clampCameraValue(camera, {
    map: currentLevel(),
    viewport: rect,
    origin,
    tileSize: scaledTileSize(),
  });
}

function scaledTileSize() {
  return getScaledTileSize(viewScale, baseTileSize);
}

function objectScale() {
  return getObjectScale(scaledTileSize());
}

function cameraView() {
  return { origin, camera, tileSize: scaledTileSize() };
}

function playSound(kind) {
  audio.playSound(kind);
}

function setStatus(message) {
  state.message = message;
  ui.syncStatus(message);
}

function roman(value) {
  return ['I', 'II', 'III', 'IV', 'V'][value - 1] ?? String(value);
}

init();

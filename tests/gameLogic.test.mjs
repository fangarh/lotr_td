import assert from 'node:assert/strict';
import test from 'node:test';

import { campaignLevels, enemyTypes, towerFamilies } from '../src/gameData.js';
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
  getLevelById,
  getTowerAttackProfile,
  getUnlockedUpgradeTier,
  isLevelUnlocked,
  normalizeSoundPreference,
  normalizeCampaignProgress,
} from '../src/gameLogic.js';

test('campaign defines at least 10 playable levels with waves', () => {
  assert.equal(campaignLevels.length >= 10, true);
  for (const level of campaignLevels.slice(0, 10)) {
    assert.equal(typeof level.id, 'number');
    assert.equal(level.waves.length > 0, true);
    assert.equal(level.startingGold > 0, true);
    assert.equal(level.lives > 0, true);
  }
});

test('tower catalog has 4 families, 5 tiers, and 3 tier-four branches per family', () => {
  assert.equal(towerFamilies.length, 4);

  for (const family of towerFamilies) {
    assert.equal(family.tiers.length, 5, family.id);
    assert.equal(Object.keys(family.branches).length, 3, family.id);

    for (const branch of Object.values(family.branches)) {
      assert.equal(branch.tier4.name.length > 0, true, family.id);
      assert.equal(branch.tier5.name.length > 0, true, family.id);
    }
  }
});

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

test('tower families expose distinct attack profiles', () => {
  const profiles = towerFamilies.map((family) => getTowerAttackProfile(family.id));
  const kinds = profiles.map((profile) => profile.kind).sort();

  assert.deepEqual(kinds, ['bombard', 'chain', 'pierce', 'precision']);
  for (const profile of profiles) {
    assert.equal(profile.label.length > 0, true);
    assert.equal(profile.description.length > 0, true);
    assert.equal(typeof profile.effect, 'string');
  }
});

test('campaign progress unlocks higher upgrade tiers gradually', () => {
  assert.equal(getUnlockedUpgradeTier(1), 2);
  assert.equal(getUnlockedUpgradeTier(3), 3);
  assert.equal(getUnlockedUpgradeTier(5), 4);
  assert.equal(getUnlockedUpgradeTier(8), 5);
  assert.equal(getUnlockedUpgradeTier(10), 5);
});

test('linear upgrades are available before branching unlocks', () => {
  const tower = createTower('eye-of-sauron', { x: 2, y: 4 });

  assert.deepEqual(
    getAvailableUpgrades(tower, 1).map((option) => option.kind),
    ['linear']
  );

  const tier2 = applyUpgrade(tower, getAvailableUpgrades(tower, 1)[0]);
  assert.equal(tier2.tier, 2);
  assert.equal(tier2.branchId, null);

  assert.deepEqual(
    getAvailableUpgrades(tier2, 3).map((option) => option.kind),
    ['linear']
  );
});

test('tier four requires one branch choice and tier five preserves that branch', () => {
  const tier3 = {
    ...createTower('morgul-sorcery', { x: 3, y: 3 }),
    tier: 3,
  };

  assert.deepEqual(
    getAvailableUpgrades(tier3, 4).map((option) => option.kind),
    []
  );

  const branchOptions = getAvailableUpgrades(tier3, 5);
  assert.equal(branchOptions.length, 3);
  assert.deepEqual(
    branchOptions.map((option) => option.kind),
    ['branch', 'branch', 'branch']
  );

  const tier4 = applyUpgrade(tier3, branchOptions[1]);
  assert.equal(tier4.tier, 4);
  assert.equal(tier4.branchId, branchOptions[1].branchId);

  const tier5Options = getAvailableUpgrades(tier4, 8);
  assert.equal(tier5Options.length, 1);
  assert.equal(tier5Options[0].kind, 'capstone');
  assert.equal(tier5Options[0].branchId, tier4.branchId);
});

test('placement allows one tower on buildable empty tiles only', () => {
  const map = {
    width: 4,
    height: 4,
    path: [
      { x: 0, y: 1 },
      { x: 1, y: 1 },
      { x: 2, y: 1 },
      { x: 3, y: 1 },
    ],
  };
  const towers = [createTower('orc-war-camp', { x: 2, y: 2 })];

  assert.equal(canPlaceTower({ x: 0, y: 0 }, map, towers).ok, true);
  assert.equal(canPlaceTower({ x: 1, y: 1 }, map, towers).ok, false);
  assert.equal(canPlaceTower({ x: 2, y: 2 }, map, towers).ok, false);
  assert.equal(canPlaceTower({ x: -1, y: 0 }, map, towers).ok, false);
});

test('campaign levels use multiple path layouts for encounter variety', () => {
  const uniquePaths = new Set(campaignLevels.map((level) => JSON.stringify(level.path)));

  assert.equal(uniquePaths.size >= 4, true);
  for (const level of campaignLevels) {
    assert.deepEqual(level.path[0], { x: 0, y: level.path[0].y });
    assert.equal(level.path.at(-1).x, level.width - 1);
  }
});

test('campaign levels use expanded battlefields for longer defense routes', () => {
  for (const level of campaignLevels.slice(0, 10)) {
    assert.equal(level.width >= 32, true, level.name);
    assert.equal(level.height >= 32, true, level.name);
    assert.equal(level.path.length >= level.width + 8, true, level.name);
    assert.equal(level.path.at(-1).x, level.width - 1, level.name);
  }

  assert.equal(campaignLevels.at(-1).width, 50);
  assert.equal(campaignLevels.at(-1).height, 50);
});

test('default campaign progress unlocks only the first level', () => {
  const progress = createDefaultProgress();

  assert.equal(getHighestUnlockedLevel(progress), 1);
  assert.equal(isLevelUnlocked(progress, 1), true);
  assert.equal(isLevelUnlocked(progress, 2), false);
  assert.deepEqual(progress.completedLevelIds, []);
});

test('completing campaign levels unlocks the next level without mutating input', () => {
  const progress = createDefaultProgress();
  const afterFirstWin = completeCampaignLevel(progress, 1, campaignLevels);

  assert.equal(getHighestUnlockedLevel(afterFirstWin), 2);
  assert.equal(isLevelUnlocked(afterFirstWin, 2), true);
  assert.deepEqual(afterFirstWin.completedLevelIds, [1]);
  assert.deepEqual(progress.completedLevelIds, []);

  const afterReplay = completeCampaignLevel(afterFirstWin, 1, campaignLevels);
  assert.deepEqual(afterReplay.completedLevelIds, [1]);
  assert.equal(getHighestUnlockedLevel(afterReplay), 2);
});

test('campaign progress caps unlocks at the final level', () => {
  const finalLevel = campaignLevels.at(-1);
  const nearlyDone = {
    ...createDefaultProgress(),
    highestUnlockedLevel: finalLevel.id,
    completedLevelIds: campaignLevels.slice(0, -1).map((level) => level.id),
  };

  const completed = completeCampaignLevel(nearlyDone, finalLevel.id, campaignLevels);

  assert.equal(getHighestUnlockedLevel(completed), finalLevel.id);
  assert.equal(isLevelUnlocked(completed, finalLevel.id + 1), false);
  assert.equal(completed.completedLevelIds.includes(finalLevel.id), true);
});

test('tester progress unlocks every campaign level and upgrade tier', () => {
  const progress = createTesterProgress(campaignLevels);
  const finalLevel = campaignLevels.at(-1);

  assert.equal(getHighestUnlockedLevel(progress), finalLevel.id);
  assert.equal(getUnlockedUpgradeTier(progress.highestUnlockedLevel), 5);
  assert.deepEqual(progress.completedLevelIds, campaignLevels.map((level) => level.id));
});

test('tester wave extension appends repeated waves without mutating the level', () => {
  const level = campaignLevels[0];
  const expanded = extendWavesForTesting(level, 2);

  assert.equal(expanded.length, level.waves.length + 2);
  assert.equal(level.waves.length, campaignLevels[0].waves.length);
  assert.notEqual(expanded, level.waves);
  assert.deepEqual(expanded.at(-1), level.waves[1]);
});

test('levels can be looked up by campaign id', () => {
  assert.equal(getLevelById(1, campaignLevels).name, campaignLevels[0].name);
  assert.equal(getLevelById(999, campaignLevels), null);
});

test('saved campaign progress is normalized before use', () => {
  assert.deepEqual(normalizeCampaignProgress(null, campaignLevels), createDefaultProgress());
  assert.deepEqual(
    normalizeCampaignProgress(
      {
        version: 1,
        highestUnlockedLevel: 99,
        completedLevelIds: [3, 1, 3, 'bad'],
      },
      campaignLevels
    ),
    {
      version: 1,
      highestUnlockedLevel: campaignLevels.at(-1).id,
      completedLevelIds: [1, 3],
    }
  );
});

test('enemy traits describe encounter roles by type and campaign level', () => {
  assert.equal(getEnemyTrait('hobbit-scout', 2).kind, 'swarm');
  assert.equal(getEnemyTrait('gondor-soldier', 2).kind, 'standard');
  assert.equal(getEnemyTrait('gondor-guard', 7).kind, 'elite');
  assert.equal(getEnemyTrait('rohirrim-rider', 7).kind, 'elite');
  assert.equal(getEnemyTrait('dwarven-sapper', 8).kind, 'siege');
  assert.equal(getEnemyTrait('dwarf-warrior', 9).kind, 'boss');
  assert.equal(getEnemyTrait('elven-warden', 9).kind, 'boss');
});

test('campaign levels expose authored presentation details', () => {
  for (const level of campaignLevels) {
    const presentation = getLevelPresentation(level);

    assert.equal(typeof presentation.sky, 'string', level.name);
    assert.equal(typeof presentation.horizon, 'string', level.name);
    assert.equal(presentation.landmarks.length > 0, true, level.name);
    assert.equal(presentation.ambientParticles.length > 0, true, level.name);
  }
});

test('sound preference normalizes stored values', () => {
  assert.equal(normalizeSoundPreference(null), false);
  assert.equal(normalizeSoundPreference(true), true);
  assert.equal(normalizeSoundPreference(false), false);
  assert.equal(normalizeSoundPreference('true'), true);
  assert.equal(normalizeSoundPreference('false'), false);
  assert.equal(normalizeSoundPreference('unexpected'), false);
});

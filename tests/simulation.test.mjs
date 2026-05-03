import assert from 'node:assert/strict';
import test from 'node:test';

import {
  collectKilledEnemies,
  createEnemy,
  damageEnemy,
  findNearbyEnemies,
  findTarget,
  getTowerSellValue,
  placeTower,
  performTowerAttack,
  sellTower,
  upgradeTower,
  updateEffects,
  updateEnemies,
  updateOutcome,
  updateProjectiles,
  updateSpawning,
  updateTowers,
} from '../src/simulation.js';

test('simulation finds the in-range enemy with the highest path progress score', () => {
  const tower = { tile: { x: 0, y: 0 } };
  const closeLessProgress = {
    id: 1,
    hp: 10,
    segment: 1,
    pos: { x: 1, y: 1 },
  };
  const fartherMoreProgress = {
    id: 2,
    hp: 10,
    segment: 2,
    pos: { x: 2, y: 0 },
  };
  const outOfRange = {
    id: 3,
    hp: 10,
    segment: 99,
    pos: { x: 10, y: 10 },
  };
  const state = {
    enemies: [closeLessProgress, fartherMoreProgress, outOfRange],
  };

  assert.equal(findTarget(state, tower, 3), fartherMoreProgress);
  assert.equal(findTarget(state, tower, 0.5), null);
});

test('simulation finds nearby living enemies by distance and respects limit', () => {
  const target = { id: 1, hp: 10, pos: { x: 0, y: 0 } };
  const nearest = { id: 2, hp: 10, pos: { x: 0.4, y: 0 } };
  const farthestIncluded = { id: 3, hp: 10, pos: { x: 0.9, y: 0 } };
  const dead = { id: 4, hp: 0, pos: { x: 0.2, y: 0 } };
  const outOfRadius = { id: 5, hp: 10, pos: { x: 2, y: 0 } };
  const state = {
    enemies: [farthestIncluded, target, outOfRadius, nearest, dead],
  };

  assert.deepEqual(findNearbyEnemies(state, target, 1, 3), [nearest, farthestIncluded]);
  assert.deepEqual(findNearbyEnemies(state, target, 1, 1), [nearest]);
});

test('simulation creates scaled enemies at the level path start', () => {
  const trait = { kind: 'runner', label: 'Fast' };
  const enemy = createEnemy({
    id: 7,
    type: 'scout',
    base: {
      name: 'Scout',
      hp: 50,
      speed: 1.2,
      reward: 9,
      damage: 2,
      color: '#abc',
      size: 0.7,
    },
    trait,
    level: {
      id: 3,
      path: [
        { x: 4, y: 5 },
        { x: 6, y: 5 },
      ],
    },
  });

  assert.deepEqual(enemy, {
    id: 7,
    type: 'scout',
    name: 'Scout',
    hp: 68,
    maxHp: 68,
    speed: 1.2648,
    reward: 11,
    damage: 2,
    color: '#abc',
    size: 0.7,
    trait,
    segment: 0,
    pos: { x: 4, y: 5 },
    slowTimer: 0,
    slowFactor: 0,
    phase: 4.56,
    hitFlash: 0,
  });
});

test('simulation does not advance spawning when no wave is running', () => {
  const spawned = [];
  const state = {
    runningWave: false,
    spawnTimer: 0.25,
    spawnQueue: [
      { type: 'scout', delay: 0.4 },
    ],
  };

  updateSpawning(state, 0.5, (type) => spawned.push(type));

  assert.equal(state.spawnTimer, 0.25);
  assert.deepEqual(state.spawnQueue, [
    { type: 'scout', delay: 0.4 },
  ]);
  assert.deepEqual(spawned, []);
});

test('simulation advances spawning and drains ready spawn queue entries', () => {
  const spawned = [];
  const state = {
    runningWave: true,
    spawnTimer: 0.1,
    spawnQueue: [
      { type: 'scout', delay: 0.2 },
      { type: 'soldier', delay: 0.45 },
      { type: 'captain', delay: 0.8 },
    ],
  };

  updateSpawning(state, 0.6, (type) => spawned.push(type));

  assert.deepEqual(spawned, ['scout', 'soldier']);
  assert.equal(state.spawnTimer, 0.15000000000000002);
  assert.deepEqual(state.spawnQueue, [
    { type: 'captain', delay: 0.8 },
  ]);
});

test('simulation moves enemies along the level path and updates timers', () => {
  const enemy = {
    id: 1,
    hp: 10,
    speed: 2,
    damage: 1,
    segment: 0,
    pos: { x: 0, y: 0 },
    slowTimer: 1,
    slowFactor: 0.5,
    hitFlash: 0.2,
  };
  const state = {
    lives: 10,
    enemies: [enemy],
    effects: [],
  };
  const breaches = [];

  updateEnemies(state, {
    path: [
      { x: 0, y: 0 },
      { x: 10, y: 0 },
    ],
  }, 0.5, (breachedEnemy) => breaches.push(breachedEnemy.id));

  assert.equal(enemy.slowTimer, 0.5);
  assert.equal(enemy.hitFlash, 0);
  assert.equal(enemy.segment, 0);
  assert.deepEqual(enemy.pos, { x: 0.5, y: 0 });
  assert.deepEqual(state.enemies, [enemy]);
  assert.equal(state.lives, 10);
  assert.deepEqual(state.effects, []);
  assert.deepEqual(breaches, []);
});

test('simulation removes enemies that breach the end of the path', () => {
  const enemy = {
    id: 2,
    hp: 10,
    speed: 3,
    damage: 2,
    segment: 0,
    pos: { x: 0, y: 0 },
    slowTimer: 0,
    slowFactor: 0,
    hitFlash: 0,
  };
  const state = {
    lives: 8,
    enemies: [enemy],
    effects: [],
  };
  const breaches = [];

  updateEnemies(state, {
    path: [
      { x: 0, y: 0 },
      { x: 1, y: 0 },
    ],
  }, 1, (breachedEnemy) => breaches.push(breachedEnemy.id));

  assert.equal(state.lives, 6);
  assert.deepEqual(state.enemies, []);
  assert.deepEqual(state.effects, [
    { kind: 'breach', pos: { x: 1, y: 0 }, age: 0, life: 0.55 },
  ]);
  assert.deepEqual(breaches, [2]);
});

test('simulation collects killed enemy rewards and emits kill effects', () => {
  const killedKinds = [];
  const alive = {
    id: 1,
    hp: 3,
    reward: 4,
    pos: { x: 1, y: 1 },
    color: '#111',
    trait: { kind: 'swarm' },
  };
  const regularKilled = {
    id: 2,
    hp: 0,
    reward: 8,
    pos: { x: 2, y: 3 },
    color: '#222',
    trait: { kind: 'elite' },
  };
  const bossKilled = {
    id: 3,
    hp: -5,
    reward: 20,
    pos: { x: 5, y: 8 },
    color: '#333',
    trait: { kind: 'boss' },
  };
  const state = {
    gold: 10,
    enemies: [alive, regularKilled, bossKilled],
    effects: [],
  };

  collectKilledEnemies(state, (enemy) => killedKinds.push(enemy.trait.kind));

  assert.equal(state.gold, 38);
  assert.deepEqual(state.enemies, [alive]);
  assert.deepEqual(killedKinds, ['elite', 'boss']);
  assert.deepEqual(state.effects, [
    { kind: 'fall', pos: { x: 2, y: 3 }, age: 0, life: 0.45, color: '#222' },
    { kind: 'reward', pos: { x: 2, y: 3 }, age: 0, life: 0.75, text: '+8' },
    { kind: 'fall', pos: { x: 5, y: 8 }, age: 0, life: 0.45, color: '#333' },
    { kind: 'reward', pos: { x: 5, y: 8 }, age: 0, life: 0.75, text: '+20' },
  ]);
});

test('simulation damages a target and emits a hit effect', () => {
  const target = {
    id: 1,
    hp: 30,
    pos: { x: 2, y: 3 },
    hitFlash: 0,
  };
  const state = {
    enemies: [target],
    effects: [],
  };

  damageEnemy(
    state,
    target,
    7,
    { slow: 0, splash: 0 },
    { accent: '#f00', projectile: 'arrow' },
    { effect: 'arrow-trail' },
  );

  assert.equal(target.hp, 23);
  assert.equal(target.hitFlash, 0.12);
  assert.deepEqual(state.effects, [
    { kind: 'hit', pos: { x: 2, y: 3 }, age: 0, life: 0.18, color: '#f00', style: 'arrow-trail' },
  ]);
});

test('simulation applies direct slow using the strongest slow factor', () => {
  const target = {
    id: 1,
    hp: 30,
    pos: { x: 0, y: 0 },
    hitFlash: 0,
    slowFactor: 0.35,
    slowTimer: 0,
  };
  const state = {
    enemies: [target],
    effects: [],
  };

  damageEnemy(
    state,
    target,
    1,
    { slow: 0.2, splash: 0 },
    { accent: '#0f0', projectile: 'light' },
    { effect: 'light-hit' },
  );

  assert.equal(target.slowFactor, 0.35);
  assert.equal(target.slowTimer, 1.25);
});

test('simulation applies splash damage and light splash slow to nearby enemies', () => {
  const target = {
    id: 1,
    hp: 40,
    pos: { x: 0, y: 0 },
    hitFlash: 0,
    slowFactor: 0,
    slowTimer: 0,
  };
  const nearby = {
    id: 2,
    hp: 30,
    pos: { x: 0.5, y: 0 },
    slowFactor: 0.1,
    slowTimer: 0,
  };
  const far = {
    id: 3,
    hp: 30,
    pos: { x: 3, y: 0 },
    slowFactor: 0,
    slowTimer: 0,
  };
  const state = {
    enemies: [target, nearby, far],
    effects: [],
  };

  damageEnemy(
    state,
    target,
    10,
    { slow: 0.4, splash: 1 },
    { accent: '#00f', projectile: 'light' },
    { effect: 'light-chain' },
  );

  assert.equal(target.hp, 30);
  assert.equal(nearby.hp, 25.5);
  assert.equal(far.hp, 30);
  assert.equal(nearby.slowFactor, 0.27999999999999997);
  assert.equal(nearby.slowTimer, 0.9);
  assert.equal(far.slowFactor, 0);
  assert.deepEqual(state.effects, [
    { kind: 'hit', pos: { x: 0, y: 0 }, age: 0, life: 0.18, color: '#00f', style: 'light-chain' },
    { kind: 'splash', pos: { x: 0, y: 0 }, age: 0, life: 0.32, radius: 1, color: '#00f' },
  ]);
});

test('simulation performs precision tower attacks with projectile and mark effects', () => {
  const tower = {
    tile: { x: 2, y: 4 },
    tier: 2,
    branchId: 'sniper',
  };
  const target = {
    id: 1,
    hp: 40,
    maxHp: 40,
    pos: { x: 5, y: 7 },
    hitFlash: 0,
    slowFactor: 0,
    slowTimer: 0,
  };
  const state = {
    enemies: [target],
    projectiles: [],
    effects: [],
  };

  performTowerAttack(
    state,
    tower,
    target,
    { damage: 10, slow: 0, splash: 0 },
    {
      accent: '#abc',
      projectile: 'arrow',
      branches: {
        sniper: { color: '#def' },
      },
    },
    { kind: 'precision', effect: 'mark-hit' },
  );

  assert.equal(target.hp, 26.5);
  assert.deepEqual(state.projectiles, [
    {
      from: { x: 2, y: 4, z: 0.96 },
      to: { x: 5, y: 7, z: 0.28 },
      age: 0,
      life: 0.28,
      color: '#def',
      kind: 'arrow',
      profileKind: 'precision',
    },
  ]);
  assert.deepEqual(state.effects, [
    { kind: 'hit', pos: { x: 5, y: 7 }, age: 0, life: 0.18, color: '#abc', style: 'mark-hit' },
    { kind: 'mark', pos: { x: 5, y: 7 }, age: 0, life: 0.28, color: '#def' },
  ]);
});

test('simulation updates tower cooldowns, attacks targets, and collects kills', () => {
  const tower = {
    typeId: 'archer',
    tile: { x: 0, y: 0 },
    tier: 1,
    branchId: null,
    cooldown: 0,
  };
  const target = {
    id: 1,
    hp: 6,
    maxHp: 6,
    pos: { x: 0.5, y: 0 },
    segment: 0,
    hitFlash: 0,
    slowFactor: 0,
    slowTimer: 0,
    reward: 5,
    color: '#222',
    trait: { kind: 'swarm' },
  };
  const state = {
    towers: [tower],
    enemies: [target],
    projectiles: [],
    effects: [],
    gold: 3,
  };
  const killed = [];

  updateTowers(state, 0.25, {
    getTowerStats: () => ({ range: 2, damage: 10, slow: 0, splash: 0, fireRate: 2 }),
    getTowerFamily: () => ({ accent: '#f80', projectile: 'arrow', branches: {} }),
    getTowerAttackProfile: () => ({ kind: 'precision', effect: 'arrow-hit' }),
    onKill: (enemy) => killed.push(enemy.id),
  });

  assert.equal(tower.cooldown, 0.5);
  assert.equal(state.gold, 8);
  assert.deepEqual(state.enemies, []);
  assert.deepEqual(killed, [1]);
  assert.equal(state.projectiles.length, 1);
  assert.equal(state.effects.at(-2).kind, 'fall');
  assert.equal(state.effects.at(-1).kind, 'reward');
});

test('simulation resolves loss outcomes through callbacks', () => {
  const events = [];
  const state = {
    lives: 0,
    outcome: 'playing',
    runningWave: true,
    spawnQueue: [],
    enemies: [],
  };

  const result = updateOutcome(state, {
    level: { id: 1, waves: [{}] },
    campaignLevels: [],
    completeCampaignLevel: () => {
      throw new Error('loss should not complete campaign progress');
    },
    onLost: () => events.push('lost'),
  });

  assert.deepEqual(result, { kind: 'lost' });
  assert.equal(state.outcome, 'lost');
  assert.deepEqual(events, ['lost']);
});

test('simulation advances to the next wave when the current wave is cleared', () => {
  const events = [];
  const state = {
    lives: 5,
    outcome: 'playing',
    runningWave: true,
    waveIndex: 0,
    spawnQueue: [],
    enemies: [],
  };

  const result = updateOutcome(state, {
    level: { id: 1, waves: [{}, {}] },
    campaignLevels: [],
    completeCampaignLevel: () => {
      throw new Error('intermediate waves should not complete campaign progress');
    },
    onWaveCleared: () => events.push('wave'),
  });

  assert.deepEqual(result, { kind: 'wave-cleared' });
  assert.equal(state.runningWave, false);
  assert.equal(state.waveIndex, 1);
  assert.equal(state.outcome, 'playing');
  assert.deepEqual(events, ['wave']);
});

test('simulation resolves level wins and reports the next campaign level', () => {
  const events = [];
  const progress = { highestUnlockedLevel: 1, completedLevelIds: [] };
  const completedProgress = { highestUnlockedLevel: 2, completedLevelIds: [1] };
  const state = {
    lives: 5,
    outcome: 'playing',
    runningWave: true,
    waveIndex: 0,
    levelIndex: 0,
    spawnQueue: [],
    enemies: [],
    progress,
  };
  const campaignLevels = [
    { id: 1, waves: [{}] },
    { id: 2, name: 'Next Road', waves: [{}] },
  ];

  const result = updateOutcome(state, {
    level: campaignLevels[0],
    campaignLevels,
    completeCampaignLevel: (inputProgress, levelId, levels) => {
      assert.equal(inputProgress, progress);
      assert.equal(levelId, 1);
      assert.equal(levels, campaignLevels);
      return completedProgress;
    },
    onLevelWon: ({ next, nextLevelIndex }) => events.push({ next, nextLevelIndex }),
  });

  assert.deepEqual(result, { kind: 'level-won', next: campaignLevels[1], nextLevelIndex: 1 });
  assert.equal(state.runningWave, false);
  assert.equal(state.waveIndex, 1);
  assert.equal(state.outcome, 'won');
  assert.equal(state.progress, completedProgress);
  assert.deepEqual(events, [{ next: campaignLevels[1], nextLevelIndex: 1 }]);
});

test('simulation places towers, spends gold, and emits a build effect', () => {
  const createdTower = {
    id: 'tower-1',
    typeId: 'archer',
    tile: { x: 2, y: 3 },
    tier: 1,
    branchId: null,
    totalSpent: 20,
  };
  const state = {
    gold: 35,
    testerInfiniteGold: false,
    towers: [],
    effects: [],
  };
  const tile = { x: 2, y: 3 };

  const result = placeTower(state, tile, {
    level: { width: 5, height: 5, path: [] },
    towerTypeId: 'archer',
    getTowerFamily: () => ({ id: 'archer', name: 'Archer', baseCost: 20, accent: '#f80' }),
    canPlaceTower: () => ({ ok: true, reason: '' }),
    createTower: () => createdTower,
  });

  assert.deepEqual(result, {
    ok: true,
    kind: 'placed',
    tower: createdTower,
    family: { id: 'archer', name: 'Archer', baseCost: 20, accent: '#f80' },
  });
  assert.equal(state.gold, 15);
  assert.deepEqual(state.towers, [createdTower]);
  assert.deepEqual(state.effects, [
    { kind: 'build', pos: tile, age: 0, life: 0.42, color: '#f80' },
  ]);
});

test('simulation rejects invalid tower placement without mutating state', () => {
  const state = {
    gold: 35,
    testerInfiniteGold: false,
    towers: [],
    effects: [],
  };

  const result = placeTower(state, { x: 1, y: 1 }, {
    level: { width: 5, height: 5, path: [] },
    towerTypeId: 'archer',
    getTowerFamily: () => ({ id: 'archer', name: 'Archer', baseCost: 20, accent: '#f80' }),
    canPlaceTower: () => ({ ok: false, reason: 'Blocked' }),
    createTower: () => {
      throw new Error('invalid placement should not create a tower');
    },
  });

  assert.deepEqual(result, { ok: false, kind: 'invalid-placement', reason: 'Blocked' });
  assert.equal(state.gold, 35);
  assert.deepEqual(state.towers, []);
  assert.deepEqual(state.effects, []);
});

test('simulation rejects unaffordable tower placement and honors infinite gold', () => {
  const state = {
    gold: 5,
    testerInfiniteGold: false,
    towers: [],
    effects: [],
  };
  const deps = {
    level: { width: 5, height: 5, path: [] },
    towerTypeId: 'archer',
    getTowerFamily: () => ({ id: 'archer', name: 'Archer', baseCost: 20, accent: '#f80' }),
    canPlaceTower: () => ({ ok: true, reason: '' }),
    createTower: () => ({ id: 'tower-1', typeId: 'archer', tile: { x: 1, y: 1 } }),
  };

  assert.deepEqual(placeTower(state, { x: 1, y: 1 }, deps), {
    ok: false,
    kind: 'unaffordable',
    family: { id: 'archer', name: 'Archer', baseCost: 20, accent: '#f80' },
  });
  assert.equal(state.gold, 5);
  assert.deepEqual(state.towers, []);

  state.testerInfiniteGold = true;
  const result = placeTower(state, { x: 1, y: 1 }, deps);

  assert.equal(result.ok, true);
  assert.equal(state.gold, 5);
  assert.equal(state.towers.length, 1);
});

test('simulation upgrades a tower, spends gold, and emits an upgrade effect', () => {
  const tower = {
    id: 'tower-1',
    typeId: 'archer',
    tile: { x: 2, y: 3 },
    tier: 1,
    branchId: null,
    totalSpent: 20,
  };
  const upgradedTower = {
    ...tower,
    tier: 2,
    totalSpent: 35,
  };
  const option = {
    tier: 2,
    name: 'Sharper Arrows',
    cost: 15,
    color: '#def',
  };
  const state = {
    gold: 30,
    testerInfiniteGold: false,
    towers: [tower],
    effects: [],
  };

  const result = upgradeTower(state, 'tower-1', option, {
    applyUpgrade: (inputTower, inputOption) => {
      assert.equal(inputTower, tower);
      assert.equal(inputOption, option);
      return upgradedTower;
    },
    getTowerFamily: () => ({ accent: '#abc' }),
  });

  assert.deepEqual(result, {
    ok: true,
    kind: 'upgraded',
    tower: upgradedTower,
    option,
  });
  assert.equal(state.gold, 15);
  assert.deepEqual(state.towers, [upgradedTower]);
  assert.deepEqual(state.effects, [
    { kind: 'upgrade', pos: { x: 2, y: 3 }, age: 0, life: 0.68, color: '#def' },
  ]);
});

test('simulation sells a tower for its refund value and removes it', () => {
  const soldTower = {
    id: 'tower-1',
    totalSpent: 101,
  };
  const keptTower = {
    id: 'tower-2',
    totalSpent: 20,
  };
  const state = {
    gold: 9,
    towers: [soldTower, keptTower],
  };

  const result = sellTower(state, 'tower-1');

  assert.deepEqual(result, {
    ok: true,
    kind: 'sold',
    tower: soldTower,
    value: 55,
  });
  assert.equal(getTowerSellValue(soldTower), 55);
  assert.equal(state.gold, 64);
  assert.deepEqual(state.towers, [keptTower]);
});

test('simulation advances projectile ages and removes expired projectiles', () => {
  const state = {
    projectiles: [
      { id: 'active', age: 0.1, life: 1 },
      { id: 'expired', age: 0.4, life: 0.5 },
    ],
  };

  updateProjectiles(state, 0.2);

  assert.deepEqual(state.projectiles, [
    { id: 'active', age: 0.30000000000000004, life: 1 },
  ]);
});

test('simulation advances effect ages and removes expired effects', () => {
  const state = {
    effects: [
      { id: 'active', age: 0, life: 0.75 },
      { id: 'expired', age: 0.7, life: 0.75 },
    ],
  };

  updateEffects(state, 0.1);

  assert.deepEqual(state.effects, [
    { id: 'active', age: 0.1, life: 0.75 },
  ]);
});

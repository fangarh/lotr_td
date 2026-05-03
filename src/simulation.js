export function createEnemy({ id, type, base, trait, level }) {
  const scale = 1 + level.id * 0.12;
  const hp = Math.round(base.hp * scale);
  return {
    id,
    type,
    name: base.name,
    hp,
    maxHp: hp,
    speed: base.speed * (1 + Math.min(0.26, level.id * 0.018)),
    reward: Math.round(base.reward * (1 + level.id * 0.06)),
    damage: base.damage,
    color: base.color,
    size: base.size,
    trait,
    segment: 0,
    pos: { ...level.path[0] },
    slowTimer: 0,
    slowFactor: 0,
    phase: (id + 1) * 0.57,
    hitFlash: 0,
  };
}

export function updateSpawning(state, dt, spawnEnemy) {
  if (!state.runningWave) return;
  state.spawnTimer -= dt;

  while (state.spawnQueue.length > 0 && state.spawnTimer <= 0) {
    const next = state.spawnQueue.shift();
    spawnEnemy(next.type);
    state.spawnTimer += next.delay;
  }
}

export function updateEnemies(state, level, dt, onBreach) {
  const survivors = [];

  for (const enemy of state.enemies) {
    enemy.slowTimer = Math.max(0, enemy.slowTimer - dt);
    enemy.hitFlash = Math.max(0, enemy.hitFlash - dt);
    const speed = enemy.speed * (enemy.slowTimer > 0 ? 1 - enemy.slowFactor : 1);
    let remaining = speed * dt;

    while (remaining > 0 && enemy.segment < level.path.length - 1) {
      const next = level.path[enemy.segment + 1];
      const dx = next.x - enemy.pos.x;
      const dy = next.y - enemy.pos.y;
      const distance = Math.hypot(dx, dy);
      if (distance <= remaining) {
        enemy.pos = { ...next };
        enemy.segment += 1;
        remaining -= distance;
      } else {
        enemy.pos.x += (dx / distance) * remaining;
        enemy.pos.y += (dy / distance) * remaining;
        remaining = 0;
      }
    }

    if (enemy.segment >= level.path.length - 1) {
      state.lives -= enemy.damage;
      state.effects.push({ kind: 'breach', pos: enemy.pos, age: 0, life: 0.55 });
      onBreach(enemy);
    } else if (enemy.hp > 0) {
      survivors.push(enemy);
    }
  }

  state.enemies = survivors;
}

export function collectKilledEnemies(state, onKill) {
  const killed = state.enemies.filter((enemy) => enemy.hp <= 0);
  if (killed.length === 0) return;

  for (const enemy of killed) {
    state.gold += enemy.reward;
    state.effects.push({ kind: 'fall', pos: enemy.pos, age: 0, life: 0.45, color: enemy.color });
    state.effects.push({ kind: 'reward', pos: enemy.pos, age: 0, life: 0.75, text: `+${enemy.reward}` });
    onKill(enemy);
  }

  state.enemies = state.enemies.filter((enemy) => enemy.hp > 0);
}

export function findNearbyEnemies(state, target, radius, limit) {
  return state.enemies
    .filter((enemy) => enemy.id !== target.id && enemy.hp > 0)
    .map((enemy) => ({
      enemy,
      distance: Math.hypot(enemy.pos.x - target.pos.x, enemy.pos.y - target.pos.y),
    }))
    .filter((entry) => entry.distance <= radius)
    .sort((a, b) => a.distance - b.distance)
    .slice(0, limit)
    .map((entry) => entry.enemy);
}

export function findTarget(state, tower, range) {
  const candidates = state.enemies
    .filter((enemy) => Math.hypot(enemy.pos.x - tower.tile.x, enemy.pos.y - tower.tile.y) <= range)
    .sort((a, b) => b.segment + b.pos.x + b.pos.y - (a.segment + a.pos.x + a.pos.y));
  return candidates[0] ?? null;
}

export function damageEnemy(state, target, damage, stats, family, attackProfile) {
  target.hp -= damage;
  target.hitFlash = 0.12;
  state.effects.push({ kind: 'hit', pos: target.pos, age: 0, life: 0.18, color: family.accent, style: attackProfile.effect });
  if (stats.slow > 0) {
    target.slowFactor = Math.max(target.slowFactor, stats.slow);
    target.slowTimer = 1.25;
  }

  if (stats.splash > 0) {
    for (const enemy of state.enemies) {
      if (enemy.id === target.id) continue;
      const distance = Math.hypot(enemy.pos.x - target.pos.x, enemy.pos.y - target.pos.y);
      if (distance <= stats.splash) {
        enemy.hp -= damage * 0.45;
        if (family.projectile === 'light' && stats.slow > 0) {
          enemy.slowFactor = Math.max(enemy.slowFactor, stats.slow * 0.7);
          enemy.slowTimer = 0.9;
        }
      }
    }
    state.effects.push({ kind: 'splash', pos: target.pos, age: 0, life: 0.32, radius: stats.splash, color: family.accent });
  }
}

export function updateTowers(state, dt, {
  getTowerStats,
  getTowerFamily,
  getTowerAttackProfile,
  onKill = () => {},
}) {
  for (const tower of state.towers) {
    tower.cooldown = Math.max(0, tower.cooldown - dt);
    if (tower.cooldown > 0) continue;

    const stats = getTowerStats(tower);
    const target = findTarget(state, tower, stats.range);
    if (!target) continue;

    const family = getTowerFamily(tower.typeId);
    const attackProfile = getTowerAttackProfile(tower.typeId);
    tower.cooldown = 1 / stats.fireRate;
    performTowerAttack(state, tower, target, stats, family, attackProfile);
  }

  collectKilledEnemies(state, onKill);
}

export function performTowerAttack(state, tower, target, stats, family, attackProfile) {
  const color = tower.branchId ? family.branches[tower.branchId].color : family.accent;
  const from = { x: tower.tile.x, y: tower.tile.y, z: 0.7 + tower.tier * 0.13 };
  const baseProjectile = {
    from,
    to: { x: target.pos.x, y: target.pos.y, z: 0.28 },
    age: 0,
    life: attackProfile.kind === 'bombard' ? 0.42 : 0.28,
    color,
    kind: family.projectile,
    profileKind: attackProfile.kind,
  };

  if (attackProfile.kind === 'precision') {
    damageEnemy(state, target, stats.damage * (target.hp === target.maxHp ? 1.35 : 1.08), stats, family, attackProfile);
    state.projectiles.push(baseProjectile);
    state.effects.push({ kind: 'mark', pos: target.pos, age: 0, life: 0.28, color });
    return;
  }

  if (attackProfile.kind === 'pierce') {
    damageEnemy(state, target, stats.damage, { ...stats, splash: 0 }, family, attackProfile);
    const pierced = findNearbyEnemies(state, target, 1.1, 2);
    for (const enemy of pierced) {
      damageEnemy(state, enemy, stats.damage * 0.42, { ...stats, splash: 0, slow: 0 }, family, attackProfile);
    }
    state.projectiles.push({ ...baseProjectile, life: 0.2 });
    state.effects.push({ kind: 'beam', pos: target.pos, from: tower.tile, to: target.pos, age: 0, life: 0.2, color, width: 4 });
    return;
  }

  if (attackProfile.kind === 'chain') {
    damageEnemy(state, target, stats.damage, { ...stats, splash: 0 }, family, attackProfile);
    state.projectiles.push(baseProjectile);
    let source = target;
    const chained = findNearbyEnemies(state, target, 1.75, 3);
    chained.forEach((enemy, index) => {
      damageEnemy(state, enemy, stats.damage * (0.54 - index * 0.08), { ...stats, splash: 0 }, family, attackProfile);
      state.effects.push({ kind: 'beam', pos: enemy.pos, from: source.pos, to: enemy.pos, age: 0, life: 0.26, color, width: 2 });
      source = enemy;
    });
    return;
  }

  const bombardStats = { ...stats, splash: Math.max(stats.splash, 0.8 + tower.tier * 0.16) };
  damageEnemy(state, target, stats.damage, bombardStats, family, attackProfile);
  state.projectiles.push(baseProjectile);
  state.effects.push({ kind: 'shockwave', pos: target.pos, age: 0, life: 0.36, radius: bombardStats.splash, color });
}

export function updateOutcome(state, {
  level,
  campaignLevels,
  completeCampaignLevel,
  onLost = () => {},
  onWaveCleared = () => {},
  onLevelWon = () => {},
}) {
  if (state.lives <= 0) {
    state.outcome = 'lost';
    onLost();
    return { kind: 'lost' };
  }

  if (!state.runningWave || state.spawnQueue.length > 0 || state.enemies.length > 0) {
    return { kind: 'none' };
  }

  state.runningWave = false;
  state.waveIndex += 1;

  if (state.waveIndex >= level.waves.length) {
    state.outcome = 'won';
    state.progress = completeCampaignLevel(state.progress, level.id, campaignLevels);
    const nextLevelIndex = state.levelIndex + 1;
    const next = campaignLevels[nextLevelIndex];
    onLevelWon({ next, nextLevelIndex });
    return { kind: 'level-won', next, nextLevelIndex };
  }

  onWaveCleared();
  return { kind: 'wave-cleared' };
}

export function placeTower(state, tile, {
  level,
  towerTypeId,
  getTowerFamily,
  canPlaceTower,
  createTower,
}) {
  const family = getTowerFamily(towerTypeId);
  const placement = canPlaceTower(tile, level, state.towers);

  if (!placement.ok) {
    return { ok: false, kind: 'invalid-placement', reason: placement.reason };
  }

  if (!state.testerInfiniteGold && state.gold < family.baseCost) {
    return { ok: false, kind: 'unaffordable', family };
  }

  const tower = createTower(family.id, tile);
  if (!state.testerInfiniteGold) {
    state.gold -= family.baseCost;
  }
  state.towers.push(tower);
  state.effects.push({ kind: 'build', pos: tile, age: 0, life: 0.42, color: family.accent });

  return { ok: true, kind: 'placed', tower, family };
}

export function upgradeTower(state, towerId, option, {
  applyUpgrade,
  getTowerFamily,
}) {
  const index = state.towers.findIndex((tower) => tower.id === towerId);
  if (index === -1) {
    return { ok: false, kind: 'tower-not-found' };
  }

  if (!state.testerInfiniteGold && state.gold < option.cost) {
    return { ok: false, kind: 'unaffordable', option };
  }

  if (!state.testerInfiniteGold) {
    state.gold -= option.cost;
  }

  const tower = applyUpgrade(state.towers[index], option);
  state.towers[index] = tower;
  state.effects.push({
    kind: 'upgrade',
    pos: tower.tile,
    age: 0,
    life: 0.68,
    color: option.color ?? getTowerFamily(tower.typeId).accent,
  });

  return { ok: true, kind: 'upgraded', tower, option };
}

export function getTowerSellValue(tower) {
  return Math.floor(tower.totalSpent * 0.55);
}

export function sellTower(state, towerId) {
  const index = state.towers.findIndex((tower) => tower.id === towerId);
  if (index === -1) {
    return { ok: false, kind: 'tower-not-found' };
  }

  const tower = state.towers[index];
  const value = getTowerSellValue(tower);
  state.gold += value;
  state.towers.splice(index, 1);

  return { ok: true, kind: 'sold', tower, value };
}

export function updateProjectiles(state, dt) {
  for (const projectile of state.projectiles) {
    projectile.age += dt;
  }
  state.projectiles = state.projectiles.filter((projectile) => projectile.age < projectile.life);
}

export function updateEffects(state, dt) {
  for (const effect of state.effects) {
    effect.age += dt;
  }
  state.effects = state.effects.filter((effect) => effect.age < effect.life);
}

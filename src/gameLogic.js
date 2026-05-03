import { campaignLevels, levelPresentationByTheme, towerFamilies } from './gameData.js';

export const campaignProgressVersion = 1;

export function createDefaultProgress() {
  return {
    version: campaignProgressVersion,
    highestUnlockedLevel: 1,
    completedLevelIds: [],
  };
}

export function normalizeCampaignProgress(progress, levels = campaignLevels) {
  if (!progress || typeof progress !== 'object') {
    return createDefaultProgress();
  }

  const validIds = new Set(levels.map((level) => level.id));
  const maxLevelId = levels.at(-1)?.id ?? 1;
  const completedLevelIds = Array.isArray(progress.completedLevelIds)
    ? [...new Set(progress.completedLevelIds)]
        .filter((id) => Number.isInteger(id) && validIds.has(id))
        .sort((a, b) => a - b)
    : [];
  const requestedUnlock = Number.isInteger(progress.highestUnlockedLevel)
    ? progress.highestUnlockedLevel
    : 1;

  return {
    version: campaignProgressVersion,
    highestUnlockedLevel: clamp(requestedUnlock, 1, maxLevelId),
    completedLevelIds,
  };
}

export function getHighestUnlockedLevel(progress) {
  return Math.max(1, Number.isInteger(progress?.highestUnlockedLevel) ? progress.highestUnlockedLevel : 1);
}

export function isLevelUnlocked(progress, levelId) {
  return Number.isInteger(levelId) && levelId <= getHighestUnlockedLevel(progress);
}

export function getLevelById(levelId, levels = campaignLevels) {
  return levels.find((level) => level.id === levelId) ?? null;
}

export function completeCampaignLevel(progress, levelId, levels = campaignLevels) {
  const current = normalizeCampaignProgress(progress, levels);
  const levelIndex = levels.findIndex((level) => level.id === levelId);
  if (levelIndex === -1) {
    return current;
  }

  const nextLevel = levels[levelIndex + 1];
  const completedLevelIds = [...new Set([...current.completedLevelIds, levelId])].sort((a, b) => a - b);

  return {
    ...current,
    highestUnlockedLevel: Math.max(current.highestUnlockedLevel, nextLevel?.id ?? levelId),
    completedLevelIds,
  };
}

export function createTesterProgress(levels = campaignLevels) {
  const finalLevel = levels.at(-1);
  return {
    version: campaignProgressVersion,
    highestUnlockedLevel: finalLevel?.id ?? 1,
    completedLevelIds: levels.map((level) => level.id),
  };
}

export function extendWavesForTesting(level, extraWaveCount = 1) {
  const waves = Array.isArray(level?.waves) ? level.waves : [];
  if (waves.length === 0 || extraWaveCount <= 0) {
    return [...waves];
  }

  return [
    ...waves,
    ...Array.from({ length: extraWaveCount }, (_, index) => waves[index % waves.length]),
  ];
}

export function getUnlockedUpgradeTier(campaignLevel) {
  if (campaignLevel >= 8) return 5;
  if (campaignLevel >= 5) return 4;
  if (campaignLevel >= 3) return 3;
  return 2;
}

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
export function getLevelPresentation(level) {
  return levelPresentationByTheme[level?.theme] ?? levelPresentationByTheme.shire;
}

export function getTowerAttackProfile(typeId) {
  const family = getTowerFamily(typeId);
  return family.attackProfile;
}

export function normalizeSoundPreference(value) {
  if (value === true || value === 'true') return true;
  return false;
}

export function getTowerFamily(typeId) {
  const family = towerFamilies.find((candidate) => candidate.id === typeId);
  if (!family) {
    throw new Error(`Unknown tower family: ${typeId}`);
  }
  return family;
}

export function createTower(typeId, tile) {
  const family = getTowerFamily(typeId);
  return {
    id: `${typeId}-${tile.x}-${tile.y}`,
    typeId,
    name: family.name,
    tile,
    tier: 1,
    branchId: null,
    cooldown: 0,
    totalSpent: family.baseCost,
  };
}

export function getTowerTierDefinition(tower) {
  const family = getTowerFamily(tower.typeId);
  if (tower.tier <= 3 || !tower.branchId) {
    return family.tiers[tower.tier - 1];
  }
  const branch = family.branches[tower.branchId];
  return tower.tier === 4 ? branch.tier4 : branch.tier5;
}

export function getTowerStats(tower) {
  return { ...getTowerTierDefinition(tower).stats };
}

export function getAvailableUpgrades(tower, campaignLevel) {
  const family = getTowerFamily(tower.typeId);
  const unlockedTier = getUnlockedUpgradeTier(campaignLevel);
  const nextTier = tower.tier + 1;

  if (tower.tier >= 5 || nextTier > unlockedTier) {
    return [];
  }

  if (nextTier <= 3) {
    const tierDefinition = family.tiers[nextTier - 1];
    return [
      {
        kind: 'linear',
        familyId: family.id,
        tier: nextTier,
        name: tierDefinition.name,
        cost: tierDefinition.cost,
        stats: tierDefinition.stats,
      },
    ];
  }

  if (nextTier === 4) {
    return Object.entries(family.branches).map(([branchId, branch]) => ({
      kind: 'branch',
      familyId: family.id,
      branchId,
      tier: 4,
      branchName: branch.name,
      name: branch.tier4.name,
      color: branch.color,
      cost: branch.tier4.cost,
      stats: branch.tier4.stats,
    }));
  }

  const branch = family.branches[tower.branchId];
  if (!branch) {
    return [];
  }

  return [
    {
      kind: 'capstone',
      familyId: family.id,
      branchId: tower.branchId,
      tier: 5,
      branchName: branch.name,
      name: branch.tier5.name,
      color: branch.color,
      cost: branch.tier5.cost,
      stats: branch.tier5.stats,
    },
  ];
}

export function applyUpgrade(tower, option) {
  if (!option) {
    throw new Error('Upgrade option is required');
  }

  return {
    ...tower,
    tier: option.tier,
    branchId: option.branchId ?? tower.branchId,
    totalSpent: tower.totalSpent + option.cost,
  };
}

export function canPlaceTower(tile, map, towers) {
  if (!Number.isInteger(tile.x) || !Number.isInteger(tile.y)) {
    return { ok: false, reason: 'РќРµРєРѕСЂСЂРµРєС‚РЅР°СЏ РєР»РµС‚РєР°' };
  }
  if (tile.x < 0 || tile.y < 0 || tile.x >= map.width || tile.y >= map.height) {
    return { ok: false, reason: 'Р—Р° РїСЂРµРґРµР»Р°РјРё РєР°СЂС‚С‹' };
  }
  if (map.path.some((pathTile) => sameTile(pathTile, tile))) {
    return { ok: false, reason: 'РќРµР»СЊР·СЏ СЃС‚СЂРѕРёС‚СЊ РЅР° РґРѕСЂРѕРіРµ' };
  }
  if (towers.some((tower) => sameTile(tower.tile, tile))) {
    return { ok: false, reason: 'РљР»РµС‚РєР° СѓР¶Рµ Р·Р°РЅСЏС‚Р°' };
  }
  return { ok: true, reason: '' };
}

export function sameTile(a, b) {
  return a.x === b.x && a.y === b.y;
}

export function tileKey(tile) {
  return `${tile.x},${tile.y}`;
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}


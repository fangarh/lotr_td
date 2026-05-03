export const towerFamilies = [
  {
    id: 'eye-of-sauron',
    name: 'Око Саурона',
    shortName: 'Око',
    baseCost: 70,
    accent: '#d9e6f2',
    projectile: 'arrow',
    attackProfile: {
      kind: 'precision',
      label: 'Всевидящий удар',
      description: 'Дальняя одиночная атака с усиленным первым попаданием по свежей цели.',
      effect: 'arrow-trail',
    },
    description: 'Дальняя магическая башня, отмечающая и сжигающая ключевые цели.',
    tiers: [
      { tier: 1, name: 'Тлеющий знак', cost: 0, stats: { damage: 18, range: 3.4, fireRate: 1.05, splash: 0, slow: 0 } },
      { tier: 2, name: 'Красный взор', cost: 55, stats: { damage: 29, range: 3.75, fireRate: 1.16, splash: 0, slow: 0 } },
      { tier: 3, name: 'Башня наблюдения', cost: 95, stats: { damage: 47, range: 4.15, fireRate: 1.26, splash: 0, slow: 0 } },
      { tier: 4, name: 'Пылающее око', cost: 145, stats: { damage: 68, range: 4.45, fireRate: 1.35, splash: 0, slow: 0 } },
      { tier: 5, name: 'Воля Саурона', cost: 230, stats: { damage: 96, range: 4.85, fireRate: 1.48, splash: 0, slow: 0 } },
    ],
    branches: {
      citadel: {
        name: 'Чёрная цитадель',
        color: '#f8fafc',
        tier4: { name: 'Дозор Барад-дура', cost: 155, stats: { damage: 82, range: 4.9, fireRate: 1.35, splash: 0, slow: 0 } },
        tier5: { name: 'Неусыпный взор', cost: 255, stats: { damage: 122, range: 5.35, fireRate: 1.52, splash: 0, slow: 0 } },
      },
      ranger: {
        name: 'Ищейки Тени',
        color: '#70d38f',
        tier4: { name: 'Метка охотника', cost: 145, stats: { damage: 62, range: 4.55, fireRate: 1.85, splash: 0, slow: 0 } },
        tier5: { name: 'Тропа страха', cost: 240, stats: { damage: 86, range: 4.95, fireRate: 2.28, splash: 0, slow: 0 } },
      },
      beacon: {
        name: 'Сигнальные огни',
        color: '#ffd166',
        tier4: { name: 'Костёр покорения', cost: 165, stats: { damage: 70, range: 4.35, fireRate: 1.22, splash: 0.85, slow: 0 } },
        tier5: { name: 'Пламя Ородруина', cost: 265, stats: { damage: 105, range: 4.7, fireRate: 1.35, splash: 1.15, slow: 0 } },
      },
    },
  },
  {
    id: 'orc-war-camp',
    name: 'Военный лагерь орков',
    shortName: 'Орки',
    baseCost: 60,
    accent: '#d7b35f',
    projectile: 'spear',
    attackProfile: {
      kind: 'pierce',
      label: 'Град чёрных стрел',
      description: 'Стрелы и копья пробивают цель и ранят врагов рядом по линии дороги.',
      effect: 'spear-line',
    },
    description: 'Быстрые грубые залпы против лёгких отрядов сопротивления.',
    tiers: [
      { tier: 1, name: 'Сторожевой костёр', cost: 0, stats: { damage: 13, range: 2.9, fireRate: 1.55, splash: 0, slow: 0 } },
      { tier: 2, name: 'Частокол', cost: 45, stats: { damage: 21, range: 3.12, fireRate: 1.72, splash: 0, slow: 0 } },
      { tier: 3, name: 'Лагерь налётчиков', cost: 85, stats: { damage: 33, range: 3.34, fireRate: 1.92, splash: 0, slow: 0 } },
      { tier: 4, name: 'Военный вождь', cost: 135, stats: { damage: 47, range: 3.52, fireRate: 2.08, splash: 0, slow: 0 } },
      { tier: 5, name: 'Орда Мордора', cost: 215, stats: { damage: 67, range: 3.82, fireRate: 2.32, splash: 0, slow: 0 } },
    ],
    branches: {
      charge: {
        name: 'Натиск',
        color: '#f5c84b',
        tier4: { name: 'Рёв варбанды', cost: 135, stats: { damage: 56, range: 3.45, fireRate: 2.25, splash: 0.25, slow: 0 } },
        tier5: { name: 'Последний напор', cost: 230, stats: { damage: 82, range: 3.72, fireRate: 2.62, splash: 0.45, slow: 0 } },
      },
      marshal: {
        name: 'Командиры',
        color: '#8fd694',
        tier4: { name: 'Знамя Чёрной земли', cost: 150, stats: { damage: 42, range: 3.85, fireRate: 2.55, splash: 0, slow: 0 } },
        tier5: { name: 'Сбор орды', cost: 245, stats: { damage: 59, range: 4.25, fireRate: 3.0, splash: 0, slow: 0 } },
      },
      horsebow: {
        name: 'Стрелки-налётчики',
        color: '#d99b58',
        tier4: { name: 'Лёгкие застрельщики', cost: 140, stats: { damage: 38, range: 4.1, fireRate: 2.05, splash: 0, slow: 0.16 } },
        tier5: { name: 'Ветер пепла', cost: 235, stats: { damage: 55, range: 4.55, fireRate: 2.36, splash: 0, slow: 0.24 } },
      },
    },
  },
  {
    id: 'morgul-sorcery',
    name: 'Моргульское колдовство',
    shortName: 'Моргул',
    baseCost: 85,
    accent: '#bff7e1',
    projectile: 'light',
    attackProfile: {
      kind: 'chain',
      label: 'Цепь ужаса',
      description: 'Моргульская сила перескакивает между близкими врагами и усиливает контроль.',
      effect: 'light-chain',
    },
    description: 'Проклятия, цепная магия и замедляющий страх.',
    tiers: [
      { tier: 1, name: 'Зелёный огонь', cost: 0, stats: { damage: 15, range: 3.25, fireRate: 1.0, splash: 0, slow: 0.1 } },
      { tier: 2, name: 'Проклятая печать', cost: 65, stats: { damage: 25, range: 3.55, fireRate: 1.08, splash: 0, slow: 0.13 } },
      { tier: 3, name: 'Круг могил', cost: 105, stats: { damage: 40, range: 3.9, fireRate: 1.16, splash: 0, slow: 0.17 } },
      { tier: 4, name: 'Моргульский алтарь', cost: 160, stats: { damage: 58, range: 4.22, fireRate: 1.24, splash: 0, slow: 0.2 } },
      { tier: 5, name: 'Чёрное дыхание', cost: 255, stats: { damage: 82, range: 4.65, fireRate: 1.35, splash: 0, slow: 0.25 } },
    ],
    branches: {
      starlight: {
        name: 'Призрачный свет',
        color: '#e9f9ff',
        tier4: { name: 'Зеркало страха', cost: 165, stats: { damage: 76, range: 4.6, fireRate: 1.12, splash: 0, slow: 0.18 } },
        tier5: { name: 'Сияние нежити', cost: 270, stats: { damage: 118, range: 5.0, fireRate: 1.24, splash: 0, slow: 0.22 } },
      },
      roots: {
        name: 'Порча земли',
        color: '#64d38a',
        tier4: { name: 'Сплетённые корни', cost: 155, stats: { damage: 44, range: 4.05, fireRate: 1.32, splash: 0.7, slow: 0.34 } },
        tier5: { name: 'Лес под властью Тени', cost: 250, stats: { damage: 68, range: 4.35, fireRate: 1.5, splash: 1.05, slow: 0.43 } },
      },
      moon: {
        name: 'Лунная порча',
        color: '#b5c7ff',
        tier4: { name: 'Бледные стрелы', cost: 150, stats: { damage: 53, range: 4.85, fireRate: 1.52, splash: 0, slow: 0.15 } },
        tier5: { name: 'Дуга мёртвого света', cost: 245, stats: { damage: 74, range: 5.45, fireRate: 1.9, splash: 0, slow: 0.2 } },
      },
    },
  },
  {
    id: 'mordor-forge',
    name: 'Кузня Мордора',
    shortName: 'Кузня',
    baseCost: 95,
    accent: '#f08a4b',
    projectile: 'hammer',
    attackProfile: {
      kind: 'bombard',
      label: 'Тяжёлый огонь',
      description: 'Медленный удар по площади с заметной ударной волной.',
      effect: 'forge-burst',
    },
    description: 'Медленный тяжёлый обстрел, огонь и ударные волны.',
    tiers: [
      { tier: 1, name: 'Угольная яма', cost: 0, stats: { damage: 34, range: 2.65, fireRate: 0.58, splash: 0.45, slow: 0 } },
      { tier: 2, name: 'Железная плавильня', cost: 70, stats: { damage: 52, range: 2.85, fireRate: 0.64, splash: 0.55, slow: 0 } },
      { tier: 3, name: 'Осадный молот', cost: 115, stats: { damage: 78, range: 3.08, fireRate: 0.7, splash: 0.7, slow: 0 } },
      { tier: 4, name: 'Чёрная кузня', cost: 175, stats: { damage: 112, range: 3.3, fireRate: 0.76, splash: 0.88, slow: 0 } },
      { tier: 5, name: 'Сердце Ородруина', cost: 275, stats: { damage: 158, range: 3.65, fireRate: 0.84, splash: 1.05, slow: 0 } },
    ],
    branches: {
      mithril: {
        name: 'Чёрное железо',
        color: '#d7eff5',
        tier4: { name: 'Железный пресс', cost: 180, stats: { damage: 140, range: 3.25, fireRate: 0.72, splash: 0.7, slow: 0 } },
        tier5: { name: 'Молот Гронда', cost: 295, stats: { damage: 215, range: 3.55, fireRate: 0.82, splash: 0.85, slow: 0 } },
      },
      magma: {
        name: 'Магма',
        color: '#ff6b35',
        tier4: { name: 'Жила лавы', cost: 175, stats: { damage: 104, range: 3.15, fireRate: 0.78, splash: 1.18, slow: 0 } },
        tier5: { name: 'Печь Роковой горы', cost: 285, stats: { damage: 152, range: 3.45, fireRate: 0.88, splash: 1.62, slow: 0 } },
      },
      rune: {
        name: 'Руны Тени',
        color: '#9bd0ff',
        tier4: { name: 'Рунный резец', cost: 165, stats: { damage: 82, range: 3.65, fireRate: 0.92, splash: 0.65, slow: 0.22 } },
        tier5: { name: 'Синие руны Мордора', cost: 265, stats: { damage: 118, range: 4.0, fireRate: 1.08, splash: 0.82, slow: 0.32 } },
      },
    },
  },
];
export const enemyTypes = {
  'gondor-soldier': { name: 'Воин Гондора', hp: 58, speed: 0.74, reward: 8, damage: 1, color: '#9ca3af', size: 0.72 },
  'hobbit-scout': { name: 'Хоббит-разведчик', hp: 38, speed: 1.05, reward: 6, damage: 1, color: '#c8b27a', size: 0.58 },
  'gondor-guard': { name: 'Страж Гондора', hp: 132, speed: 0.62, reward: 14, damage: 2, color: '#d8dde6', size: 0.86 },
  'rohirrim-rider': { name: 'Всадник Рохана', hp: 94, speed: 1.18, reward: 12, damage: 1, color: '#d7b35f', size: 0.82 },
  'dwarf-warrior': { name: 'Воин гномов', hp: 420, speed: 0.42, reward: 35, damage: 4, color: '#b9713f', size: 1.2 },
  'dwarven-sapper': { name: 'Гном-сапёр', hp: 520, speed: 0.36, reward: 42, damage: 5, color: '#8b6f47', size: 1.16 },
  'elven-warden': { name: 'Эльфийский хранитель', hp: 720, speed: 0.82, reward: 70, damage: 7, color: '#bff7e1', size: 1.05 },
};
export const levelPresentationByTheme = {
  shire: {
    sky: '#27372b',
    horizon: '#6f8f5a',
    accent: '#d8ad45',
    landmarks: ['oak', 'hill', 'watchfire'],
    ambientParticles: ['leaf', 'ember'],
  },
  rivendell: {
    sky: '#243841',
    horizon: '#78a695',
    accent: '#bff7e1',
    landmarks: ['falls', 'arches', 'pines'],
    ambientParticles: ['mist', 'leaf'],
  },
  snow: {
    sky: '#2f3e45',
    horizon: '#c5d1c8',
    accent: '#d9e6f2',
    landmarks: ['peaks', 'ice', 'wind'],
    ambientParticles: ['snow', 'mist'],
  },
  moria: {
    sky: '#171a1d',
    horizon: '#68675d',
    accent: '#f08a4b',
    landmarks: ['pillars', 'chasm', 'forge'],
    ambientParticles: ['ash', 'ember'],
  },
  lorien: {
    sky: '#21372f',
    horizon: '#89b972',
    accent: '#e9f9ff',
    landmarks: ['mallorn', 'lanterns', 'roots'],
    ambientParticles: ['leaf', 'glow'],
  },
  rohan: {
    sky: '#394035',
    horizon: '#b3a65f',
    accent: '#f5c84b',
    landmarks: ['grass', 'banners', 'mounds'],
    ambientParticles: ['dust', 'grass'],
  },
  'helms-deep': {
    sky: '#20272b',
    horizon: '#8c8a7a',
    accent: '#9bd0ff',
    landmarks: ['walls', 'culvert', 'torches'],
    ambientParticles: ['rain', 'ember'],
  },
  gondor: {
    sky: '#2d3637',
    horizon: '#a9b0a4',
    accent: '#f8fafc',
    landmarks: ['white-tree', 'banners', 'fields'],
    ambientParticles: ['petal', 'dust'],
  },
  mordor: {
    sky: '#2b2220',
    horizon: '#a04c34',
    accent: '#ff6b35',
    landmarks: ['spires', 'lava', 'ash-dunes'],
    ambientParticles: ['ash', 'ember'],
  },
  'black-gate': {
    sky: '#151719',
    horizon: '#7c392f',
    accent: '#d45f4c',
    landmarks: ['gate', 'spikes', 'smoke'],
    ambientParticles: ['ash', 'spark'],
  },
};

const basePath = [
  { x: 0, y: 5 },
  { x: 1, y: 5 },
  { x: 2, y: 5 },
  { x: 3, y: 5 },
  { x: 3, y: 4 },
  { x: 4, y: 4 },
  { x: 5, y: 4 },
  { x: 6, y: 4 },
  { x: 6, y: 5 },
  { x: 7, y: 5 },
  { x: 8, y: 5 },
  { x: 9, y: 5 },
  { x: 9, y: 4 },
  { x: 10, y: 4 },
  { x: 11, y: 4 },
];

const rivendellPath = [
  { x: 0, y: 3 },
  { x: 1, y: 3 },
  { x: 2, y: 3 },
  { x: 2, y: 4 },
  { x: 3, y: 4 },
  { x: 4, y: 4 },
  { x: 4, y: 5 },
  { x: 5, y: 5 },
  { x: 6, y: 5 },
  { x: 6, y: 4 },
  { x: 7, y: 4 },
  { x: 8, y: 4 },
  { x: 8, y: 3 },
  { x: 9, y: 3 },
  { x: 10, y: 3 },
  { x: 11, y: 3 },
];

const mountainPath = [
  { x: 0, y: 6 },
  { x: 1, y: 6 },
  { x: 1, y: 5 },
  { x: 2, y: 5 },
  { x: 3, y: 5 },
  { x: 4, y: 5 },
  { x: 4, y: 4 },
  { x: 5, y: 4 },
  { x: 5, y: 3 },
  { x: 6, y: 3 },
  { x: 7, y: 3 },
  { x: 7, y: 4 },
  { x: 8, y: 4 },
  { x: 9, y: 4 },
  { x: 10, y: 4 },
  { x: 11, y: 4 },
];

const deepPath = [
  { x: 0, y: 4 },
  { x: 1, y: 4 },
  { x: 1, y: 5 },
  { x: 2, y: 5 },
  { x: 3, y: 5 },
  { x: 3, y: 6 },
  { x: 4, y: 6 },
  { x: 5, y: 6 },
  { x: 5, y: 5 },
  { x: 6, y: 5 },
  { x: 7, y: 5 },
  { x: 7, y: 4 },
  { x: 8, y: 4 },
  { x: 9, y: 4 },
  { x: 10, y: 4 },
  { x: 11, y: 4 },
];

const fieldPath = [
  { x: 0, y: 2 },
  { x: 1, y: 2 },
  { x: 2, y: 2 },
  { x: 3, y: 2 },
  { x: 3, y: 3 },
  { x: 4, y: 3 },
  { x: 5, y: 3 },
  { x: 6, y: 3 },
  { x: 6, y: 4 },
  { x: 7, y: 4 },
  { x: 8, y: 4 },
  { x: 9, y: 4 },
  { x: 9, y: 5 },
  { x: 10, y: 5 },
  { x: 11, y: 5 },
];

const mordorPath = [
  { x: 0, y: 6 },
  { x: 1, y: 6 },
  { x: 2, y: 6 },
  { x: 2, y: 5 },
  { x: 3, y: 5 },
  { x: 4, y: 5 },
  { x: 5, y: 5 },
  { x: 5, y: 4 },
  { x: 6, y: 4 },
  { x: 7, y: 4 },
  { x: 7, y: 5 },
  { x: 8, y: 5 },
  { x: 9, y: 5 },
  { x: 10, y: 5 },
  { x: 11, y: 5 },
];

const levelSizes = [
  { width: 32, height: 32 },
  { width: 34, height: 34 },
  { width: 36, height: 36 },
  { width: 38, height: 38 },
  { width: 40, height: 40 },
  { width: 42, height: 42 },
  { width: 44, height: 44 },
  { width: 46, height: 46 },
  { width: 48, height: 48 },
  { width: 50, height: 50 },
];

function expandPath(path, width, height, style = 'middle') {
  const expanded = [...path];
  let cursor = { ...expanded.at(-1) };
  const lowY = Math.max(2, Math.floor(height * 0.22));
  const midY = Math.max(3, Math.floor(height * 0.42));
  const highY = Math.max(4, Math.floor(height * 0.62));

  while (cursor.x < width - 1) {
    const nextX = cursor.x + 1;
    const targetY = pathTargetY(nextX, width, { lowY, midY, highY }, style);

    while (cursor.y !== targetY) {
      cursor = { x: cursor.x, y: cursor.y + Math.sign(targetY - cursor.y) };
      expanded.push(cursor);
    }

    cursor = { x: nextX, y: cursor.y };
    expanded.push(cursor);
  }

  return expanded;
}

function pathTargetY(x, width, bands, style) {
  const progress = x / Math.max(1, width - 1);
  if (style === 'ridge') {
    if (progress < 0.32) return bands.midY;
    if (progress < 0.58) return bands.lowY;
    return bands.midY - 1;
  }
  if (style === 'deep') {
    if (progress < 0.34) return bands.highY;
    if (progress < 0.66) return bands.midY;
    return bands.highY - 1;
  }
  if (style === 'field') {
    if (progress < 0.28) return bands.lowY;
    if (progress < 0.48) return bands.midY;
    if (progress < 0.72) return bands.highY;
    return bands.highY + 1;
  }
  if (style === 'mordor') {
    if (progress < 0.3) return bands.highY;
    if (progress < 0.5) return bands.midY;
    if (progress < 0.78) return bands.midY + 2;
    return bands.highY;
  }
  if (progress < 0.35) return bands.midY;
  if (progress < 0.64) return bands.highY;
  return bands.midY + 1;
}

function wave(entries) {
  return entries.map(([type, count, delay = 0.85]) => ({ type, count, delay }));
}

export const campaignLevels = [
  { id: 1, name: 'Тень у Бри', theme: 'shire', startingGold: 260, lives: 20, ...levelSizes[0], path: expandPath(basePath, levelSizes[0].width, levelSizes[0].height), waves: [wave([['hobbit-scout', 10]]), wave([['gondor-soldier', 12]])] },
  { id: 2, name: 'Дорога к Ривенделлу', theme: 'rivendell', startingGold: 270, lives: 20, ...levelSizes[1], path: expandPath(rivendellPath, levelSizes[1].width, levelSizes[1].height), waves: [wave([['hobbit-scout', 12], ['gondor-soldier', 8]]), wave([['gondor-soldier', 16]])] },
  { id: 3, name: 'Перевал Карадрас', theme: 'snow', startingGold: 285, lives: 19, ...levelSizes[2], path: expandPath(mountainPath, levelSizes[2].width, levelSizes[2].height, 'ridge'), waves: [wave([['gondor-soldier', 16]]), wave([['hobbit-scout', 18], ['gondor-guard', 3]])] },
  { id: 4, name: 'Врата Мории', theme: 'moria', startingGold: 305, lives: 18, ...levelSizes[3], path: expandPath(deepPath, levelSizes[3].width, levelSizes[3].height, 'deep'), waves: [wave([['hobbit-scout', 20], ['gondor-soldier', 10]]), wave([['gondor-guard', 6], ['rohirrim-rider', 4]])] },
  { id: 5, name: 'Порча Лориэна', theme: 'lorien', startingGold: 330, lives: 18, ...levelSizes[4], path: expandPath(rivendellPath, levelSizes[4].width, levelSizes[4].height), waves: [wave([['rohirrim-rider', 10], ['gondor-soldier', 14]]), wave([['gondor-guard', 10], ['dwarf-warrior', 1]])] },
  { id: 6, name: 'Броды Изена', theme: 'rohan', startingGold: 355, lives: 17, ...levelSizes[5], path: expandPath(fieldPath, levelSizes[5].width, levelSizes[5].height, 'field'), waves: [wave([['rohirrim-rider', 14], ['gondor-guard', 8]]), wave([['gondor-soldier', 20], ['dwarf-warrior', 2]])] },
  { id: 7, name: 'Осада Хельмовой Пади', theme: 'helms-deep', startingGold: 380, lives: 16, ...levelSizes[6], path: expandPath(deepPath, levelSizes[6].width, levelSizes[6].height, 'deep'), waves: [wave([['gondor-guard', 18]]), wave([['dwarven-sapper', 2], ['gondor-guard', 14]])] },
  { id: 8, name: 'Поля Пеленнора', theme: 'gondor', startingGold: 410, lives: 16, ...levelSizes[7], path: expandPath(fieldPath, levelSizes[7].width, levelSizes[7].height, 'field'), waves: [wave([['rohirrim-rider', 16], ['gondor-guard', 18]]), wave([['dwarf-warrior', 4], ['dwarven-sapper', 3]])] },
  { id: 9, name: 'Перевал Кирит Унгол', theme: 'mordor', startingGold: 440, lives: 15, ...levelSizes[8], path: expandPath(mordorPath, levelSizes[8].width, levelSizes[8].height, 'mordor'), waves: [wave([['gondor-soldier', 26], ['dwarven-sapper', 3]]), wave([['dwarf-warrior', 5], ['elven-warden', 1]])] },
  { id: 10, name: 'Чёрные врата', theme: 'black-gate', startingGold: 480, lives: 15, ...levelSizes[9], path: expandPath(mordorPath, levelSizes[9].width, levelSizes[9].height, 'mordor'), waves: [wave([['gondor-guard', 24], ['dwarf-warrior', 5]]), wave([['dwarven-sapper', 5], ['elven-warden', 2]])] },
];






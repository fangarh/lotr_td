export function createRenderer({
  ctx,
  getViewport,
  getCurrentLevel,
  getCameraView,
  getRenderState,
  getLevelPresentation,
  getVisibleTileBounds,
  tileKey,
  sameTile,
  getSelectedTile,
  getSelectedTowerId,
  getHoverTile,
  getSelectedTowerType,
  getTowerAt,
  getTowerFamily,
  getTowerAttackProfile,
  canPlaceTower,
  project,
  getObjectScale,
  getScaledTileSize,
}) {
  function draw() {
    const viewport = getViewport();
    ctx.clearRect(0, 0, viewport.width, viewport.height);
    drawBackdrop(viewport);
    drawMap(viewport);
    drawPathMarkers();
    drawTowers();
    drawEnemies();
    drawProjectiles();
    drawEffects();
    drawHover();
  }

  function drawBackdrop(viewport) {
    const presentation = getLevelPresentation(getCurrentLevel());
    const gradient = ctx.createLinearGradient(0, 0, 0, viewport.height);
    gradient.addColorStop(0, presentation.sky);
    gradient.addColorStop(0.52, '#171b19');
    gradient.addColorStop(1, '#101111');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, viewport.width, viewport.height);

    drawLandmarks(viewport, presentation);
    drawAmbientParticles(viewport, presentation);
  }

  function drawLandmarks(rect, presentation) {
    ctx.save();
    ctx.globalAlpha = 0.46;
    ctx.fillStyle = presentation.horizon;

    if (presentation.landmarks.includes('peaks')) {
      for (let i = -1; i < 7; i += 1) {
        const x = i * 190 + 70;
        ctx.beginPath();
        ctx.moveTo(x, rect.height * 0.36);
        ctx.lineTo(x + 96, rect.height * 0.12);
        ctx.lineTo(x + 210, rect.height * 0.36);
        ctx.closePath();
        ctx.fill();
      }
    } else if (presentation.landmarks.includes('gate')) {
      const baseY = rect.height * 0.39;
      ctx.fillStyle = 'rgba(18, 16, 15, 0.42)';
      ctx.beginPath();
      ctx.moveTo(rect.width * 0.46, baseY);
      ctx.lineTo(rect.width * 0.53, baseY - 34);
      ctx.lineTo(rect.width * 0.58, baseY);
      ctx.lineTo(rect.width * 0.64, baseY - 56);
      ctx.lineTo(rect.width * 0.69, baseY);
      ctx.lineTo(rect.width * 0.76, baseY - 42);
      ctx.lineTo(rect.width * 0.83, baseY);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = 'rgba(124, 57, 47, 0.2)';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(rect.width * 0.5, baseY - 8);
      ctx.bezierCurveTo(rect.width * 0.6, baseY - 18, rect.width * 0.7, baseY - 18, rect.width * 0.8, baseY - 8);
      ctx.stroke();
    } else if (presentation.landmarks.includes('walls')) {
      ctx.fillRect(0, rect.height * 0.34, rect.width, 26);
      for (let i = 0; i < 12; i += 1) {
        ctx.fillRect(i * 120, rect.height * 0.28, 34, 62);
      }
    } else {
      for (let i = 0; i < 9; i += 1) {
        const x = i * 175 + 40;
        ctx.beginPath();
        ctx.arc(x, rect.height * 0.36 + (i % 3) * 8, 66 + (i % 2) * 28, Math.PI, 0);
        ctx.fill();
      }
    }

    ctx.globalAlpha = 0.16;
    ctx.fillStyle = presentation.accent;
    for (let i = 0; i < 12; i += 1) {
      ctx.beginPath();
      ctx.arc(90 + i * 150, rect.height - 54 - (i % 3) * 20, 3 + (i % 4), 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.restore();
  }

  function drawAmbientParticles(rect, presentation) {
    const { clock } = getRenderState();
    ctx.save();
    const color = presentation.accent;
    for (let i = 0; i < 38; i += 1) {
      const speed = 0.08 + (i % 7) * 0.018;
      const drift = (clock * speed + i * 0.137) % 1;
      const x = (i * 97 + drift * rect.width) % rect.width;
      const y = 92 + ((i * 53 + drift * rect.height * 0.55) % (rect.height * 0.58));
      const particle = presentation.ambientParticles[i % presentation.ambientParticles.length];
      ctx.globalAlpha = particle === 'snow' || particle === 'mist' ? 0.32 : 0.2;
      ctx.fillStyle = particle === 'ash' ? '#c8beb0' : color;
      ctx.beginPath();
      ctx.ellipse(x, y, particle === 'rain' ? 1.2 : 2.2, particle === 'rain' ? 8 : 2.2, 0.3, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.restore();
  }

  function drawMap(viewport) {
    const level = getCurrentLevel();
    const pathSet = new Set(level.path.map(tileKey));
    const visibleBounds = getVisibleTileBounds(level, getCameraView(), viewport);
    const selectedTile = getSelectedTile();

    for (let y = visibleBounds.minY; y <= visibleBounds.maxY; y += 1) {
      for (let x = visibleBounds.minX; x <= visibleBounds.maxX; x += 1) {
        const tile = { x, y };
        const isPath = pathSet.has(tileKey(tile));
        const isSelected = Boolean(selectedTile && sameTile(tile, selectedTile));
        drawTerrainTile(tile, level.theme, isPath, isSelected);
        if (!isPath && !getTowerAt(tile)) {
          drawTileOrnament(tile, level.theme);
        }
      }
    }
  }

  function drawPathMarkers() {
    const level = getCurrentLevel();
    const start = project(level.path[0].x, level.path[0].y);
    const end = project(level.path[level.path.length - 1].x, level.path[level.path.length - 1].y);
    drawFlag(start.x, start.y - 18, '#86c66f');
    drawFlag(end.x, end.y - 18, '#d45f4c');
  }

  function drawTowers() {
    const { towers } = getRenderState();
    const sortedTowers = [...towers].sort((a, b) => a.tile.x + a.tile.y - (b.tile.x + b.tile.y));
    for (const tower of sortedTowers) {
      drawTower(tower);
    }
  }

  function drawTower(tower) {
    const point = project(tower.tile.x, tower.tile.y);
    const family = getTowerFamily(tower.typeId);
    const branch = tower.branchId ? family.branches[tower.branchId] : null;
    const color = branch?.color ?? family.accent;
    const attackProfile = getTowerAttackProfile(tower.typeId);
    const scale = getObjectScale();
    const height = (24 + tower.tier * 9) * scale;
    const width = (27 + tower.tier * 5) * scale;
    const selected = tower.id === getSelectedTowerId();

    ctx.save();
    ctx.translate(point.x, point.y);

    if (tower.typeId === 'eye-of-sauron') {
      drawGondorTower(width, height, color, tower.tier, selected);
      ctx.restore();
      return;
    }

    drawShadow(0, 9, width * 1.4, 11);

    ctx.fillStyle = towerBodyColor(tower.typeId);
    ctx.strokeStyle = selected ? '#ffe08a' : '#2a2a25';
    ctx.lineWidth = selected ? 3 : 1.4;
    ctx.beginPath();
    ctx.ellipse(0, 4, width * 0.74, 10, 0, 0, Math.PI * 2);
    ctx.fillStyle = '#2f332d';
    ctx.fill();
    ctx.fillStyle = towerBodyColor(tower.typeId);
    roundRect(-width / 2, -height, width, height, 4);
    ctx.fill();
    ctx.stroke();

    if (tower.typeId === 'orc-war-camp') {
      drawSpearBanner(width, height, color, tower.tier);
    } else if (tower.typeId === 'morgul-sorcery') {
      drawElvenCrown(width, height, color, tower.tier);
    } else {
      drawForgeTop(width, height, color, tower.tier);
    }

    if (tower.tier >= 4) {
      ctx.strokeStyle = color;
      ctx.globalAlpha = 0.6;
      ctx.beginPath();
      ctx.arc(0, -height + 8, 16 + tower.tier * 2, 0, Math.PI * 2);
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    drawAttackSigil(attackProfile.kind, width, height, color);

    ctx.restore();
  }

  function drawEnemies() {
    const { enemies, clock } = getRenderState();
    const sortedEnemies = [...enemies].sort((a, b) => a.pos.x + a.pos.y - (b.pos.x + b.pos.y));
    for (const enemy of sortedEnemies) {
      const point = project(enemy.pos.x, enemy.pos.y);
      const radius = 10 * enemy.size * getObjectScale();
      const gait = Math.sin(clock * 9 + enemy.phase);
      const bob = Math.sin(clock * 6 + enemy.phase) * Math.min(3, enemy.speed * 2.6);
      const bodyY = point.y - radius + bob;
      drawShadow(point.x, point.y + 8, radius * 2.2, 8 + Math.abs(gait) * 2);

      ctx.strokeStyle = '#1d1a17';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(point.x - radius * 0.42, point.y + 1);
      ctx.lineTo(point.x - radius * 0.72, point.y + 7 + gait * 3);
      ctx.moveTo(point.x + radius * 0.42, point.y + 1);
      ctx.lineTo(point.x + radius * 0.72, point.y + 7 - gait * 3);
      ctx.stroke();

      ctx.fillStyle = enemy.hitFlash > 0 ? '#fff0c4' : enemy.color;
      ctx.strokeStyle = enemy.trait.kind === 'standard' ? (enemy.slowTimer > 0 ? '#b5e8ff' : '#1d1a17') : enemy.trait.color;
      ctx.lineWidth = enemy.trait.kind === 'standard' ? (enemy.slowTimer > 0 ? 2.5 : 1.2) : 2.8;
      ctx.beginPath();
      ctx.ellipse(point.x, bodyY, radius, radius * 1.35, gait * 0.04, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
      ctx.beginPath();
      ctx.ellipse(point.x - radius * 0.26, bodyY - radius * 0.36, radius * 0.25, radius * 0.42, -0.4, 0, Math.PI * 2);
      ctx.fill();

      if (enemy.slowTimer > 0) {
        ctx.strokeStyle = 'rgba(181, 232, 255, 0.72)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.ellipse(point.x, point.y + 1, radius * 1.7, radius * 0.72, 0, 0, Math.PI * 2);
        ctx.stroke();
      }

      if (enemy.type === 'dwarf-warrior' || enemy.type === 'dwarven-sapper') {
        ctx.fillStyle = '#2f2926';
        ctx.fillRect(point.x - radius * 0.5, bodyY - radius * 1.5, radius, radius * 0.7);
      }
      if (enemy.type === 'elven-warden') {
        ctx.fillStyle = 'rgba(8,8,12,0.72)';
        ctx.beginPath();
        ctx.moveTo(point.x, bodyY - radius * 1.8);
        ctx.lineTo(point.x - radius * 1.6, bodyY + radius * 0.6);
        ctx.lineTo(point.x + radius * 1.6, bodyY + radius * 0.6);
        ctx.closePath();
        ctx.fill();
      }
      if (enemy.trait.label) {
        drawEnemyBadge(point.x, bodyY - radius * 2.15, enemy.trait);
      }

      drawHealthBar(point.x, bodyY - radius * 1.75, radius * 2.4, enemy.hp / enemy.maxHp);
    }
  }

  function drawProjectiles() {
    const { projectiles } = getRenderState();
    for (const projectile of projectiles) {
      const t = projectile.age / projectile.life;
      const from = project(projectile.from.x, projectile.from.y);
      const to = project(projectile.to.x, projectile.to.y);
      const arc = projectile.profileKind === 'pierce' || projectile.profileKind === 'chain' ? 10 : Math.sin(t * Math.PI) * 38;
      const x = lerp(from.x, to.x, t);
      const y = lerp(from.y - projectile.from.z * 34, to.y - projectile.to.z * 34, t) - arc;

      ctx.strokeStyle = projectile.color;
      ctx.fillStyle = projectile.color;
      ctx.lineWidth = projectile.kind === 'hammer' ? 4 : projectile.profileKind === 'pierce' ? 3 : 2;
      if (projectile.profileKind === 'chain') {
        ctx.shadowColor = projectile.color;
        ctx.shadowBlur = 14;
      }
      ctx.beginPath();
      ctx.moveTo(lerp(from.x, to.x, Math.max(0, t - 0.12)), lerp(from.y, to.y, Math.max(0, t - 0.12)) - arc * 0.6);
      ctx.lineTo(x, y);
      ctx.stroke();
      ctx.shadowBlur = 0;

      if (projectile.profileKind === 'precision') {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(Math.atan2(to.y - from.y, to.x - from.x));
        ctx.beginPath();
        ctx.moveTo(8, 0);
        ctx.lineTo(-6, -4);
        ctx.lineTo(-3, 0);
        ctx.lineTo(-6, 4);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
        continue;
      }

      if (projectile.profileKind === 'pierce') {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(Math.atan2(to.y - from.y, to.x - from.x));
        ctx.fillRect(-10, -2, 20, 4);
        ctx.beginPath();
        ctx.moveTo(13, 0);
        ctx.lineTo(3, -5);
        ctx.lineTo(3, 5);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
        continue;
      }

      ctx.beginPath();
      ctx.arc(x, y, projectile.kind === 'hammer' ? 7 : projectile.kind === 'light' ? 5 : 3, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function drawEffects() {
    const { effects } = getRenderState();
    for (const effect of effects) {
      const point = project(effect.pos.x, effect.pos.y);
      const t = effect.age / effect.life;
      ctx.save();
      ctx.globalAlpha = 1 - t;
      if (effect.kind === 'beam') {
        const from = project(effect.from.x, effect.from.y);
        const to = project(effect.to.x, effect.to.y);
        ctx.strokeStyle = effect.color;
        ctx.lineWidth = effect.width ?? 2;
        ctx.shadowColor = effect.color;
        ctx.shadowBlur = 12;
        ctx.beginPath();
        ctx.moveTo(from.x, from.y - 24);
        ctx.lineTo(to.x, to.y - 18);
        ctx.stroke();
      } else if (effect.kind === 'shockwave') {
        const tile = getScaledTileSize();
        ctx.strokeStyle = effect.color;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.ellipse(point.x, point.y, effect.radius * tile.w * 0.55 * (0.55 + t), effect.radius * tile.h * 0.55 * (0.55 + t), 0, 0, Math.PI * 2);
        ctx.stroke();
        ctx.fillStyle = 'rgba(255, 107, 53, 0.16)';
        ctx.beginPath();
        ctx.ellipse(point.x, point.y, effect.radius * tile.w * 0.34 * (0.6 + t), effect.radius * tile.h * 0.34 * (0.6 + t), 0, 0, Math.PI * 2);
        ctx.fill();
      } else if (effect.kind === 'mark') {
        ctx.strokeStyle = effect.color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(point.x - 13, point.y - 34);
        ctx.lineTo(point.x + 13, point.y - 34);
        ctx.moveTo(point.x, point.y - 47);
        ctx.lineTo(point.x, point.y - 21);
        ctx.stroke();
      } else if (effect.kind === 'splash') {
        const tile = getScaledTileSize();
        ctx.strokeStyle = effect.color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.ellipse(point.x, point.y, effect.radius * tile.w * 0.45 * (0.4 + t), effect.radius * tile.h * 0.45 * (0.4 + t), 0, 0, Math.PI * 2);
        ctx.stroke();
      } else if (effect.kind === 'hit') {
        ctx.strokeStyle = effect.color;
        ctx.lineWidth = effect.style === 'spear-line' ? 3 : 2;
        const rays = effect.style === 'light-chain' ? 8 : 5;
        if (effect.style === 'light-chain') {
          ctx.shadowColor = effect.color;
          ctx.shadowBlur = 10;
        }
        for (let i = 0; i < rays; i += 1) {
          const angle = i * 1.26 + t;
          ctx.beginPath();
          ctx.moveTo(point.x + Math.cos(angle) * 5, point.y - 14 + Math.sin(angle) * 5);
          ctx.lineTo(point.x + Math.cos(angle) * (14 + t * 10), point.y - 14 + Math.sin(angle) * (14 + t * 10));
          ctx.stroke();
        }
      } else if (effect.kind === 'build' || effect.kind === 'upgrade') {
        const tile = getScaledTileSize();
        ctx.strokeStyle = effect.color;
        ctx.fillStyle = effect.color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.ellipse(point.x, point.y - 2, tile.w * 0.25 * (1 + t), tile.h * 0.25 * (1 + t), 0, 0, Math.PI * 2);
        ctx.stroke();
        if (effect.kind === 'upgrade') {
          ctx.beginPath();
          ctx.arc(point.x, point.y - 44 - t * 12, 5 + t * 6, 0, Math.PI * 2);
          ctx.fill();
        }
      } else if (effect.kind === 'breach') {
        ctx.fillStyle = '#d45f4c';
        ctx.fillRect(point.x - 18, point.y - 38 - t * 8, 36, 5);
      } else if (effect.kind === 'reward') {
        ctx.fillStyle = '#f6d77b';
        ctx.font = '700 14px Inter, Segoe UI, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(effect.text, point.x, point.y - 30 - t * 28);
      } else {
        ctx.fillStyle = effect.color ?? '#d8ad45';
        ctx.beginPath();
        ctx.arc(point.x, point.y - 16 - t * 16, 8 + t * 8, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }
  }

  function drawHover() {
    const tile = getHoverTile();
    if (!tile) return;
    const tower = getTowerAt(tile);
    const placement = canPlaceTower(tile, getCurrentLevel(), getRenderState().towers);
    const color = tower ? '#ffe08a' : placement.ok ? '#8fd694' : '#d45f4c';
    drawDiamond(tile, 'rgba(255,255,255,0.06)', color, 3);

    const selectedTowerType = getSelectedTowerType();
    if (selectedTowerType && placement.ok && !tower) {
      const point = project(tile.x, tile.y);
      const family = getTowerFamily(selectedTowerType);
      ctx.globalAlpha = getRenderState().gold >= family.baseCost ? 0.78 : 0.38;
      ctx.fillStyle = family.accent;
      ctx.beginPath();
      ctx.arc(point.x, point.y - 20, 12, 0, Math.PI * 2);
      ctx.fill();
      ctx.globalAlpha = 1;
    }
  }

  function drawDiamond(tile, fill, stroke, lineWidth) {
    const point = project(tile.x, tile.y);
    const scaledTile = getScaledTileSize();
    ctx.beginPath();
    ctx.moveTo(point.x, point.y - scaledTile.h / 2);
    ctx.lineTo(point.x + scaledTile.w / 2, point.y);
    ctx.lineTo(point.x, point.y + scaledTile.h / 2);
    ctx.lineTo(point.x - scaledTile.w / 2, point.y);
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.strokeStyle = stroke;
    ctx.lineWidth = lineWidth;
    ctx.fill();
    ctx.stroke();
  }

  function drawTerrainTile(tile, theme, isPath, selected) {
    const point = project(tile.x, tile.y);
    const scaledTile = getScaledTileSize();
    const seed = hashTile(tile);
    const palette = isPath ? pathSurface(theme) : groundSurface(theme);
    const variation = ((seed % 17) - 8) / 100;
    const patchCount = isPath ? 2 : 3 + (seed % 2);

    ctx.save();
    ctx.beginPath();
    ctx.moveTo(point.x, point.y - scaledTile.h / 2);
    ctx.lineTo(point.x + scaledTile.w / 2, point.y);
    ctx.lineTo(point.x, point.y + scaledTile.h / 2);
    ctx.lineTo(point.x - scaledTile.w / 2, point.y);
    ctx.closePath();
    ctx.clip();

    ctx.fillStyle = palette.base;
    ctx.fillRect(point.x - scaledTile.w / 2, point.y - scaledTile.h / 2, scaledTile.w, scaledTile.h);

    ctx.globalAlpha = 0.18 + variation;
    ctx.fillStyle = palette.light;
    ctx.beginPath();
    ctx.moveTo(point.x, point.y - scaledTile.h / 2);
    ctx.lineTo(point.x + scaledTile.w / 2, point.y);
    ctx.lineTo(point.x, point.y + scaledTile.h * 0.08);
    ctx.lineTo(point.x - scaledTile.w / 2, point.y);
    ctx.closePath();
    ctx.fill();

    ctx.globalAlpha = 0.16 - variation * 0.5;
    ctx.fillStyle = palette.shadow;
    ctx.beginPath();
    ctx.moveTo(point.x - scaledTile.w / 2, point.y);
    ctx.lineTo(point.x, point.y + scaledTile.h / 2);
    ctx.lineTo(point.x + scaledTile.w / 2, point.y);
    ctx.lineTo(point.x, point.y + scaledTile.h * 0.08);
    ctx.closePath();
    ctx.fill();

    for (let i = 0; i < patchCount; i += 1) {
      const px = point.x + (((seed >> (i * 3)) % 19) - 9) * scaledTile.w * 0.018;
      const py = point.y + (((seed >> (i * 4 + 1)) % 13) - 6) * scaledTile.h * 0.032;
      ctx.globalAlpha = isPath ? 0.11 : 0.08 + ((seed + i) % 4) * 0.012;
      ctx.fillStyle = i % 2 === 0 ? palette.patch : palette.light;
      ctx.beginPath();
      ctx.ellipse(px, py, scaledTile.w * (0.08 + (i % 3) * 0.025), scaledTile.h * 0.055, -0.35 + i * 0.18, 0, Math.PI * 2);
      ctx.fill();
    }

    ctx.globalAlpha = isPath ? 0.14 : 0.1;
    ctx.strokeStyle = palette.detail;
    ctx.lineWidth = Math.max(1, scaledTile.w * 0.012);
    for (let i = 0; i < (isPath ? 3 : 2); i += 1) {
      const y = point.y - scaledTile.h * 0.12 + i * scaledTile.h * 0.11 + ((seed >> i) % 5) * scaledTile.h * 0.006;
      ctx.beginPath();
      ctx.moveTo(point.x - scaledTile.w * 0.23, y);
      ctx.bezierCurveTo(point.x - scaledTile.w * 0.06, y - scaledTile.h * 0.04, point.x + scaledTile.w * 0.08, y + scaledTile.h * 0.035, point.x + scaledTile.w * 0.24, y - scaledTile.h * 0.01);
      ctx.stroke();
    }

    ctx.restore();

    ctx.save();
    ctx.beginPath();
    ctx.moveTo(point.x, point.y - scaledTile.h / 2);
    ctx.lineTo(point.x + scaledTile.w / 2, point.y);
    ctx.lineTo(point.x, point.y + scaledTile.h / 2);
    ctx.lineTo(point.x - scaledTile.w / 2, point.y);
    ctx.closePath();
    ctx.strokeStyle = selected ? '#f5ce73' : palette.edge;
    ctx.lineWidth = selected ? 2.4 : isPath ? 1.3 : 0.75;
    ctx.stroke();
    ctx.restore();
  }

  function drawTileOrnament(tile, theme) {
    const seed = hashTile(tile);
    if (seed % 7 > 1) return;

    const point = project(tile.x, tile.y);
    ctx.save();
    ctx.translate(point.x + ((seed % 5) - 2) * 3, point.y - 8 + ((seed % 3) - 1) * 2);
    ctx.globalAlpha = 0.78;

    if (theme === 'snow') {
      ctx.fillStyle = 'rgba(230, 238, 232, 0.72)';
      ctx.fillRect(-8, -2, 16, 3);
    } else if (theme === 'moria' || theme === 'mordor' || theme === 'black-gate') {
      ctx.fillStyle = theme === 'moria' ? '#3a3834' : '#382820';
      ctx.beginPath();
      ctx.moveTo(-7, 5);
      ctx.lineTo(-1, -8);
      ctx.lineTo(8, 4);
      ctx.closePath();
      ctx.fill();
    } else if (theme === 'rohan' || theme === 'gondor') {
      ctx.strokeStyle = '#d0bd6a';
      ctx.lineWidth = 1.5;
      for (let i = -1; i <= 1; i += 1) {
        ctx.beginPath();
        ctx.moveTo(i * 4, 4);
        ctx.lineTo(i * 5 + 2, -7);
        ctx.stroke();
      }
    } else {
      ctx.fillStyle = theme === 'lorien' || theme === 'rivendell' ? '#bff7e1' : '#78a662';
      ctx.beginPath();
      ctx.moveTo(0, -12);
      ctx.lineTo(-8, 4);
      ctx.lineTo(8, 4);
      ctx.closePath();
      ctx.fill();
    }

    ctx.restore();
  }

  function groundSurface(theme) {
    const surfaces = {
      shire: { base: '#668f59', light: '#7da86d', shadow: '#4e724a', patch: '#5f854f', detail: '#d0c67f', edge: 'rgba(16, 27, 18, 0.32)' },
      rivendell: { base: '#5c8872', light: '#76a58b', shadow: '#416957', patch: '#507d68', detail: '#b9e1c9', edge: 'rgba(16, 28, 24, 0.32)' },
      snow: { base: '#a5b4aa', light: '#c8d1c7', shadow: '#83968d', patch: '#93a69b', detail: '#eef4ec', edge: 'rgba(42, 52, 48, 0.28)' },
      moria: { base: '#5f625a', light: '#777970', shadow: '#454840', patch: '#555850', detail: '#a3a094', edge: 'rgba(20, 22, 20, 0.38)' },
      lorien: { base: '#719a66', light: '#91b77a', shadow: '#57784f', patch: '#678d5d', detail: '#d4d899', edge: 'rgba(20, 34, 18, 0.3)' },
      rohan: { base: '#948c5d', light: '#ada268', shadow: '#746d49', patch: '#898055', detail: '#d6c879', edge: 'rgba(38, 34, 18, 0.3)' },
      'helms-deep': { base: '#716f64', light: '#888477', shadow: '#56554d', patch: '#67655c', detail: '#bdb59e', edge: 'rgba(27, 26, 22, 0.34)' },
      gondor: { base: '#728168', light: '#899a78', shadow: '#596950', patch: '#68775e', detail: '#d8ca83', edge: 'rgba(18, 29, 18, 0.32)' },
      mordor: { base: '#605646', light: '#78694f', shadow: '#473d34', patch: '#554b3f', detail: '#b08b64', edge: 'rgba(21, 17, 14, 0.38)' },
      'black-gate': { base: '#565049', light: '#6d655b', shadow: '#3e3934', patch: '#4e4842', detail: '#a99576', edge: 'rgba(16, 14, 12, 0.4)' },
    };
    return surfaces[theme] ?? surfaces.shire;
  }

  function pathSurface(theme) {
    const surfaces = {
      snow: { base: '#bfb8a8', light: '#d2cdbc', shadow: '#9b9485', patch: '#a89f8e', detail: '#eee4cb', edge: 'rgba(48, 43, 35, 0.34)' },
      moria: { base: '#45413a', light: '#5b554c', shadow: '#302d29', patch: '#39352f', detail: '#8f8678', edge: 'rgba(10, 10, 9, 0.45)' },
      mordor: { base: '#4d3a31', light: '#604739', shadow: '#382a25', patch: '#45332d', detail: '#9f7058', edge: 'rgba(15, 10, 9, 0.46)' },
      'black-gate': { base: '#403832', light: '#554840', shadow: '#2f2925', patch: '#382f2a', detail: '#866a57', edge: 'rgba(12, 10, 9, 0.48)' },
    };
    return surfaces[theme] ?? { base: '#927b58', light: '#aa9167', shadow: '#735f45', patch: '#836d4f', detail: '#d0b47b', edge: 'rgba(39, 29, 18, 0.38)' };
  }

  function hashTile(tile) {
    return Math.abs((tile.x + 11) * 73856093 ^ (tile.y + 17) * 19349663);
  }

  function towerBodyColor(typeId) {
    const colors = {
      'eye-of-sauron': '#3b2624',
      'orc-war-camp': '#4a3f2a',
      'morgul-sorcery': '#23453c',
      'mordor-forge': '#57443a',
    };
    return colors[typeId] ?? '#71716a';
  }

  function drawAttackSigil(kind, width, height, color) {
    const { clock } = getRenderState();
    ctx.save();
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.globalAlpha = 0.92;
    if (kind === 'precision') {
      ctx.beginPath();
      ctx.arc(0, -height * 0.48, 7, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(-12, -height * 0.48);
      ctx.lineTo(12, -height * 0.48);
      ctx.moveTo(0, -height * 0.48 - 12);
      ctx.lineTo(0, -height * 0.48 + 12);
      ctx.stroke();
    } else if (kind === 'pierce') {
      for (let i = -1; i <= 1; i += 1) {
        ctx.beginPath();
        ctx.moveTo(i * 7, -height - 28);
        ctx.lineTo(i * 7, -height + 4);
        ctx.stroke();
      }
    } else if (kind === 'chain') {
      for (let i = 0; i < 3; i += 1) {
        ctx.beginPath();
        ctx.arc((i - 1) * 8, -height * 0.58 + Math.sin(clock * 3 + i) * 2, 5, 0, Math.PI * 2);
        ctx.stroke();
      }
    } else {
      ctx.beginPath();
      ctx.ellipse(0, -height - 2, width * 0.35, 8, 0, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.restore();
  }

  function drawGondorTower(width, height, color, tier, selected) {
    const tile = getScaledTileSize();
    const baseY = 1;
    const bodyBottomY = -7;
    const topY = -height - 5;
    const capY = topY - 8;
    const baseHalf = Math.min(width * 0.62, tile.w * 0.31);
    const secondBaseHalf = Math.min(width * 0.48, tile.w * 0.24);
    const bodyBaseHalf = Math.min(width * 0.42, tile.w * 0.23);
    const bodyTopHalf = bodyBaseHalf * 0.68;

    ctx.save();
    drawShadow(0, 13, Math.min(width * 1.45, tile.w * 0.64), 12);

    ctx.fillStyle = 'rgba(13, 16, 15, 0.22)';
    ctx.beginPath();
    ctx.ellipse(0, 9, baseHalf * 0.92, 9, 0, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#c8c0aa';
    ctx.beginPath();
    ctx.moveTo(0, baseY - 15);
    ctx.lineTo(baseHalf, baseY);
    ctx.lineTo(0, baseY + 17);
    ctx.lineTo(-baseHalf, baseY);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#ddd5bd';
    ctx.beginPath();
    ctx.moveTo(0, baseY - 24);
    ctx.lineTo(secondBaseHalf, baseY - 10);
    ctx.lineTo(0, baseY + 4);
    ctx.lineTo(-secondBaseHalf, baseY - 10);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#b5ac91';
    ctx.beginPath();
    ctx.moveTo(-secondBaseHalf, baseY - 10);
    ctx.lineTo(0, baseY + 4);
    ctx.lineTo(0, baseY + 12);
    ctx.lineTo(-secondBaseHalf, baseY - 2);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#9b9479';
    ctx.beginPath();
    ctx.moveTo(secondBaseHalf, baseY - 10);
    ctx.lineTo(0, baseY + 4);
    ctx.lineTo(0, baseY + 12);
    ctx.lineTo(secondBaseHalf, baseY - 2);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#a9a086';
    ctx.beginPath();
    ctx.moveTo(-baseHalf, baseY);
    ctx.lineTo(0, baseY + 17);
    ctx.lineTo(0, baseY + 25);
    ctx.lineTo(-baseHalf, baseY + 8);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#8f886f';
    ctx.beginPath();
    ctx.moveTo(baseHalf, baseY);
    ctx.lineTo(0, baseY + 17);
    ctx.lineTo(0, baseY + 25);
    ctx.lineTo(baseHalf, baseY + 8);
    ctx.closePath();
    ctx.fill();

    if (selected) {
      ctx.strokeStyle = '#ffe08a';
      ctx.lineWidth = 2.4;
      ctx.beginPath();
      ctx.moveTo(0, baseY - 15);
      ctx.lineTo(baseHalf, baseY);
      ctx.lineTo(0, baseY + 17);
      ctx.lineTo(-baseHalf, baseY);
      ctx.closePath();
      ctx.stroke();
    }

    ctx.strokeStyle = 'rgba(55, 58, 50, 0.45)';
    ctx.lineWidth = 1;
    for (let i = -1; i <= 1; i += 1) {
      ctx.beginPath();
      ctx.moveTo(i * baseHalf * 0.28, baseY - 10 + Math.abs(i) * 3);
      ctx.lineTo(i * baseHalf * 0.36, baseY + 13);
      ctx.stroke();
    }

    ctx.fillStyle = '#ebe6d5';
    ctx.beginPath();
    ctx.moveTo(-bodyBaseHalf, bodyBottomY);
    ctx.lineTo(-bodyTopHalf, topY);
    ctx.lineTo(bodyTopHalf, topY);
    ctx.lineTo(bodyBaseHalf, bodyBottomY);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#cfc8b5';
    ctx.beginPath();
    ctx.moveTo(-bodyBaseHalf, bodyBottomY);
    ctx.lineTo(-bodyTopHalf, topY);
    ctx.lineTo(-bodyTopHalf - width * 0.12, topY + 12);
    ctx.lineTo(-bodyBaseHalf - width * 0.12, bodyBottomY + 8);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#f8f3e3';
    ctx.beginPath();
    ctx.moveTo(bodyBaseHalf, bodyBottomY);
    ctx.lineTo(bodyTopHalf, topY);
    ctx.lineTo(bodyTopHalf + width * 0.1, topY + 11);
    ctx.lineTo(bodyBaseHalf + width * 0.1, bodyBottomY + 7);
    ctx.closePath();
    ctx.fill();

    ctx.strokeStyle = 'rgba(39, 42, 39, 0.58)';
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    ctx.moveTo(-bodyBaseHalf, bodyBottomY);
    ctx.lineTo(-bodyTopHalf, topY);
    ctx.lineTo(bodyTopHalf, topY);
    ctx.lineTo(bodyBaseHalf, bodyBottomY);
    ctx.closePath();
    ctx.stroke();

    ctx.strokeStyle = 'rgba(83, 88, 78, 0.38)';
    ctx.lineWidth = 1;
    for (let i = 0; i < Math.min(5, tier + 2); i += 1) {
      const y = bodyBottomY - 11 - i * 13;
      const inset = i * width * 0.025;
      ctx.beginPath();
      ctx.moveTo(-bodyBaseHalf + 5 + inset, y);
      ctx.lineTo(bodyBaseHalf - 5 - inset, y - 3);
      ctx.stroke();
    }
    for (const x of [-0.28, 0, 0.28]) {
      ctx.beginPath();
      ctx.moveTo(x * width, bodyBottomY - 2);
      ctx.lineTo(x * width * 0.72, topY + 8);
      ctx.stroke();
    }

    const bevelTop = topY + 8;
    ctx.fillStyle = 'rgba(255, 255, 255, 0.18)';
    ctx.beginPath();
    ctx.moveTo(-bodyTopHalf + 2, topY + 4);
    ctx.lineTo(-bodyBaseHalf + 5, bodyBottomY - 2);
    ctx.lineTo(-bodyBaseHalf + width * 0.17, bodyBottomY + 1);
    ctx.lineTo(-bodyTopHalf + width * 0.12, bevelTop);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = 'rgba(87, 85, 74, 0.18)';
    ctx.beginPath();
    ctx.moveTo(bodyTopHalf - 2, topY + 4);
    ctx.lineTo(bodyBaseHalf - 5, bodyBottomY - 2);
    ctx.lineTo(bodyBaseHalf - width * 0.17, bodyBottomY + 1);
    ctx.lineTo(bodyTopHalf - width * 0.12, bevelTop);
    ctx.closePath();
    ctx.fill();

    ctx.strokeStyle = 'rgba(255, 255, 255, 0.36)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(-bodyTopHalf + 4, topY + 6);
    ctx.lineTo(-bodyBaseHalf + 8, bodyBottomY - 1);
    ctx.stroke();

    ctx.strokeStyle = 'rgba(58, 60, 53, 0.34)';
    ctx.beginPath();
    ctx.moveTo(bodyTopHalf - 5, topY + 6);
    ctx.lineTo(bodyBaseHalf - 8, bodyBottomY - 1);
    ctx.stroke();

    ctx.fillStyle = '#d8d1be';
    for (const side of [-1, 1]) {
      const x = side * width * 0.44;
      ctx.beginPath();
      ctx.moveTo(x, bodyBottomY + 1);
      ctx.lineTo(x + side * width * 0.16, bodyBottomY + 7);
      ctx.lineTo(x + side * width * 0.08, topY + 20);
      ctx.lineTo(x - side * width * 0.05, topY + 15);
      ctx.closePath();
      ctx.fill();
    }

    drawGondorHangingBanner(-width * 0.43, -height * 0.55, -1, height, color);
    drawGondorHangingBanner(width * 0.43, -height * 0.52, 1, height, color);

    drawGondorArchedWindow(0, -height * 0.55, 10, 21, '#202b35');
    if (tier >= 2) {
      drawGondorArchedWindow(-width * 0.23, -height * 0.38, 7, 15, '#2b3741');
      drawGondorArchedWindow(width * 0.23, -height * 0.38, 7, 15, '#2b3741');
    }
    if (tier >= 4) {
      drawGondorArchedWindow(0, -height * 0.75, 7, 16, '#1b2530');
    }

    ctx.fillStyle = '#d9d2be';
    ctx.strokeStyle = 'rgba(42, 45, 40, 0.7)';
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    ctx.moveTo(-width * 0.5, topY + 4);
    ctx.lineTo(-width * 0.38, topY - 8);
    ctx.lineTo(width * 0.38, topY - 8);
    ctx.lineTo(width * 0.5, topY + 4);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = '#aaa58f';
    ctx.beginPath();
    ctx.moveTo(-width * 0.5, topY + 4);
    ctx.lineTo(-width * 0.38, topY - 8);
    ctx.lineTo(-width * 0.38, topY - 1);
    ctx.lineTo(-width * 0.49, topY + 11);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#f1ead7';
    ctx.beginPath();
    ctx.moveTo(width * 0.5, topY + 4);
    ctx.lineTo(width * 0.38, topY - 8);
    ctx.lineTo(width * 0.38, topY - 1);
    ctx.lineTo(width * 0.49, topY + 11);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#f8f4e8';
    ctx.beginPath();
    ctx.moveTo(0, capY - 10);
    ctx.lineTo(width * 0.5, capY);
    ctx.lineTo(0, capY + 10);
    ctx.lineTo(-width * 0.5, capY);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = '#bdb8a6';
    ctx.beginPath();
    ctx.moveTo(-width * 0.5, capY);
    ctx.lineTo(0, capY + 10);
    ctx.lineTo(0, capY + 16);
    ctx.lineTo(-width * 0.5, capY + 6);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#ded7c5';
    ctx.beginPath();
    ctx.moveTo(width * 0.5, capY);
    ctx.lineTo(0, capY + 10);
    ctx.lineTo(0, capY + 16);
    ctx.lineTo(width * 0.5, capY + 6);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = '#c4c2b8';
    for (let i = -3; i <= 3; i += 1) {
      const blockWidth = width * 0.1;
      const blockHeight = i % 2 === 0 ? 12 : 9;
      const x = i * width * 0.15 - blockWidth / 2;
      const y = capY - blockHeight;
      ctx.fillRect(x, y, blockWidth, blockHeight);
      ctx.fillStyle = i < 0 ? '#aaa693' : '#e4decd';
      ctx.fillRect(x + blockWidth * 0.68, y + 2, blockWidth * 0.32, blockHeight - 2);
      ctx.fillStyle = '#c4c2b8';
    }

    ctx.fillStyle = '#efe8d3';
    for (const x of [-0.27, 0, 0.27]) {
      ctx.beginPath();
      ctx.moveTo(x * width, capY - 31);
      ctx.lineTo(x * width - 5, capY - 10);
      ctx.lineTo(x * width + 5, capY - 10);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = 'rgba(91, 88, 75, 0.22)';
      ctx.beginPath();
      ctx.moveTo(x * width, capY - 31);
      ctx.lineTo(x * width + 5, capY - 10);
      ctx.lineTo(x * width + 1, capY - 10);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = '#efe8d3';
    }

    ctx.strokeStyle = 'rgba(243, 211, 124, 0.82)';
    ctx.lineWidth = 1.8;
    ctx.beginPath();
    ctx.moveTo(0, capY - 26);
    ctx.lineTo(0, capY + 3);
    ctx.moveTo(-10, capY - 12);
    ctx.lineTo(10, capY - 12);
    ctx.stroke();

    ctx.fillStyle = '#f3d37c';
    ctx.shadowColor = 'rgba(243, 211, 124, 0.85)';
    ctx.shadowBlur = tier >= 4 ? 18 : 9;
    ctx.beginPath();
    ctx.moveTo(0, capY - 25 - tier * 0.7);
    ctx.lineTo(7 + tier * 0.4, capY - 14);
    ctx.lineTo(0, capY - 4);
    ctx.lineTo(-7 - tier * 0.4, capY - 14);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = 'rgba(255, 246, 184, 0.86)';
    ctx.beginPath();
    ctx.moveTo(0, capY - 20 - tier * 0.4);
    ctx.lineTo(3.5, capY - 14);
    ctx.lineTo(0, capY - 8);
    ctx.lineTo(-3.5, capY - 14);
    ctx.closePath();
    ctx.fill();
    ctx.shadowBlur = 0;

    ctx.restore();
  }

  function drawGondorHangingBanner(x, y, side, height, color) {
    const bannerWidth = 9;
    const bannerHeight = Math.max(20, height * 0.32);

    ctx.save();
    ctx.translate(x, y);
    ctx.fillStyle = '#17283d';
    ctx.strokeStyle = 'rgba(248, 250, 252, 0.72)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.bezierCurveTo(side * 3, bannerHeight * 0.18, side * 2, bannerHeight * 0.55, side * 4, bannerHeight);
    ctx.lineTo(side * bannerWidth, bannerHeight - 5);
    ctx.bezierCurveTo(side * (bannerWidth - 2), bannerHeight * 0.54, side * bannerWidth, bannerHeight * 0.15, side * (bannerWidth - 1), 0);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    ctx.strokeStyle = color;
    ctx.globalAlpha = 0.9;
    ctx.beginPath();
    ctx.moveTo(side * 4, 4);
    ctx.lineTo(side * 5, bannerHeight - 8);
    ctx.stroke();
    ctx.restore();
  }

  function drawGondorArchedWindow(x, y, width, height, fill) {
    ctx.save();
    ctx.fillStyle = fill;
    ctx.beginPath();
    ctx.moveTo(x - width / 2, y + height / 2);
    ctx.lineTo(x - width / 2, y - height * 0.08);
    ctx.quadraticCurveTo(x, y - height * 0.58, x + width / 2, y - height * 0.08);
    ctx.lineTo(x + width / 2, y + height / 2);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = 'rgba(245, 241, 226, 0.65)';
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.restore();
  }

  function drawSpearBanner(width, height, color, tier) {
    ctx.strokeStyle = '#241d15';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(0, -height - 24);
    ctx.lineTo(0, -height + 8);
    ctx.stroke();
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.moveTo(2, -height - 23);
    ctx.lineTo(22, -height - 15);
    ctx.lineTo(2, -height - 8);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    for (let i = 0; i < 2 + Math.min(3, tier); i += 1) {
      const offset = (i - 2) * 7;
      ctx.beginPath();
      ctx.moveTo(offset, -height + 2);
      ctx.lineTo(offset + 10, -height - 18);
      ctx.stroke();
    }
  }

  function drawElvenCrown(width, height, color, tier) {
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    for (let i = 0; i < 4 + tier; i += 1) {
      const angle = (Math.PI * 2 * i) / (4 + tier);
      ctx.beginPath();
      ctx.moveTo(0, -height + 2);
      ctx.lineTo(Math.cos(angle) * width * 0.62, -height + Math.sin(angle) * 11);
      ctx.stroke();
    }
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(0, -height - 4, 7 + tier, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = 'rgba(255,255,255,0.38)';
    ctx.beginPath();
    ctx.moveTo(-width * 0.36, -height + 9);
    ctx.quadraticCurveTo(0, -height - 18, width * 0.36, -height + 9);
    ctx.stroke();
  }

  function drawForgeTop(width, height, color, tier) {
    ctx.fillStyle = '#2c2521';
    ctx.fillRect(width * 0.18, -height - 18, 9, 20);
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(0, -height - 2, 8 + tier, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = 'rgba(230,230,220,0.4)';
    ctx.beginPath();
    ctx.moveTo(width * 0.18 + 5, -height - 22);
    ctx.quadraticCurveTo(width * 0.34, -height - 32, width * 0.1, -height - 42);
    ctx.stroke();
    ctx.fillStyle = 'rgba(255, 107, 53, 0.55)';
    for (let i = 0; i < Math.min(4, tier); i += 1) {
      ctx.beginPath();
      ctx.arc(-width * 0.28 + i * 6, -height + 10, 3, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  function drawFlag(x, y, color) {
    ctx.strokeStyle = '#201913';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x, y - 42);
    ctx.stroke();
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.moveTo(x + 2, y - 42);
    ctx.lineTo(x + 32, y - 34);
    ctx.lineTo(x + 2, y - 25);
    ctx.closePath();
    ctx.fill();
  }

  function drawHealthBar(x, y, width, ratio) {
    ctx.fillStyle = 'rgba(12, 10, 8, 0.78)';
    ctx.fillRect(x - width / 2 - 1, y - 1, width + 2, 7);
    ctx.fillStyle = '#251f1b';
    ctx.fillRect(x - width / 2, y, width, 5);
    ctx.fillStyle = ratio > 0.45 ? '#86c66f' : '#d45f4c';
    ctx.fillRect(x - width / 2, y, width * Math.max(0, ratio), 5);
  }

  function drawEnemyBadge(x, y, trait) {
    ctx.save();
    ctx.font = '700 10px Inter, Segoe UI, sans-serif';
    ctx.textAlign = 'center';
    const width = Math.max(34, ctx.measureText(trait.label).width + 12);
    ctx.fillStyle = 'rgba(16, 17, 17, 0.82)';
    ctx.strokeStyle = trait.color;
    ctx.lineWidth = 1;
    roundRect(x - width / 2, y - 11, width, 16, 4);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = trait.color;
    ctx.fillText(trait.label, x, y);
    ctx.restore();
  }

  function drawShadow(x, y, width, height) {
    ctx.fillStyle = 'rgba(0,0,0,0.26)';
    ctx.beginPath();
    ctx.ellipse(x, y, width / 2, height / 2, 0, 0, Math.PI * 2);
    ctx.fill();
  }

  function roundRect(x, y, width, height, radius) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    ctx.lineTo(x + radius, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  return {
    draw,
    drawBackdrop,
    drawMap,
    drawPathMarkers,
    drawTowers,
    drawEnemies,
    drawProjectiles,
    drawEffects,
  };
  }

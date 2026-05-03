export const baseTileSize = { w: 400, h: 200 };

export function getScaledTileSize(viewScale, tileSize = baseTileSize) {
  return {
    w: tileSize.w * viewScale,
    h: tileSize.h * viewScale,
  };
}

export function getViewScale({
  viewport,
  map,
  tileSize = baseTileSize,
  maxScale = 0.68,
  desktopMinScale = 0.48,
  compactMinScale = 0.43,
}) {
  const mapWidth = ((map.width + map.height) * tileSize.w) / 2;
  const mapHeight = ((map.width + map.height) * tileSize.h) / 2 + 120;
  const fitScale = Math.min((viewport.width * 0.9) / mapWidth, (viewport.height * 0.68) / mapHeight);
  const minScale = viewport.width >= 1180 ? desktopMinScale : compactMinScale;
  return Math.min(maxScale, Math.max(minScale, fitScale));
}

export function getOrigin({ viewport, map, tileSize, minY = 142, yRatio = 0.22 }) {
  return {
    x: viewport.width / 2 - ((map.width - map.height) * tileSize.w) / 4,
    y: Math.max(minY, viewport.height * yRatio),
  };
}

export function projectWorldTile(tile, view) {
  return {
    x: (tile.x - tile.y) * (view.tileSize.w / 2) + view.origin.x,
    y: (tile.x + tile.y) * (view.tileSize.h / 2) + view.origin.y,
  };
}

export function projectTile(tile, view) {
  const point = projectWorldTile(tile, view);
  return {
    x: point.x + view.camera.x,
    y: point.y + view.camera.y,
  };
}

export function getMapWorldBounds(map, view, { topPadding = 140, bottomPadding = 120 } = {}) {
  let minX = Number.POSITIVE_INFINITY;
  let maxX = Number.NEGATIVE_INFINITY;
  let minY = Number.POSITIVE_INFINITY;
  let maxY = Number.NEGATIVE_INFINITY;

  for (const point of [
    projectWorldTile({ x: 0, y: 0 }, view),
    projectWorldTile({ x: map.width - 1, y: 0 }, view),
    projectWorldTile({ x: 0, y: map.height - 1 }, view),
    projectWorldTile({ x: map.width - 1, y: map.height - 1 }, view),
  ]) {
    minX = Math.min(minX, point.x - view.tileSize.w / 2);
    maxX = Math.max(maxX, point.x + view.tileSize.w / 2);
    minY = Math.min(minY, point.y - view.tileSize.h / 2 - topPadding);
    maxY = Math.max(maxY, point.y + view.tileSize.h / 2 + bottomPadding);
  }

  return { minX, maxX, minY, maxY };
}

export function clampCamera(camera, { map, viewport, origin, tileSize, margin = 120 }) {
  const bounds = getMapWorldBounds(map, { origin, tileSize });
  const minX = viewport.width - margin - bounds.maxX;
  const maxX = margin - bounds.minX;
  const minY = viewport.height - margin - bounds.maxY;
  const maxY = margin - bounds.minY;

  return {
    x: minX > maxX ? (minX + maxX) / 2 : clamp(camera.x, minX, maxX),
    y: minY > maxY ? (minY + maxY) / 2 : clamp(camera.y, minY, maxY),
  };
}

export function pickTileAt(point, map, view) {
  let best = null;
  let bestDistance = Number.POSITIVE_INFINITY;

  for (let ty = 0; ty < map.height; ty += 1) {
    for (let tx = 0; tx < map.width; tx += 1) {
      const projected = projectTile({ x: tx, y: ty }, view);
      const normalized =
        Math.abs(point.x - projected.x) / (view.tileSize.w / 2) +
        Math.abs(point.y - projected.y) / (view.tileSize.h / 2);
      if (normalized <= 1 && normalized < bestDistance) {
        best = { x: tx, y: ty };
        bestDistance = normalized;
      }
    }
  }

  return best;
}

export function getVisibleTileBounds(map, view, viewport) {
  const padding = Math.max(view.tileSize.w, view.tileSize.h) * 1.5;
  let minX = map.width - 1;
  let minY = map.height - 1;
  let maxX = 0;
  let maxY = 0;

  for (let y = 0; y < map.height; y += 1) {
    for (let x = 0; x < map.width; x += 1) {
      const point = projectTile({ x, y }, view);
      if (
        point.x >= -padding &&
        point.x <= viewport.width + padding &&
        point.y >= -padding &&
        point.y <= viewport.height + padding
      ) {
        minX = Math.min(minX, x);
        minY = Math.min(minY, y);
        maxX = Math.max(maxX, x);
        maxY = Math.max(maxY, y);
      }
    }
  }

  return {
    minX: Math.max(0, minX - 1),
    minY: Math.max(0, minY - 1),
    maxX: Math.min(map.width - 1, maxX + 1),
    maxY: Math.min(map.height - 1, maxY + 1),
  };
}

export function getObjectScale(tileSize) {
  return Math.max(0.96, Math.min(1.42, tileSize.w / 64));
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

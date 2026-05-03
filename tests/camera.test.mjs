import assert from 'node:assert/strict';
import test from 'node:test';

import {
  baseTileSize,
  clampCamera,
  getObjectScale,
  getScaledTileSize,
  getVisibleTileBounds,
  pickTileAt,
  projectTile,
  projectWorldTile,
} from '../src/camera.js';

const view = {
  origin: { x: 520, y: 145 },
  camera: { x: -30, y: 18 },
  tileSize: { w: 200, h: 100 },
};

test('camera uses the logical isometric tile size as its default base', () => {
  assert.deepEqual(baseTileSize, { w: 400, h: 200 });
  assert.deepEqual(getScaledTileSize(0.5), { w: 200, h: 100 });
});

test('world projection keeps camera offset separate from isometric math', () => {
  assert.deepEqual(projectWorldTile({ x: 3, y: 1 }, view), { x: 720, y: 345 });
  assert.deepEqual(projectTile({ x: 3, y: 1 }, view), { x: 690, y: 363 });
});

test('object scale follows projected tile width with stable min and max limits', () => {
  assert.equal(getObjectScale({ w: 20, h: 10 }), 0.96);
  assert.equal(getObjectScale({ w: 64, h: 32 }), 1);
  assert.equal(getObjectScale({ w: 400, h: 200 }), 1.42);
});

test('camera clamp keeps large maps within viewport margins', () => {
  const map = { width: 32, height: 32 };
  const viewport = { width: 1000, height: 640 };
  const clamped = clampCamera(
    { x: 99999, y: -99999 },
    {
      map,
      viewport,
      origin: view.origin,
      tileSize: view.tileSize,
      margin: 120,
    }
  );

  assert.deepEqual(clamped, { x: 2800, y: -2895 });
});

test('tile picking returns the diamond under a screen point', () => {
  const map = { width: 8, height: 8 };
  const point = projectTile({ x: 3, y: 1 }, view);

  assert.deepEqual(pickTileAt(point, map, view), { x: 3, y: 1 });
  assert.equal(pickTileAt({ x: -500, y: -500 }, map, view), null);
});

test('visible tile bounds include on-screen tiles and stay inside the map', () => {
  const bounds = getVisibleTileBounds(
    { width: 32, height: 32 },
    {
      origin: { x: 520, y: 145 },
      camera: { x: 0, y: 0 },
      tileSize: { w: 200, h: 100 },
    },
    { width: 1000, height: 640 }
  );

  assert.deepEqual(bounds, { minX: 0, minY: 0, maxX: 12, maxY: 12 });
});

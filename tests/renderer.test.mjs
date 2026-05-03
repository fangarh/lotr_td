import assert from 'node:assert/strict';
import test from 'node:test';

import { createRenderer } from '../src/renderer.js';

test('renderer clears the viewport and draws scene layers in order', () => {
  const calls = [];
  const ctx = createContext(calls);
  const renderer = createRenderer({
    ctx,
    getViewport: () => ({ width: 800, height: 500 }),
    getCurrentLevel: () => ({
      width: 2,
      height: 2,
      theme: 'mordor',
      path: [{ x: 1, y: 0 }],
    }),
    getCameraView: () => ({ camera: { x: 0, y: 0 } }),
    getRenderState: () => ({
      towers: [],
      enemies: [],
      projectiles: [],
      effects: [],
      gold: 0,
      clock: 0,
    }),
    getLevelPresentation: () => ({
      sky: '#111111',
      horizon: '#222222',
      accent: '#ff0000',
      landmarks: [],
      ambientParticles: [],
    }),
    getVisibleTileBounds: () => ({ minX: 0, minY: 0, maxX: 1, maxY: 1 }),
    tileKey: (tile) => `${tile.x},${tile.y}`,
    sameTile: (a, b) => a.x === b.x && a.y === b.y,
    getSelectedTile: () => ({ x: 0, y: 1 }),
    getSelectedTowerId: () => null,
    getHoverTile: () => null,
    getSelectedTowerType: () => null,
    getTowerAt: (tile) => (tile.x === 0 && tile.y === 0 ? { id: 'tower' } : null),
    getTowerFamily: () => ({ accent: '#ff0000', branches: {} }),
    getTowerAttackProfile: () => ({ kind: 'precision' }),
    canPlaceTower: () => ({ ok: false }),
    project: (x, y) => ({ x: x * 10, y: y * 10 }),
    getObjectScale: () => 1,
    getScaledTileSize: () => ({ w: 400, h: 200 }),
  });

  renderer.draw();

  assert.deepEqual(calls, [
    'clearRect:0,0,800,500',
    'createLinearGradient:0,0,0,500',
    'gradient.addColorStop:0:#111111',
    'gradient.addColorStop:0.52:#171b19',
    'gradient.addColorStop:1:#101111',
    'fillRect:0,0,800,500',
  ]);
});

function createContext(calls) {
  return {
    fillStyle: '',
    strokeStyle: '',
    lineWidth: 1,
    clearRect: (...args) => calls.push(`clearRect:${args.join(',')}`),
    fillRect: (...args) => {
      if (args[0] === 0 && args[1] === 0 && args[2] === 800 && args[3] === 500) {
        calls.push(`fillRect:${args.join(',')}`);
      }
    },
    beginPath: () => {},
    closePath: () => {},
    moveTo: () => {},
    lineTo: () => {},
    stroke: () => {},
    fill: () => {},
    save: () => {},
    restore: () => {},
    clip: () => {},
    translate: () => {},
    arc: () => {},
    ellipse: () => {},
    bezierCurveTo: () => {},
    createLinearGradient: (...args) => {
      calls.push(`createLinearGradient:${args.join(',')}`);
      return {
        addColorStop: (offset, color) => calls.push(`gradient.addColorStop:${offset}:${color}`),
      };
    },
  };
}

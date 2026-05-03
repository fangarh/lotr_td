import assert from 'node:assert/strict';
import test from 'node:test';

import { attachInputHandlers } from '../src/input.js';

test('input adapter wires controls to callbacks', () => {
  const callbacks = createCallbacks();
  const controls = createControls();

  attachInputHandlers({
    targetWindow: createEventTarget(),
    canvas: createCanvasTarget(),
    controls,
    ...callbacks.handlers,
  });

  controls.levelSelect.value = '3';
  controls.levelSelect.fire('change', {});
  controls.startWaveButton.fire('click', {});
  controls.restartButton.fire('click', {});
  controls.soundToggleButton.fire('click', {});
  controls.unlockAllButton.fire('click', {});
  controls.addGoldButton.fire('click', {});
  controls.addWavesButton.fire('click', {});
  controls.infiniteGoldButton.fire('click', {});

  assert.deepEqual(callbacks.calls, [
    ['level', 3],
    ['start'],
    ['restart'],
    ['sound'],
    ['unlock'],
    ['gold'],
    ['waves'],
    ['infinite'],
  ]);
});

test('input adapter handles canvas pan, hover, and click suppression', () => {
  const callbacks = createCallbacks();
  const targetWindow = createEventTarget();
  const canvas = createCanvasTarget();

  attachInputHandlers({
    targetWindow,
    canvas,
    controls: createControls(),
    ...callbacks.handlers,
  });

  canvas.fire('pointerdown', { button: 2, pointerId: 1, clientX: 10, clientY: 10 });
  assert.deepEqual(canvas.capturedPointers, []);

  canvas.fire('pointerdown', { button: 0, pointerId: 7, clientX: 10, clientY: 10 });
  assert.deepEqual(canvas.capturedPointers, [7]);

  canvas.fire('pointermove', { pointerId: 7, clientX: 13, clientY: 14 });
  canvas.fire('pointermove', { pointerId: 7, clientX: 16, clientY: 18 });
  canvas.fire('pointerup', { pointerId: 7, clientX: 16, clientY: 18 });
  canvas.fire('click', { kind: 'suppressed-click' });
  canvas.fire('click', { kind: 'real-click' });

  assert.deepEqual(canvas.releasedPointers, [7]);
  assert.deepEqual(callbacks.calls, [
    ['hover', 'pointermove'],
    ['pan', 3, 4],
    ['hover', 'pointermove'],
    ['hover', 'pointerup'],
    ['click', 'real-click'],
  ]);
});

test('input adapter handles wheel panning and hover clear', () => {
  const callbacks = createCallbacks();
  const canvas = createCanvasTarget();

  attachInputHandlers({
    targetWindow: createEventTarget(),
    canvas,
    controls: createControls(),
    ...callbacks.handlers,
  });

  const wheelEvent = {
    deltaX: 12,
    deltaY: -5,
    defaultPrevented: false,
    preventDefault() {
      this.defaultPrevented = true;
    },
  };

  canvas.fire('wheel', wheelEvent);
  canvas.fire('mouseleave', {});

  assert.equal(wheelEvent.defaultPrevented, true);
  assert.deepEqual(canvas.listenerOptions.get('wheel'), { passive: false });
  assert.deepEqual(callbacks.calls, [
    ['pan', -12, 5],
    ['hover', 'wheel'],
    ['hover-clear'],
  ]);
});

test('input adapter clears active pan on pointer cancel', () => {
  const callbacks = createCallbacks();
  const canvas = createCanvasTarget();

  attachInputHandlers({
    targetWindow: createEventTarget(),
    canvas,
    controls: createControls(),
    ...callbacks.handlers,
  });

  canvas.fire('pointerdown', { button: 0, pointerId: 1, clientX: 0, clientY: 0 });
  canvas.fire('pointercancel', { pointerId: 1 });
  canvas.fire('pointermove', { pointerId: 1, clientX: 20, clientY: 20 });

  assert.deepEqual(callbacks.calls, [
    ['hover', 'pointermove'],
  ]);
});

function createCallbacks() {
  const calls = [];
  return {
    calls,
    handlers: {
      onResize: () => calls.push(['resize']),
      onLevelChange: (id) => calls.push(['level', id]),
      onStartWave: () => calls.push(['start']),
      onRestart: () => calls.push(['restart']),
      onToggleSound: () => calls.push(['sound']),
      onUnlockTesterCampaign: () => calls.push(['unlock']),
      onAddTesterGold: () => calls.push(['gold']),
      onAddTesterWaves: () => calls.push(['waves']),
      onToggleTesterInfiniteGold: () => calls.push(['infinite']),
      onPan: ({ dx, dy }) => calls.push(['pan', dx, dy]),
      onHover: (event) => calls.push(['hover', event.type]),
      onHoverClear: () => calls.push(['hover-clear']),
      onCanvasClick: (event) => calls.push(['click', event.kind]),
    },
  };
}

function createControls() {
  return {
    levelSelect: createEventTarget({ value: '1' }),
    startWaveButton: createEventTarget(),
    restartButton: createEventTarget(),
    soundToggleButton: createEventTarget(),
    unlockAllButton: createEventTarget(),
    addGoldButton: createEventTarget(),
    addWavesButton: createEventTarget(),
    infiniteGoldButton: createEventTarget(),
  };
}

function createCanvasTarget() {
  return {
    ...createEventTarget(),
    capturedPointers: [],
    releasedPointers: [],
    setPointerCapture(pointerId) {
      this.capturedPointers.push(pointerId);
    },
    releasePointerCapture(pointerId) {
      this.releasedPointers.push(pointerId);
    },
  };
}

function createEventTarget(extra = {}) {
  return {
    listeners: new Map(),
    listenerOptions: new Map(),
    addEventListener(name, listener, options) {
      this.listeners.set(name, listener);
      if (options) {
        this.listenerOptions.set(name, options);
      }
    },
    fire(name, event) {
      event.type = name;
      this.listeners.get(name)?.(event);
    },
    ...extra,
  };
}

import assert from 'node:assert/strict';
import test from 'node:test';

import { createAudio } from '../src/audio.js';

test('audio does not create a context when sound is disabled', () => {
  let createdContexts = 0;
  const audio = createAudio({
    getSoundEnabled: () => false,
    getWindow: () => ({
      AudioContext: class {
        constructor() {
          createdContexts += 1;
        }
      },
    }),
  });

  audio.playSound('build');

  assert.equal(createdContexts, 0);
});

test('audio plays known tones through WebAudio nodes', () => {
  const contexts = [];
  const audio = createAudio({
    getSoundEnabled: () => true,
    getWindow: () => ({
      AudioContext: createFakeAudioContextClass(contexts),
    }),
  });

  audio.playSound('breach');

  const context = contexts[0];
  assert.equal(context.oscillators.length, 1);
  assert.equal(context.gains.length, 1);
  assert.equal(context.oscillators[0].type, 'sawtooth');
  assert.deepEqual(context.oscillators[0].frequency.calls[0], ['set', 95, 4]);
  assert.equal(context.oscillators[0].connections[0], context.gains[0]);
  assert.equal(context.gains[0].connections[0], context.destination);
  assert.deepEqual(context.oscillators[0].starts, [4]);
  assert.ok(Math.abs(context.oscillators[0].stops[0] - 4.24) < 0.000001);
});

test('audio resumes a suspended context and reuses it', () => {
  const contexts = [];
  const audio = createAudio({
    getSoundEnabled: () => true,
    getWindow: () => ({
      AudioContext: createFakeAudioContextClass(contexts, { state: 'suspended' }),
    }),
  });

  audio.playSound('toggle');
  audio.playSound('upgrade');

  assert.equal(contexts.length, 1);
  assert.equal(contexts[0].resumeCalls, 1);
  assert.equal(contexts[0].oscillators.length, 2);
});

test('audio ignores unavailable or blocked WebAudio support', () => {
  createAudio({
    getSoundEnabled: () => true,
    getWindow: () => ({}),
  }).playSound('build');

  createAudio({
    getSoundEnabled: () => true,
    getWindow: () => {
      throw new Error('blocked');
    },
  }).playSound('build');
});

function createFakeAudioContextClass(contexts, { state = 'running' } = {}) {
  return class FakeAudioContext {
    constructor() {
      this.currentTime = 4;
      this.destination = { kind: 'destination' };
      this.gains = [];
      this.oscillators = [];
      this.resumeCalls = 0;
      this.state = state;
      contexts.push(this);
    }

    createOscillator() {
      const oscillator = {
        connections: [],
        frequency: createAutomationParam(),
        starts: [],
        stops: [],
        type: '',
        connect(target) {
          this.connections.push(target);
        },
        start(time) {
          this.starts.push(time);
        },
        stop(time) {
          this.stops.push(time);
        },
      };
      this.oscillators.push(oscillator);
      return oscillator;
    }

    createGain() {
      const gain = {
        connections: [],
        gain: createAutomationParam(),
        connect(target) {
          this.connections.push(target);
        },
      };
      this.gains.push(gain);
      return gain;
    }

    resume() {
      this.resumeCalls += 1;
      this.state = 'running';
    }
  };
}

function createAutomationParam() {
  return {
    calls: [],
    setValueAtTime(value, time) {
      this.calls.push(['set', value, time]);
    },
    exponentialRampToValueAtTime(value, time) {
      this.calls.push(['ramp', value, time]);
    },
  };
}

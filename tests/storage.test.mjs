import assert from 'node:assert/strict';
import test from 'node:test';

import { campaignLevels } from '../src/gameData.js';
import { createDefaultProgress } from '../src/gameLogic.js';
import {
  loadCampaignProgress,
  loadSoundPreference,
  saveCampaignProgress,
  saveSoundPreference,
} from '../src/storage.js';

test('storage loads normalized campaign progress', () => {
  const storage = createStorage();
  storage.setItem('middle-earth-td-progress-v1', JSON.stringify({
    completedLevelIds: [1, 2, 999, 2],
  }));

  assert.deepEqual(loadCampaignProgress(storage, campaignLevels), {
    version: 1,
    highestUnlockedLevel: 1,
    completedLevelIds: [1, 2],
  });
});

test('storage falls back to default campaign progress when loading fails', () => {
  assert.deepEqual(
    loadCampaignProgress(createStorage({ getThrows: true }), campaignLevels),
    createDefaultProgress(),
  );

  const storage = createStorage();
  storage.setItem('middle-earth-td-progress-v1', '{bad json');

  assert.deepEqual(loadCampaignProgress(storage, campaignLevels), createDefaultProgress());
});

test('storage reports campaign progress save failures', () => {
  const storage = createStorage();

  assert.equal(saveCampaignProgress(storage, { completedLevelIds: [1] }), true);
  assert.equal(storage.getItem('middle-earth-td-progress-v1'), '{"completedLevelIds":[1]}');
  assert.equal(saveCampaignProgress(createStorage({ setThrows: true }), { completedLevelIds: [1] }), false);
});

test('storage loads and saves sound preference', () => {
  const storage = createStorage();

  assert.equal(loadSoundPreference(storage), false);
  assert.equal(saveSoundPreference(storage, true), true);
  assert.equal(storage.getItem('middle-earth-td-sound-enabled-v1'), 'true');
  assert.equal(loadSoundPreference(storage), true);
  assert.equal(saveSoundPreference(createStorage({ setThrows: true }), false), false);
  assert.equal(loadSoundPreference(createStorage({ getThrows: true })), false);
});

function createStorage({ getThrows = false, setThrows = false } = {}) {
  const items = new Map();
  return {
    getItem(key) {
      if (getThrows) {
        throw new Error('blocked');
      }
      return items.get(key) ?? null;
    },
    setItem(key, value) {
      if (setThrows) {
        throw new Error('blocked');
      }
      items.set(key, value);
    },
  };
}

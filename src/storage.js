import {
  createDefaultProgress,
  normalizeCampaignProgress,
  normalizeSoundPreference,
} from './gameLogic.js';

const progressStorageKey = 'middle-earth-td-progress-v1';
const soundStorageKey = 'middle-earth-td-sound-enabled-v1';

export function loadCampaignProgress(storage, levels) {
  try {
    const raw = storage.getItem(progressStorageKey);
    return normalizeCampaignProgress(raw ? JSON.parse(raw) : null, levels);
  } catch {
    return createDefaultProgress();
  }
}

export function saveCampaignProgress(storage, progress) {
  try {
    storage.setItem(progressStorageKey, JSON.stringify(progress));
    return true;
  } catch {
    return false;
  }
}

export function loadSoundPreference(storage) {
  try {
    return normalizeSoundPreference(storage.getItem(soundStorageKey));
  } catch {
    return false;
  }
}

export function saveSoundPreference(storage, enabled) {
  try {
    storage.setItem(soundStorageKey, String(enabled));
    return true;
  } catch {
    return false;
  }
}

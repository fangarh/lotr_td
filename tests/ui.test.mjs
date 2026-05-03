import assert from 'node:assert/strict';
import test from 'node:test';

import { createUi } from '../src/ui.js';

test('ui renders level select options', () => {
  const hud = createHudElements();
  const ui = createUi({
    soundToggleButton: createButton(),
    ...hud,
    getSoundEnabled: () => false,
  });

  ui.renderLevelSelect({
    selectedLevelId: '2',
    levels: [
      { value: '1', disabled: false, label: '1. Удун - пройдено' },
      { value: '2', disabled: false, label: '2. Кирит Унгол' },
      { value: '3', disabled: true, label: '3. Осгилиат - закрыто' },
    ],
  });

  assert.equal(hud.levelSelect.children.length, 3);
  assert.equal(hud.levelSelect.children[0].value, '1');
  assert.equal(hud.levelSelect.children[0].disabled, false);
  assert.equal(hud.levelSelect.children[0].textContent, '1. Удун - пройдено');
  assert.equal(hud.levelSelect.children[2].disabled, true);
  assert.equal(hud.levelSelect.value, '2');
});

test('ui renders tower buttons and forwards selection', () => {
  const hud = createHudElements();
  const selectedTowerIds = [];
  const ui = createUi({
    soundToggleButton: createButton(),
    ...hud,
    getSoundEnabled: () => false,
  });

  ui.renderTowerButtons({
    towers: [
      {
        id: 'orcPit',
        name: 'Орочья яма',
        shortName: 'Орки',
        description: 'Дешевые заставы',
        baseCost: 70,
        active: false,
      },
      {
        id: 'eye',
        name: 'Око',
        shortName: 'Око',
        description: 'Магический надзор',
        baseCost: 140,
        active: true,
      },
    ],
    onSelectTower: (towerId) => selectedTowerIds.push(towerId),
  });

  assert.equal(hud.towerButtons.children.length, 2);
  assert.equal(hud.towerButtons.children[0].className, 'tower-card');
  assert.equal(hud.towerButtons.children[1].className, 'tower-card active');
  assert.equal(hud.towerButtons.children[1].attributes.get('aria-label'), 'Око');
  assert.equal(hud.towerButtons.children[1].dataset.tooltip, 'Око: Магический надзор Стоимость 140.');
  assert.equal(hud.towerButtons.children[1].innerHTML, '<strong>Око</strong><small>Магический надзор<br>Цена: 140</small>');

  hud.towerButtons.children[0].click();

  assert.deepEqual(selectedTowerIds, ['orcPit']);
});

test('ui renders selected tower actions and forwards commands', () => {
  const hud = createHudElements();
  const upgradeCalls = [];
  const sellCalls = [];
  const payload = { tier: 2 };
  const ui = createUi({
    soundToggleButton: createButton(),
    ...hud,
    getSoundEnabled: () => false,
  });

  ui.renderSelection({
    contentHtml: '<strong>Око</strong><br>Уровень 1',
    upgradeNoteText: '',
    upgrades: [
      {
        towerId: 7,
        payload,
        name: 'Пылающий взгляд',
        branchName: 'Пламя',
        cost: 120,
        damage: 18,
        range: 4,
      },
    ],
    sell: {
      towerId: 7,
      text: 'Продать за 66',
    },
  }, {
    onUpgradeTower: (towerId, upgrade) => upgradeCalls.push([towerId, upgrade]),
    onSellTower: (towerId) => sellCalls.push(towerId),
  });

  assert.equal(hud.selectionBox.innerHTML, '<strong>Око</strong><br>Уровень 1');
  assert.equal(hud.upgradeButtons.children.length, 2);
  assert.equal(hud.upgradeButtons.children[0].className, 'upgrade-card');
  assert.equal(hud.upgradeButtons.children[0].dataset.tooltip, 'Пылающий взгляд: стоимость 120, урон 18, дальность 4.');
  assert.equal(hud.upgradeButtons.children[1].className, 'secondary');
  assert.equal(hud.upgradeButtons.children[1].textContent, 'Продать за 66');

  hud.upgradeButtons.children[0].click();
  hud.upgradeButtons.children[1].click();

  assert.deepEqual(upgradeCalls, [[7, payload]]);
  assert.deepEqual(sellCalls, [7]);
});

test('ui renders selection notes and plain selection text', () => {
  const hud = createHudElements();
  const ui = createUi({
    soundToggleButton: createButton(),
    ...hud,
    getSoundEnabled: () => false,
  });

  ui.renderSelection({
    contentText: 'Клетка не выбрана.',
    upgradeNoteText: 'Башня достигла максимума.',
    upgrades: [],
    sell: null,
  }, {
    onUpgradeTower: () => {},
    onSellTower: () => {},
  });

  assert.equal(hud.selectionBox.textContent, 'Клетка не выбрана.');
  assert.equal(hud.upgradeButtons.children.length, 1);
  assert.equal(hud.upgradeButtons.children[0].className, 'selection');
  assert.equal(hud.upgradeButtons.children[0].textContent, 'Башня достигла максимума.');
});

test('ui syncs the sound toggle button state and label', () => {
  let soundEnabled = false;
  const button = createButton();
  const ui = createUi({
    soundToggleButton: button,
    ...createHudElements(),
    getSoundEnabled: () => soundEnabled,
  });

  ui.syncSoundToggle();
  assert.equal(button.attributes.get('aria-pressed'), 'false');
  assert.equal(button.textContent, 'Звук: выкл');

  soundEnabled = true;
  ui.syncSoundToggle();
  assert.equal(button.attributes.get('aria-pressed'), 'true');
  assert.equal(button.textContent, 'Звук: вкл');
});

test('ui syncs the hud view model into DOM elements', () => {
  const hud = createHudElements();
  const ui = createUi({
    soundToggleButton: createButton(),
    ...hud,
    getSoundEnabled: () => false,
  });

  ui.syncHud({
    goldText: '∞',
    livesText: '12',
    waveText: '2/5',
    unlockText: 'III',
    campaignProgressHtml: '<strong>2/10</strong> уровней пройдено',
    startWaveDisabled: true,
  });

  assert.equal(hud.goldEl.textContent, '∞');
  assert.equal(hud.livesEl.textContent, '12');
  assert.equal(hud.waveEl.textContent, '2/5');
  assert.equal(hud.unlockEl.textContent, 'III');
  assert.equal(hud.campaignProgressEl.innerHTML, '<strong>2/10</strong> уровней пройдено');
  assert.equal(hud.startWaveButton.disabled, true);
});

test('ui syncs tester hud controls', () => {
  const hud = createHudElements();
  const ui = createUi({
    soundToggleButton: createButton(),
    ...hud,
    getSoundEnabled: () => false,
  });

  ui.syncTesterHud({
    infiniteGoldPressed: true,
    infiniteGoldText: 'Деньги: ∞',
    testerStatusText: 'Тест: все улучшения · волн 12',
  });

  assert.equal(hud.infiniteGoldButton.attributes.get('aria-pressed'), 'true');
  assert.equal(hud.infiniteGoldButton.textContent, 'Деньги: ∞');
  assert.equal(hud.testerStatusEl.textContent, 'Тест: все улучшения · волн 12');
});

test('ui syncs status text', () => {
  const hud = createHudElements();
  const ui = createUi({
    soundToggleButton: createButton(),
    ...hud,
    getSoundEnabled: () => false,
  });

  ui.syncStatus('Башня построена.');

  assert.equal(hud.statusBox.textContent, 'Башня построена.');
});

function createButton() {
  return {
    attributes: new Map(),
    className: '',
    dataset: {},
    innerHTML: '',
    textContent: '',
    type: '',
    disabled: false,
    listeners: new Map(),
    setAttribute(name, value) {
      this.attributes.set(name, value);
    },
    addEventListener(name, listener) {
      this.listeners.set(name, listener);
    },
    click() {
      this.listeners.get('click')?.();
    },
  };
}

function createHudElements() {
  return {
    levelSelect: createSelect(),
    towerButtons: createButtonGroup(),
    upgradeButtons: createButtonGroup(),
    selectionBox: createElement(),
    goldEl: createElement(),
    livesEl: createElement(),
    waveEl: createElement(),
    unlockEl: createElement(),
    campaignProgressEl: createElement(),
    startWaveButton: createButton(),
    statusBox: createElement(),
    infiniteGoldButton: createButton(),
    testerStatusEl: createElement(),
  };
}

function createElement() {
  return {
    textContent: '',
    innerHTML: '',
  };
}

function createSelect() {
  return {
    children: [],
    ownerDocument: {
      createElement(tagName) {
        assert.equal(tagName, 'option');
        return createOption();
      },
    },
    value: '',
    replaceChildren() {
      this.children = [];
    },
    append(child) {
      this.children.push(child);
    },
  };
}

function createOption() {
  return {
    value: '',
    disabled: false,
    textContent: '',
  };
}

function createButtonGroup() {
  return {
    children: [],
    ownerDocument: {
      createElement(tagName) {
        if (tagName === 'button') {
          return createButton();
        }
        if (tagName === 'div') {
          return {
            ...createElement(),
            className: '',
          };
        }
        assert.fail(`Unexpected tag: ${tagName}`);
      },
    },
    replaceChildren() {
      this.children = [];
    },
    append(child) {
      this.children.push(child);
    },
  };
}

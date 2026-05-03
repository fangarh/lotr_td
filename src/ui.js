export function createUi({
  levelSelect,
  towerButtons,
  upgradeButtons,
  selectionBox,
  soundToggleButton,
  goldEl,
  livesEl,
  waveEl,
  unlockEl,
  campaignProgressEl,
  startWaveButton,
  statusBox,
  infiniteGoldButton,
  testerStatusEl,
  getSoundEnabled,
}) {
  function syncSoundToggle() {
    const enabled = getSoundEnabled();
    soundToggleButton.setAttribute('aria-pressed', String(enabled));
    soundToggleButton.textContent = enabled ? 'Звук: вкл' : 'Звук: выкл';
  }

  function renderLevelSelect({ levels, selectedLevelId }) {
    levelSelect.replaceChildren();
    for (const level of levels) {
      const option = levelSelect.ownerDocument.createElement('option');
      option.value = level.value;
      option.disabled = level.disabled;
      option.textContent = level.label;
      levelSelect.append(option);
    }
    levelSelect.value = selectedLevelId;
  }

  function renderTowerButtons({ towers, onSelectTower }) {
    towerButtons.replaceChildren();
    for (const tower of towers) {
      const button = towerButtons.ownerDocument.createElement('button');
      button.className = `tower-card${tower.active ? ' active' : ''}`;
      button.type = 'button';
      button.setAttribute('aria-label', tower.name);
      button.dataset.tooltip = `${tower.shortName}: ${tower.description} Стоимость ${tower.baseCost}.`;
      button.innerHTML = `<strong>${tower.name}</strong><small>${tower.description}<br>Цена: ${tower.baseCost}</small>`;
      button.addEventListener('click', () => onSelectTower(tower.id));
      towerButtons.append(button);
    }
  }

  function renderSelection(selection, { onUpgradeTower, onSellTower }) {
    upgradeButtons.replaceChildren();
    if (selection.contentHtml) {
      selectionBox.innerHTML = selection.contentHtml;
    } else {
      selectionBox.textContent = selection.contentText;
    }

    if (selection.upgradeNoteText) {
      const note = upgradeButtons.ownerDocument.createElement('div');
      note.className = 'selection';
      note.textContent = selection.upgradeNoteText;
      upgradeButtons.append(note);
    }

    for (const upgrade of selection.upgrades) {
      const button = upgradeButtons.ownerDocument.createElement('button');
      button.className = 'upgrade-card';
      button.type = 'button';
      button.setAttribute('aria-label', upgrade.name);
      button.dataset.tooltip = `${upgrade.name}: стоимость ${upgrade.cost}, урон ${upgrade.damage}, дальность ${upgrade.range}.`;
      button.innerHTML = `<strong>${upgrade.name}</strong><small>${upgrade.branchName ? `${upgrade.branchName}<br>` : ''}Цена: ${upgrade.cost} · Урон: ${upgrade.damage} · Дальность: ${upgrade.range}</small>`;
      button.addEventListener('click', () => onUpgradeTower(upgrade.towerId, upgrade.payload));
      upgradeButtons.append(button);
    }

    if (selection.sell) {
      const sell = upgradeButtons.ownerDocument.createElement('button');
      sell.className = 'secondary';
      sell.type = 'button';
      sell.setAttribute('aria-label', 'Продать башню');
      sell.dataset.tooltip = 'Вернуть 55% вложенного золота и освободить клетку.';
      sell.textContent = selection.sell.text;
      sell.addEventListener('click', () => onSellTower(selection.sell.towerId));
      upgradeButtons.append(sell);
    }
  }

  function syncHud({
    goldText,
    livesText,
    waveText,
    unlockText,
    campaignProgressHtml,
    startWaveDisabled,
  }) {
    goldEl.textContent = goldText;
    livesEl.textContent = livesText;
    waveEl.textContent = waveText;
    unlockEl.textContent = unlockText;
    campaignProgressEl.innerHTML = campaignProgressHtml;
    startWaveButton.disabled = startWaveDisabled;
  }

  function syncStatus(message) {
    statusBox.textContent = message;
  }

  function syncTesterHud({
    infiniteGoldPressed,
    infiniteGoldText,
    testerStatusText,
  }) {
    infiniteGoldButton.setAttribute('aria-pressed', String(infiniteGoldPressed));
    infiniteGoldButton.textContent = infiniteGoldText;
    testerStatusEl.textContent = testerStatusText;
  }

  return {
    renderLevelSelect,
    renderSelection,
    renderTowerButtons,
    syncHud,
    syncSoundToggle,
    syncStatus,
    syncTesterHud,
  };
}

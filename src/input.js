export function attachInputHandlers({
  targetWindow,
  canvas,
  controls,
  onResize,
  onLevelChange,
  onStartWave,
  onRestart,
  onToggleSound,
  onUnlockTesterCampaign,
  onAddTesterGold,
  onAddTesterWaves,
  onToggleTesterInfiniteGold,
  onPan,
  onHover,
  onHoverClear,
  onCanvasClick,
}) {
  let panState = null;
  let suppressNextClick = false;

  targetWindow.addEventListener('resize', onResize);
  controls.levelSelect.addEventListener('change', () => onLevelChange(Number(controls.levelSelect.value)));
  controls.startWaveButton.addEventListener('click', onStartWave);
  controls.restartButton.addEventListener('click', onRestart);
  controls.soundToggleButton.addEventListener('click', onToggleSound);
  controls.unlockAllButton.addEventListener('click', onUnlockTesterCampaign);
  controls.addGoldButton.addEventListener('click', onAddTesterGold);
  controls.addWavesButton.addEventListener('click', onAddTesterWaves);
  controls.infiniteGoldButton.addEventListener('click', onToggleTesterInfiniteGold);

  canvas.addEventListener('pointerdown', (event) => {
    if (event.button !== 0) return;
    panState = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      lastX: event.clientX,
      lastY: event.clientY,
      moved: false,
    };
    canvas.setPointerCapture(event.pointerId);
  });

  canvas.addEventListener('pointermove', (event) => {
    if (panState?.pointerId === event.pointerId) {
      const dx = event.clientX - panState.lastX;
      const dy = event.clientY - panState.lastY;
      const totalDistance = Math.hypot(event.clientX - panState.startX, event.clientY - panState.startY);
      panState.lastX = event.clientX;
      panState.lastY = event.clientY;
      if (totalDistance > 5) {
        panState.moved = true;
        onPan({ dx, dy });
      }
    }
    onHover(event);
  });

  canvas.addEventListener('pointerup', (event) => {
    if (panState?.pointerId !== event.pointerId) return;
    suppressNextClick = panState.moved;
    canvas.releasePointerCapture(event.pointerId);
    panState = null;
    onHover(event);
  });

  canvas.addEventListener('pointercancel', (event) => {
    if (panState?.pointerId === event.pointerId) {
      panState = null;
    }
  });

  canvas.addEventListener('wheel', (event) => {
    event.preventDefault();
    onPan({ dx: -event.deltaX, dy: -event.deltaY });
    onHover(event);
  }, { passive: false });

  canvas.addEventListener('mouseleave', onHoverClear);

  canvas.addEventListener('click', (event) => {
    if (suppressNextClick) {
      suppressNextClick = false;
      return;
    }
    onCanvasClick(event);
  });
}

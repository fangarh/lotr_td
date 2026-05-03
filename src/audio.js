const tones = {
  toggle: [520, 0.08, 0.035],
  wave: [180, 0.16, 0.05],
  build: [420, 0.08, 0.045],
  upgrade: [620, 0.18, 0.05],
  kill: [260, 0.05, 0.032],
  bossDown: [120, 0.28, 0.06],
  breach: [95, 0.22, 0.065],
  victory: [740, 0.32, 0.055],
  lost: [110, 0.42, 0.055],
};

export function createAudio({ getSoundEnabled, getWindow }) {
  let audioContext = null;

  function playSound(kind) {
    if (!getSoundEnabled()) return;

    const audio = getAudioContext();
    if (!audio) return;

    const tone = tones[kind] ?? [300, 0.1, 0.035];
    const now = audio.currentTime;
    const oscillator = audio.createOscillator();
    const gain = audio.createGain();
    oscillator.type = kind === 'breach' || kind === 'lost' ? 'sawtooth' : 'triangle';
    oscillator.frequency.setValueAtTime(tone[0], now);
    oscillator.frequency.exponentialRampToValueAtTime(Math.max(40, tone[0] * 0.62), now + tone[1]);
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(tone[2], now + 0.015);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + tone[1]);
    oscillator.connect(gain);
    gain.connect(audio.destination);
    oscillator.start(now);
    oscillator.stop(now + tone[1] + 0.02);
  }

  function getAudioContext() {
    try {
      const hostWindow = getWindow();
      const AudioContextClass = hostWindow.AudioContext || hostWindow.webkitAudioContext;
      if (!AudioContextClass) return null;
      audioContext ??= new AudioContextClass();
      if (audioContext.state === 'suspended') {
        audioContext.resume();
      }
      return audioContext;
    } catch {
      return null;
    }
  }

  return {
    playSound,
  };
}

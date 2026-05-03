# Iteration 2 Campaign Progression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> Status note, 2026-05-01: this is a historical plan. Browser storage and DOM wiring are no longer in `src/main.js`; they are split into `src/storage.js`, `src/ui.js`, and `src/input.js`. Use current Obsidian source files for architecture before implementing new work.

**Goal:** Turn the playable prototype into a campaign loop with saved progress, locked levels, varied maps, clearer encounters, and stronger battle feedback.

**Architecture:** Keep pure campaign rules in `src/gameLogic.js` and level data in `src/gameData.js` so core progression is testable with `node --test`. Current browser storage and DOM wiring are split into adapter modules, with no build step.

**Tech Stack:** Static HTML, CSS, JavaScript ES modules, Canvas 2D, Node test runner.

---

### Task 1: Campaign Progress Rules

**Files:**
- Modify: `tests/gameLogic.test.mjs`
- Modify: `src/gameLogic.js`
- Modify: `src/gameData.js`

- [ ] Write failing tests for level-path variety, default campaign progress, locked level selection, and completing a level.
- [ ] Run `npm.cmd test` and confirm the new tests fail because the progress helpers do not exist yet.
- [ ] Add pure helpers: `createDefaultProgress`, `isLevelUnlocked`, `completeCampaignLevel`, `getHighestUnlockedLevel`, and `getLevelById`.
- [ ] Give campaign levels distinct path layouts and optional encounter notes/modifiers while preserving at least 10 levels.
- [ ] Run `npm.cmd test` and confirm the logic tests pass.

### Task 2: Browser Save State and Level Locks

**Files:**
- Modify: `src/main.js`
- Modify: `index.html`
- Modify: `styles.css`

- [ ] Load progress from `localStorage` with a versioned key and fall back to default progress on bad data.
- [ ] Render locked levels in the selector and prevent resetting into locked levels.
- [ ] On victory, persist completion, unlock the next level, and refresh the level selector.
- [ ] Add compact campaign status UI showing completed levels and current unlocked cap.

### Task 3: Battle Readability

**Files:**
- Modify: `src/main.js`
- Modify: `styles.css`

- [ ] Add enemy trait labels through data-driven modifiers: elite, boss, swarm, siege.
- [ ] Improve visual feedback with sharper health bars, slow rings, reward floaters, and boss silhouettes.
- [ ] Keep the canvas full-bleed and avoid adding extra card clutter to the play area.

### Task 4: Verification

**Files:**
- Verify: `tests/gameLogic.test.mjs`
- Verify: browser at `http://127.0.0.1:5174/index.html`

- [ ] Run `npm.cmd test`.
- [ ] Run or reuse the static server.
- [ ] Use the browser to confirm there are 10 levels, locked levels cannot be selected before progress, the canvas is nonblank, and a completed level unlocks the next one.

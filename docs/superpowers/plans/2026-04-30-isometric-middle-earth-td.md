# Isometric Middle-earth Tower Defence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> Status note, 2026-05-01: this is a historical implementation plan. Current code has been refactored beyond this plan: rendering, UI, storage, audio, input, camera math, and part of simulation now live outside `src/main.js`. Use `docs/roadmap.md`, `docs/decisions.md`, and `docs/android-porting.md` for current architecture.

**Goal:** Build a playable static HTML isometric tower defence game with 10 levels, 4 tower families, branching upgrades, and evolving visuals.

**Architecture:** Keep campaign data and pure rules separate from rendering. The browser loop consumes tested data and logic, then handles canvas input, drawing, animation, and HUD updates.

**Tech Stack:** Static HTML, CSS, JavaScript ES modules, Canvas 2D, Node built-in `node:test`.

---

### Task 1: Core Rules

**Files:**
- Create: `src/gameData.js`
- Create: `src/gameLogic.js`
- Create: `tests/gameLogic.test.mjs`
- Create: `package.json`

- [ ] Write tests for tower catalog shape, campaign length, unlock tiers, branch requirements, and placement rules.
- [ ] Run `npm test` and confirm tests fail because modules do not exist yet.
- [ ] Implement `gameData.js` and `gameLogic.js` until tests pass.

### Task 2: Browser Shell

**Files:**
- Create: `index.html`
- Create: `styles.css`
- Create: `src/main.js`

- [ ] Build a full-screen app layout with canvas workspace and compact side HUD.
- [ ] Load campaign and tower data into visible controls.
- [ ] Render a nonblank isometric map with road, buildable tiles, and preview selection.

### Task 3: Playable Loop

**Files:**
- Modify: `src/main.js`
- Modify: `styles.css`

- [ ] Add level start, wave spawning, enemy movement, tower targeting, projectiles, gold rewards, and life loss.
- [ ] Add tower placement, selection, selling, and upgrade/branch buttons.
- [ ] Add clear win/lose state and next-level progression.

### Task 4: Visual Upgrade Pass

**Files:**
- Modify: `src/main.js`
- Modify: `styles.css`

- [ ] Draw tower level changes with height, banners, glows, smoke, and branch-specific accents.
- [ ] Draw enemy tier changes with size, armor, mounts, and boss silhouettes.
- [ ] Add concise UI polish and hover affordances without crowding the playfield.

### Task 5: Verification

**Files:**
- Modify only if verification finds defects.

- [ ] Run `npm test`.
- [ ] Open `index.html` in the in-app browser or a local static server.
- [ ] Verify the canvas is nonblank and a short play flow works: select tower, place, start wave, upgrade, complete or lose a level.

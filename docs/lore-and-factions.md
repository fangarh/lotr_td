# Lore And Factions

This game is inspired by the broad conflict structure of Tolkien's Middle-earth, but should avoid overfitting to exact canon at the cost of gameplay clarity.

## Player Side

The player represents the spreading power of Mordor and the Shadow.

Implementation status: the first playable catalog now follows this direction. Current player towers are Eye of Sauron, Orc War Camp, Morgul Sorcery, and Mordor Forge families. The Godot spike now has the base Eye tower proxy plus imported Shadow tower visual proxies for B2, textured B3, and B4, with a static visual-only B4 projectile preview, a short visual-only moving B4 shot instance with temporary ember readability helpers, and a temporary red-orange fire cue from the first tower attack adapter. Detailed visuals, projectile behavior, and final branch names can still change during the dark tower visual and mechanics passes.

Possible player-aligned tower themes:
- Eye of Sauron: surveillance, fire, fear, marking, magical pressure.
- Barad-dur / Black Stone: heavy dark fortifications.
- Orc war camps: arrows, crude artillery, soldier blockades.
- Mordor forge: metal, fire, siege, explosive pressure.
- Morgul sorcery: fear, curses, poison-green magic, spectral control.
- Dol Guldur / spiders: webs, roots, corruption, path obstacles.
- Troll pits / drums: brute-force support, summons, area denial.

Obstacle blocker framing should stay aligned with Shadow occupation rather than neutral barricades. Candidate temporary blockers include Orc shield lines, crude Mordor barricades, summoned troll-thrown rubble, spider web masses, and corrupted root growths. The first blocker HP lifecycle uses an `orc-blockade` fixture effect, and Free Peoples enemy proxies can now stop at blocker contact radius and damage that blocker through a signal-bridged adapter contract. A capture-only review script can now record that contact state, but final faction-specific blocker visuals, names, attack animations, and richer enemy interactions remain open.

## Enemy Side

Target attackers after the faction pivot are the Free Peoples and allies resisting conquest.

Implementation status: the first playable enemy catalog now uses Free Peoples resistance roles: Gondor soldiers and guards, Hobbits, Rohirrim, Dwarves, Dwarven sappers, and Elven wardens. Stats still reuse the old role structure until balance work resumes. The first Godot enemy proxy visually represents the baseline Gondor soldier with primitive light metal, shield, spear/banner, and blue-white accents while gameplay remains generic path movement. Imported Elven archer, Dwarven warrior, and Gondor warrior GLB proxies can now be selected by the Godot spike enemy catalog; the Elven archer, Dwarven warrior, and Gondor warrior have been refreshed from user-provided ZIP PBR exports.

Candidate enemy families:
- Gondor infantry: disciplined baseline units.
- Gondor shield guards: armored units.
- Rohirrim riders: fast cavalry.
- Elven archers: ranged or evasive units.
- Elven wardens/mages: resistant or cleansing units.
- Dwarven warriors: slow, armored, durable.
- Dwarven sappers: anti-tower or path-clearing units.
- Hobbits/scouts: small, quick, hard to target.
- Ents or Beornings: rare heavy late-game units.

## Campaign Fantasy

The campaign should feel like the Shadow establishing footholds across Middle-earth:
- Black Gate / Mordor: mustering.
- Ithilien: pushing out scouts and rangers.
- Osgiliath / Gondor borderlands: pressure against Men.
- Rohan plains: cavalry resistance.
- Dol Guldur / Mirkwood: corruption of forested lands.
- Dale / Lonely Mountain region: Men and Dwarves.
- Lorien / Rivendell: Elven resistance.
- Final free stronghold: combined resistance.

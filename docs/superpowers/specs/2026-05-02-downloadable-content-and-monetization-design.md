# Downloadable Content And Monetization Design

## Context

The production direction is a Godot mobile-first tower-defense game with Windows and desktop Web as secondary targets. The game needs support for downloadable content and monetization without coupling combat simulation to store logic or making purchases affect the balance of the base campaign.

## Product Rules

- The base game contains the main campaign, baseline towers, baseline enemies, and baseline visuals.
- Paid gameplay DLC must not make the base campaign easier. It may add isolated campaigns, levels, biomes, scenario rules, enemies, and content packs, but it must not grant stronger towers, permanent upgrades, passives, or other advantages in the base campaign.
- Visual monetization is cosmetic only: tower skins, enemy visual variants, projectile/effect skins, terrain themes, UI cosmetics, and similar presentation changes.
- Some content packs may be free. Seasonal or holiday packs can be claimable for free.
- Claimed event content remains owned forever after claim, even after the event window ends.
- Store and entitlement checks must happen outside combat simulation. Gameplay systems receive already-authorized content choices.

## Architecture

Use a data-first content-pack model rather than hard-coded DLC branches.

Core components:

- `ContentPackManifest`: describes a base, expansion, cosmetic, or event pack.
- `ContentRegistry`: loads available manifests and registers campaigns, levels, skins, themes, effects, and data definitions.
- `EntitlementService`: answers whether a player can use, claim, download, or delete a pack or cosmetic item.
- `ContentInstaller`: installs, verifies, updates, and removes downloaded content packs.
- `DeliveryProvider`: platform adapter for how content is obtained on a given storefront.
- `StoreAdapter`: platform adapter for ownership and purchase state.

The game should avoid `if/case` dispatch for concrete content ids. Content should register itself through manifests and definitions. Polymorphism is still appropriate for behavior contracts such as tower behavior, enemy behavior, attack effects, and visual-skin application.

## Manifest Shape

Initial manifest fields:

```json
{
  "id": "event.yule_2026",
  "title": "Yule Shadows",
  "version": "1.0.0",
  "kind": "event",
  "grantPolicy": "event_claim",
  "requiredAppVersion": "0.2.0",
  "dependencies": [],
  "content": {
    "campaigns": [],
    "levels": [],
    "towerSkins": [],
    "enemySkins": [],
    "terrainThemes": [],
    "effects": []
  },
  "integrity": {
    "hashAlgorithm": "sha256",
    "hash": "manifest-or-package-hash"
  }
}
```

Supported `kind` values:

- `base`
- `expansion`
- `cosmetic`
- `event`

Supported `grantPolicy` values:

- `included`
- `purchase`
- `free_claim`
- `event_claim`
- `dev_unlock`

## Entitlements

Entitlements are stored as durable records separate from installed files. Removing downloaded files should not remove ownership.

Entitlement grant sources:

- `base`: included with the game.
- `purchase`: owned through a platform store.
- `free_claim`: manually claimed free content.
- `event_claim`: event content claimed during the event window and retained forever.
- `dev_unlock`: local development and QA unlock.

Core queries:

```text
can_use(content_id)
can_claim(content_id)
claim(content_id)
can_download(pack_id)
is_installed(pack_id)
```

## Delivery Providers

Use one game-facing abstraction and platform-specific providers:

- `LocalDevProvider`: reads packs from local folders for development and automated smoke tests.
- `DirectManifestProvider`: downloads a remote index and package files from a CDN or static host.
- `GooglePlayAssetDeliveryProvider`: uses Google Play Asset Delivery for Android releases on Google Play.
- `SteamDepotProvider`: reads content installed through Steam DLC depots.
- `ItchBuildProvider`: treats itch.io channels/builds as the distribution layer, with optional in-game update prompts for direct-download users.

The registry should not care which provider delivered the files. It only sees installed manifests and verified resource roots.

## Store Recommendations

- Android on Google Play: prefer Play Asset Delivery for large downloadable asset packs. Keep downloaded packs asset-only: models, textures, sounds, scenes, manifests, localization, and data.
- Steam: use DLC and depots so Steam manages ownership, installation, and updates. The game scans installed depots for content-pack manifests.
- itch.io and direct distribution: use itch butler/Wharf for build updates where possible. For standalone downloadable packs, use `DirectManifestProvider` with hashes, version checks, and explicit install state.

## Script Policy

Downloaded DLC should not introduce arbitrary new scripts in the first implementation. Packs may reference built-in behavior ids and include data/resources. New mechanics ship through app updates, then DLC manifests can select those built-in behaviors.

This keeps Android/Web/Windows behavior predictable, reduces platform review risk, and prevents downloaded content from becoming an unsafe plugin system.

## Inheritance Policy

Use inheritance for behavior and presentation contracts:

- `TowerBehavior`
- `EnemyBehavior`
- `AttackEffect`
- `VisualSkin`
- `TerrainTheme`

Do not model ownership or delivery through inheritance:

- No `ChristmasDlc extends BaseGame`.
- No `PaidTower extends Tower`.
- No `StoreSpecificCampaign extends Campaign`.

DLC is a data and delivery concern. Behavior is a gameplay concern.

## Implementation Sequence

1. Add content-pack manifest parsing and validation using local files only.
2. Add `ContentRegistry` and register the current base scenario through the same path.
3. Add `EntitlementService` with local save-backed grants and dev unlocks.
4. Add cosmetic skin selection behind entitlement checks.
5. Add isolated expansion campaign registration without affecting the base campaign.
6. Add `LocalDevProvider` smoke tests for installing/removing a local pack.
7. Add the first production delivery provider only after the local pack path is stable.

## Testing Strategy

- Manifest validation tests for required fields, dependency ids, version compatibility, and hash metadata presence.
- Registry tests proving new packs register content without adding content-specific `if/case` branches.
- Entitlement tests for included, purchase, free claim, event claim, dev unlock, and removed-but-owned content.
- Balance guard tests proving paid content does not unlock stronger base-campaign towers or upgrades.
- Provider smoke tests for local pack install, duplicate version handling, missing dependency handling, and corrupted package rejection.

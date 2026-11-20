# KAAVAL: Guardians of Dawn — Game Design & Build Specification

> Working title. Check trademark/Play Store availability before launch.
> Version 1.0 · Android-first · Godot 4 · Solo developer + Claude Code

---

## 0. How to use this document

1. Create an empty folder, put `CLAUDE.md` in the root and this file at `docs/GAME_SPEC.md`.
2. Open Claude Code in that folder.
3. Run phases **one at a time** using the prompts in §18. Do not ask for the whole game in one go.
4. After each phase: play-test on a real Android phone, then commit.

---

## 1. Concept

**One-line pitch:** Survive the night, protect your village, and light the lamps before dawn.

**Genre:** Roguelite auto-shooter ("survivor-like"), portrait, one-thumb.

**Core fantasy:** You are a village guardian. Every night, folklore-inspired creatures swarm out of the forest. You move; your weapons fire automatically. Survive 15 minutes until dawn. Spend what you earn to rebuild and upgrade the village, which makes you stronger for the next night.

**What makes it different (the hook):**
1. **The village is the meta-progression.** Upgrades are visible buildings, not abstract stat bars. Players watch their village grow.
2. **Original folklore-inspired setting.** Rural, lamp-lit, night-time India-inspired world. Original creatures. Warm lamp-light vs. dark forest art direction.

**Design pillars:**
- *Easy to start, hard to put down:* one-thumb controls, runs of 15 min, a meaningful choice every ~30 seconds.
- *Every run builds something:* even a failed run earns village progress.
- *Fair monetization:* paying speeds things up and buys cosmetics. Skilled free players can finish all content.

**Content rules (hard):**
- No deities, temples, religious symbols, caste references, or real religious figures.
- All creatures, names, art, and audio are original or properly licensed.
- Do not copy names, art, UI layout, or text from any existing game.

---

## 2. Target & platform

| Item | Decision |
|---|---|
| Platform | Android (Google Play). iOS later. |
| Orientation | Portrait only |
| Min device | 3 GB RAM, Android 8+ (adjust to Play's requirements) |
| Performance target | 60 FPS with 300 enemies on screen on a mid-range phone |
| Audience | 13+ (avoids Google Play Families policy complexity with ads) |
| Content rating | Mild fantasy violence (IARC questionnaire) |
| Languages | English at launch; strings externalised for Tamil/Hindi later |
| Online requirement | Fully playable offline. Network used only for purchases, ads, remote config, cloud save. |

---

## 3. Tech stack

| Layer | Choice | Notes |
|---|---|---|
| Engine | **Godot 4.x (latest stable)** | Free, strong 2D, Android export |
| Renderer | **Compatibility** (OpenGL ES 3) | Widest Android device support |
| Language | GDScript (static typing everywhere) | |
| Tests | GUT (Godot Unit Test) addon | Runs headless |
| Billing | Official Godot Google Play Billing plugin (godot-sdk-integrations) | Verify version matches Godot version |
| Ads | AdMob via a maintained Godot AdMob plugin (e.g., Poing Studios) | Use Google **test ad IDs** in all dev builds |
| Consent | Google UMP (User Messaging Platform) via the AdMob plugin | Required for EEA/UK users |
| Remote config | Static JSON hosted on Firebase Hosting or GitHub Pages, fetched with `HTTPRequest` | Zero cost, no SDK |
| Analytics | Phase 6: Firebase Analytics via plugin, or a thin custom logger first | Optional for MVP |
| Cloud save | Phase 7+ (post-launch): Google Play Games Services saved games | Not in MVP |
| Art (MVP) | Coloured primitive shapes → Kenney.nl CC0 packs → custom art later | |
| Audio | Kenney.nl CC0 audio, or freesound.org CC0 only | Track licences in `CREDITS.md` |

---

## 4. Core gameplay (a "Night")

### 4.1 Controls
- **Floating virtual joystick:** touch anywhere in the lower 70% of the screen; joystick appears under the finger. Release = stop.
- No attack button. All weapons fire automatically.
- Pause button top-right.

### 4.2 Run flow
1. Choose hero → Start Night.
2. Hero spawns at the centre of a large looping/bounded forest-clearing map (MVP: 1 map, 4000×4000 px, bounded with soft walls).
3. Enemies spawn off-screen in a ring around the player per the wave table (§7.3).
4. Enemies drop **Spirit Embers** (XP). Walk near to collect (magnet radius).
5. Level up → game pauses → **choose 1 of 3** upgrade cards (§5.4).
6. Mini-boss at 5:00, boss at 10:00, final boss at 14:30.
7. Survive to **15:00 = Dawn** → victory. HP reaches 0 → defeat (offer revive, §9.3).
8. Results screen: time survived, kills, coins, timber earned → Village.

### 4.3 Hero stats (base)
| Stat | Default |
|---|---|
| Max HP | 100 |
| Move speed | 220 px/s |
| Armor | 0 (flat damage reduction per hit, min damage 1) |
| Pickup radius | 80 px |
| Damage multiplier | 1.0 |
| Cooldown multiplier | 1.0 |
| Area multiplier | 1.0 |
| HP regen | 0 HP/s |
| XP multiplier | 1.0 |
| Weapon slots | 4 |
| Passive slots | 4 |

### 4.4 XP curve
`xp_to_next(level) = round(6 + 4 * level + 0.6 * level^1.6)`

Expected level by 15:00 ≈ 35–40. Tune via remote config.

### 4.5 Damage & hits
- Player i-frames: 0.5 s after taking a hit.
- Enemy contact damage applied once per 0.5 s while overlapping.
- Floating damage numbers (toggle in settings).
- Hit flash on enemies (white shader, 0.08 s).

---

## 5. Heroes, weapons, passives, evolutions

### 5.1 Heroes (MVP: 2)
| ID | Name | Starting weapon | Modifiers | Unlock |
|---|---|---|---|---|
| `hero_muthu` | Muthu, the Watchman | Sling Stone | Balanced. +10% max HP | Default |
| `hero_ammu` | Ammu, the Lamplighter | Lamp Orbit | −15% max HP, +15% area, +10% XP | 5,000 coins OR IAP ₹199 |

### 5.2 Weapons (MVP: 8) — levels 1–5
All values at level 1; per-level gains listed. Cooldown in seconds.

| ID | Name | Behaviour | Dmg | CD | Per level |
|---|---|---|---|---|---|
| `w_sling` | Sling Stone | Fires a stone at nearest enemy | 12 | 0.9 | +1 projectile at L3, L5; +20% dmg |
| `w_lamp_orbit` | Lamp Orbit | 2 flames orbit the hero, damage on touch | 8 | constant (hit every 0.4 s per enemy) | +1 flame per level; +10% radius |
| `w_bamboo_spear` | Bamboo Spear | Thrown in movement direction, pierces 3 | 18 | 1.4 | +1 pierce; +15% dmg |
| `w_firecracker` | Firecracker Burst | Lands on a random on-screen enemy, AoE 90 px | 22 | 2.2 | +15% area; −8% CD |
| `w_thorn_whip` | Thorn Whip | Horizontal arc in front, 180 px wide | 16 | 1.1 | L3 hits both sides; +20% dmg |
| `w_chilli_smoke` | Chilli Smoke | Aura around hero, damage over time | 4 / tick (0.5 s) | constant | +12% radius; +1 dmg |
| `w_valari` | Valari | Boomerang thrown at nearest, returns, hits twice | 14 | 1.6 | +1 valari at L3, L5; +15% dmg |
| `w_war_drum` | War Drum | Shockwave pulse, knockback | 10 | 3.0 | +20% knockback; +15% area |

### 5.3 Passives (MVP: 6) — levels 1–5
| ID | Name | Effect per level |
|---|---|---|
| `p_bangle` | Iron Bangle | +1 armor |
| `p_sandals` | Swift Sandals | +8% move speed |
| `p_neem` | Neem Leaf | +0.3 HP/s regen |
| `p_magnet` | Magnet Stone | +20% pickup radius |
| `p_whetstone` | Whetstone | +8% damage |
| `p_hourglass` | Hourglass | −6% cooldown |

### 5.4 Level-up card rules
- Offer 3 cards from: new weapon (if slot free), new passive (if slot free), level-up of owned weapon/passive (if < L5).
- Weighting: owned items ×1.5 weight (encourages builds).
- If nothing is available: offer "+50 coins" and "Heal 30% HP".
- **Reroll:** 1 free reroll per run; extra rerolls from the Village "Library" building.

### 5.5 Evolutions (MVP: 4)
Condition: weapon at L5 **and** paired passive owned (any level). Evolution is granted from the **boss chest** (dropped by mini-boss/boss).

| Weapon | + Passive | → Evolution | Effect |
|---|---|---|---|
| Sling Stone | Whetstone | **Meteor Sling** | Stones explode on hit (AoE 60 px), 5 projectiles |
| Lamp Orbit | Hourglass | **Ring of Dawn** | 8 flames, larger radius, burns (DoT) |
| Valari | Swift Sandals | **Twin Valari Storm** | 4 valaris spiral outward continuously |
| Chilli Smoke | Neem Leaf | **Ghost Pepper Miasma** | Huge aura, heals hero 1 HP per 10 enemies killed inside |

---

## 6. Enemies & bosses

### 6.1 Regular enemies (MVP: 5)
| ID | Name | HP | Speed | Contact dmg | XP | Behaviour |
|---|---|---|---|---|---|---|
| `e_wisp` | Shadow Wisp | 8 | 140 | 5 | 1 | Chases player |
| `e_crawler` | Thorn Crawler | 40 | 70 | 10 | 3 | Slow tank |
| `e_crow` | Night Crow | 12 | 260 | 6 | 2 | Spawns in a line, flies straight across screen |
| `e_golem` | Mud Golem | 60 | 80 | 12 | 4 | Splits into 2 Mud Pups (15 HP) on death |
| `e_thief` | Lantern Thief | 25 | 180 | 0 | 5 | Steals nearby embers, flees; drops them all + bonus coins if killed |

**Scaling:** enemy HP × `(1 + 0.12 × minutes_elapsed)`; contact damage × `(1 + 0.05 × minutes_elapsed)`. Both multipliers in remote config.

### 6.2 Bosses
| Time | ID | Name | HP | Mechanics |
|---|---|---|---|---|
| 5:00 | `b_crawler_queen` | Thorn Queen (mini-boss) | 800 | Charges in a line every 4 s; spawns 6 crawlers at 50% HP |
| 10:00 | `b_banyan_wraith` | Banyan Wraith | 3,000 | Roots erupt under player (telegraphed red circle 1 s); summons wisps |
| 14:30 | `b_eclipse_beast` | Eclipse Beast | 8,000 | Darkens screen except a light radius around hero; 3 attack patterns; enrage at 30% |

- Bosses show a top health bar and a 2 s warning banner on spawn.
- Bosses drop a **Boss Chest**: evolution if eligible, otherwise 1–3 random upgrades + coins.
- If the Eclipse Beast is alive at 15:00, dawn still wins (sunlight kills it — satisfying moment).

---

## 7. Map & waves

### 7.1 Map
- MVP: 1 map, "Forest Edge". Bounded 4000×4000 px with tree walls.
- Decorative props (rocks, bushes, lamps) — non-colliding except boundary.
- Ambient darkness: a full-screen dark overlay with a light circle around the hero (CanvasModulate + PointLight2D, or a cheap shader for Compatibility renderer).
- Dawn: gradually brighten from 13:00 to 15:00.

### 7.2 Spawning
- Spawn ring: just outside camera view (camera rect + 120 px).
- Max simultaneous enemies: 300 (remote config). If at cap, skip spawn.
- Despawn and respawn enemies that are > 1.5 screens away from the player.

### 7.3 Wave timeline
| Time | Spawn rate (per s) | Enemy mix | Events |
|---|---|---|---|
| 0:00–1:00 | 1.0 | 100% wisp | Tutorial hints (first run only) |
| 1:00–3:00 | 2.0 | 80% wisp, 20% crawler | |
| 3:00–5:00 | 3.0 | 60% wisp, 30% crawler, crow lines every 30 s | |
| 5:00 | — | — | **Thorn Queen** |
| 5:00–8:00 | 4.0 | 50% wisp, 25% crawler, 15% golem, 10% thief | Crow lines every 25 s |
| 8:00–10:00 | 5.5 | 40% wisp, 25% crawler, 25% golem, 10% thief | Ring swarm at 9:00 (40 wisps surround player) |
| 10:00 | — | — | **Banyan Wraith** |
| 10:00–13:00 | 7.0 | 35% wisp, 30% crawler, 25% golem, 10% thief | Crow lines every 20 s |
| 13:00–14:30 | 9.0 | mixed | Dawn begins brightening |
| 14:30 | — | — | **Eclipse Beast** |
| 15:00 | — | — | **DAWN — victory** |

Store the wave table as data (`data/waves/forest_edge.tres` or JSON), not code.

---

## 8. Meta-progression: The Village

### 8.1 Currencies
| Currency | Type | Earned from | Spent on |
|---|---|---|---|
| **Coins** | Soft | Runs, missions, chests | Building upgrades, hero unlock |
| **Timber** | Material | Bosses, chests, dawn bonus | Building upgrades from L4+ |
| **Gems** | Premium | IAP, missions (small), achievements | Revive, skip build timers, Guardian Chests, cosmetics |

### 8.2 Run rewards
- Coins: `kills / 8 + minutes_survived × 12`, ×1.5 on dawn victory (+200 dawn bonus).
- Timber: Thorn Queen 3, Banyan Wraith 6, Dawn 10.
- All multipliers in remote config.

### 8.3 Buildings (MVP: 7, levels 1–10)
| ID | Building | Bonus per level |
|---|---|---|
| `bld_blacksmith` | Blacksmith | +4% damage |
| `bld_healer` | Healer's Hut | +6 max HP |
| `bld_watchtower` | Watchtower | +6% pickup radius |
| `bld_granary` | Granary | +5% coins from runs |
| `bld_training` | Training Ground | +2% move speed |
| `bld_library` | Library | +4% XP; +1 reroll at L3, L6, L9 |
| `bld_lamp_tower` | Lamp Tower | L1: unlocks revive slot; +2% armor-equivalent per level |

**Cost formula:** `coins = round(120 × 1.55^(level-1))`; `timber = 0` for L1–3, else `round(2 × 1.4^(level-4))`.

**Build timers:** L1–3 instant. L4: 5 min, then ×1.8 per level, capped at 8 h. Only 1 building upgrades at a time (2nd builder slot = IAP/gems later). Gems skip cost: `ceil(remaining_minutes / 6)`.

### 8.4 Village screen
- Top-down or isometric-lite illustration of the village; each building visibly changes at L1, L4, L7, L10.
- Tap building → panel with current bonus, next bonus, cost, Upgrade button.
- Village lamps light up as total village level increases (visual reward).

### 8.5 Retention systems
- **Daily missions:** 3 per day from a pool (e.g., "Kill 500 wisps", "Survive 10 min", "Evolve a weapon"). Rewards: coins + 10 gems each. Reset 00:00 local time.
- **Daily login calendar:** 7-day loop. Day 7 = 50 gems.
- **Free Chest:** every 6 hours (coins, timber, chance of gems). Rewarded ad = open an extra one (max 3/day).
- **Achievements:** one-time gem rewards (first dawn, 10,000 kills, all buildings L5, etc.).

---

## 9. Monetization

### 9.1 Principles
- No forced interstitial ads in MVP.
- No pay-to-win content locks; IAP accelerates and decorates.
- Show prices from Google Play (localised), never hard-coded strings in UI.

### 9.2 In-app products (Google Play Console)
| Product ID | Type | Contents | Target price (INR) |
|---|---|---|---|
| `gems_80` | Consumable | 80 gems | ₹89 |
| `gems_500` | Consumable | 500 gems (+10%) | ₹449 |
| `gems_1200` | Consumable | 1,200 gems (+20%) | ₹899 |
| `gems_2800` | Consumable | 2,800 gems (+35%) | ₹1,799 |
| `starter_pack` | Non-consumable (one-time) | 300 gems, 2,000 coins, 20 timber, exclusive "Dawnbringer" Muthu skin | ₹149 |
| `ad_free_pass` | Non-consumable | All rewarded-ad rewards granted instantly without watching | ₹249 |
| `hero_ammu` | Non-consumable | Unlock Ammu immediately | ₹199 |
| `builder_2` | Non-consumable | Second simultaneous building upgrade | ₹299 |
| *(v2)* `dawn_pass_s1` | Consumable or subscription | Season pass premium track | ₹399 / season |

**Starter pack trigger:** shown once after the player's first run ends, then available in shop for 72 h with a countdown, then permanently in shop without countdown (keep it honest — no fake urgency resets).

### 9.3 Gem sinks (in-game prices)
| Use | Gems |
|---|---|
| Revive (once per run; requires Lamp Tower L1) | 30 (or watch ad) |
| Skip build timer | `ceil(remaining_minutes / 6)` |
| Guardian Chest | 120 |
| Skins | 300–800 |

### 9.4 Randomised items — legal requirement
Guardian Chest and Free Chest contents are random. **Display drop odds** in the chest's info panel (Google Play policy). Store odds in data and render them from the same data the roll uses.

### 9.5 Rewarded ads (AdMob)
| Placement | Reward | Cap |
|---|---|---|
| Revive | Revive with 50% HP + clear nearby enemies | 1 per run |
| Results screen | Double coins | Once per run |
| Free chest | Open an extra free chest | 3/day |

- Always use Google test ad unit IDs in debug builds. Real IDs only in release config.
- Show UMP consent form before first ad request where required.

### 9.6 Billing implementation rules
- On app start: connect billing → query existing purchases → restore non-consumables.
- Consumables: grant gems, then **consume** the purchase.
- Non-consumables: grant, then **acknowledge** within 3 days (unacknowledged purchases are auto-refunded by Google).
- Handle: pending purchases, cancelled, already owned, network failure.
- Persist entitlement state locally; reconcile with Play on every launch.
- *(Post-launch)* Server-side receipt validation via a Firebase Cloud Function + Google Play Developer API.

---

## 10. Screens & UX

| Screen | Key elements |
|---|---|
| Splash | Logo, loading bar, consent flow (first launch) |
| Home / Village | Village view, currencies bar (coins/timber/gems + "+" to shop), **Start Night** big button, hero portrait, nav: Village · Heroes · Shop · Missions · Settings |
| Hero select | Hero cards, stats, skin picker, unlock button |
| Run HUD | HP bar, XP bar (top), timer (top centre), kill count, coin count, weapon/passive icons with levels, pause |
| Level-up modal | 3 cards with icon, name, level, description, "NEW"/"EVOLVE" tags; reroll button |
| Boss banner | Name + warning, top boss HP bar |
| Pause | Resume, current build, settings, quit (confirm) |
| Revive | Countdown 5 s, "Watch ad" / "30 gems" / "Give up" |
| Results | Victory/Defeat, time, kills, coins, timber, "Double coins (ad)", Continue |
| Shop | Featured (starter pack), Gems, Chests (with odds), Heroes, Skins, Ad-free pass, Restore purchases |
| Missions | Daily missions, login calendar, achievements |
| Settings | Music/SFX volume, haptics, damage numbers, joystick size, language, privacy policy link, support email, credits |

**UX rules:**
- Minimum touch target 48 dp.
- Respect safe areas / notches.
- Every purchase button shows the Play-localised price.
- Haptic tick on level-up and boss kill (toggleable).
- First run: 3 short contextual hints (move, collect embers, choose upgrade). No long tutorial.

---

## 11. Art & audio direction

- **Palette:** deep indigo/teal night, warm amber lamp-light, ember orange for XP, dawn pink/gold for victory.
- **Style:** clean 2D, readable silhouettes, slight outline on enemies for contrast against dark ground.
- **Readability rule:** player always visible; enemy projectiles are bright and distinct; XP embers glow.
- **MVP:** coloured shapes (circle = hero, triangles = wisps, etc.). Swap in Kenney packs in Phase 4.
- **Audio:** soft ambient night loop, punchy hit SFX, satisfying ember pickup "ting" (pitch rises with combo), level-up chime, boss stinger, dawn theme.
- Keep a `CREDITS.md` listing every asset, source URL, and licence.

---

## 12. Architecture (Godot)

### 12.1 Folder structure
```
res://
  project.godot
  autoload/
    game_state.gd        # runtime profile: currencies, buildings, unlocks
    save_manager.gd      # load/save JSON, versioning, migration
    economy.gd           # all cost/reward formulas (pure functions)
    remote_config.gd     # fetch + cache + defaults
    billing_service.gd   # wraps Play Billing plugin; mock in editor/desktop
    ads_service.gd       # wraps AdMob plugin; mock in editor/desktop
    analytics.gd         # event logging facade
    audio_manager.gd
    scene_router.gd      # screen transitions
  data/
    heroes/*.tres  weapons/*.tres  passives/*.tres  evolutions/*.tres
    enemies/*.tres  bosses/*.tres  waves/*.tres  buildings/*.tres
    missions.json  chests.json  products.json  remote_config_defaults.json
  scripts/
    resources/           # WeaponData, EnemyData, ... (class_name extends Resource)
    run/                 # run_manager.gd, spawner.gd, spatial_grid.gd, xp_system.gd, levelup_roller.gd
    entities/            # player.gd, enemy.gd, boss_*.gd, ember.gd, projectile.gd
    weapons/             # base_weapon.gd + one script per weapon
    ui/
  scenes/
    main.tscn  home/  run/  ui/
  assets/
    sprites/  audio/  fonts/  shaders/
  addons/
    gut/  (billing plugin)  (admob plugin)
  tests/
    unit/  integration/
docs/
  GAME_SPEC.md
  PROGRESS.md
CREDITS.md
```

### 12.2 Key patterns
- **Data-driven:** every number in §4–§9 lives in `data/` or remote config, never hard-coded in gameplay scripts.
- **Service facades:** `BillingService` and `AdsService` expose the same API with a **mock implementation** on desktop/editor so the game is fully testable without a phone.
- **Signals over direct references** between systems (e.g., `enemy_died(enemy_data, position)`).
- **Object pooling** for enemies, projectiles, embers, damage numbers.
- **No physics bodies for enemies.** Move enemies manually; detect collisions with a uniform **spatial hash grid** (cell 64 px). Player and bosses may use Area2D.
- **Embers:** render with `MultiMeshInstance2D` when count > 100; auto-merge embers when > 400 on map.
- **Run state is separate from profile state.** A run never mutates `GameState` until the results screen commits rewards.

### 12.3 Save system
- File: `user://save.json`, with `save_version` integer and migration functions.
- Save on: results commit, purchase grant, building start/finish, app pause (`NOTIFICATION_APPLICATION_PAUSED`).
- Write to temp file then rename (atomic).
- Simple checksum to detect casual tampering (not real security).
- Build timers use **wall-clock UTC timestamps** (start + duration), so they progress while the app is closed.

### 12.4 Remote config (JSON)
```json
{
  "config_version": 1,
  "enemy_hp_scale_per_min": 0.12,
  "enemy_dmg_scale_per_min": 0.05,
  "max_enemies": 300,
  "coin_multiplier": 1.0,
  "xp_multiplier": 1.0,
  "build_timer_multiplier": 1.0,
  "starter_pack_enabled": true,
  "free_chest_hours": 6
}
```
Fetch on launch (timeout 3 s), cache to `user://remote_config.json`, fall back to bundled defaults.

---

## 13. Performance budget

| Item | Budget |
|---|---|
| Enemies on screen | 300 (cap) |
| Projectiles | 200 |
| Embers | 400 before merging |
| Draw calls | < 150 (use texture atlases) |
| Frame time | ≤ 16.6 ms on target device |
| APK/AAB size | < 80 MB |
| Cold start | < 4 s to Home |

Add a debug overlay (FPS, enemy count, projectile count) toggled by a hidden gesture or debug build flag.

---

## 14. Analytics events
`app_open`, `run_start {hero}`, `run_end {result, time, kills, level, coins}`, `level_up {level, choice_id}`, `evolution {id}`, `boss_killed {id, time}`, `building_upgrade {id, level}`, `shop_open`, `iap_start {sku}`, `iap_success {sku}`, `iap_fail {sku, reason}`, `ad_show {placement}`, `ad_reward {placement}`, `mission_complete {id}`, `tutorial_step {n}`.

Key metrics to watch: D1/D7 retention, average run length, % runs reaching 10:00, starter pack conversion, ARPDAU.

---

## 15. Testing

### 15.1 Automated (GUT, headless)
- `economy.gd`: cost formulas, reward formulas, timer gem-skip cost.
- `levelup_roller.gd`: never offers maxed items, respects slots, evolution eligibility.
- `save_manager.gd`: round-trip, migration from older version, corrupted file fallback.
- `spawner`: wave table produces expected mix/rate at given times.
- `billing_service` (mock): consume/acknowledge flows, restore, pending.

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

### 15.2 Manual checklist per phase
- Plays at 60 FPS on a real mid-range Android phone.
- No softlocks on pause/resume, app background/foreground, rotation lock.
- Purchases tested with Play Console **licence testers**.
- Ads tested with **test IDs** only.

---

## 16. Release checklist (Google Play)

1. Google Play Console developer account (one-time USD 25 fee).
2. **New personal accounts:** closed test with **≥ 12 testers opted in for 14 continuous days** before applying for production. Testers must actually play. Plan this early (church/friends/colleagues).
3. Android export: Godot export templates, Android SDK, JDK 17, **Gradle build enabled** (required for plugins).
4. Generate upload keystore (`keytool`), store it safely + backed up. Enable Play App Signing.
5. Export **AAB** (not APK) for Play.
6. Target API level: whatever Play Console currently requires — check before release.
7. Privacy policy URL (host on GitHub Pages) covering ads, analytics, purchases.
8. Data safety form (ads ID, analytics, purchase history).
9. Content rating questionnaire (IARC). Target audience 13+.
10. Store listing: icon 512×512, feature graphic 1024×500, 4–8 phone screenshots, short (80 chars) & full description, 30 s trailer (optional, recommended).
11. Create all IAP products in Play Console with IDs from §9.2. Set licence testers.
12. AdMob: app registered, ad units created, `app-ads.txt` on your developer website.
13. Pre-launch report review (Play Console auto-tests on devices).

---

## 17. Build phases & acceptance criteria

### Phase 0 — Project setup
- Godot project, Compatibility renderer, portrait 1080×1920 base with `canvas_items` stretch, `expand` aspect.
- Folder structure (§12.1), autoload stubs, GUT installed, one passing test.
- `docs/PROGRESS.md` created.
- **Done when:** project opens, blank main scene runs, headless tests pass.

### Phase 1 — Core loop (placeholder shapes)
- Floating joystick, player movement, camera follow, bounded map.
- One enemy type (wisp), spawner (ring), spatial grid collisions, contact damage, i-frames.
- One weapon (Sling Stone), projectile pooling, hit flash, damage numbers.
- Embers, magnet pickup, XP bar, level-up modal with 3 cards (Sling levels + 2 passives).
- Timer, death → simple results screen → restart.
- **Done when:** a full 15-min run is playable on desktop and Android at 60 FPS with 300 wisps.

### Phase 2 — Content
- All 8 weapons, 6 passives, 4 evolutions, 5 enemies, 3 bosses, boss chests.
- Wave timeline from data.
- Darkness + light radius, dawn transition, victory flow.
- **Done when:** every weapon/passive/evolution is obtainable and works; all bosses fight correctly; tests for roller + spawner pass.

### Phase 3 — Meta-progression
- GameState, SaveManager (atomic, versioned), Economy formulas.
- Coins/Timber/Gems, run reward commit.
- Village screen with 7 buildings, upgrade costs, build timers (wall-clock), gem skip.
- Hero select + Ammu unlock by coins.
- Daily missions, login calendar, free chest with odds display, achievements.
- **Done when:** progress survives app kill/restart; timers progress while closed; economy tests pass.

### Phase 4 — UI polish & juice
- Final UI layouts for all screens (§10), safe areas, 48 dp targets.
- Kenney art swap, atlases, particles (ember sparkle, hit, death puffs, level-up burst).
- Audio manager, music + SFX, haptics, settings persistence.
- Screen shake (small), boss banners, first-run hints.
- **Done when:** game feels responsive and readable; settings all work.

### Phase 5 — Monetization
- BillingService (real plugin on Android, mock on desktop): all products in §9.2, restore, consume/acknowledge, pending handling.
- Shop screen with Play-localised prices, starter pack trigger logic.
- AdsService (AdMob + UMP consent): rewarded placements in §9.5, ad-free pass bypass.
- **Done when:** every product purchasable with licence tester accounts; restore works after reinstall; ads show with test IDs.

### Phase 6 — Remote config & analytics
- Remote config fetch/cache/defaults wired to all tunables.
- Analytics facade + events in §14.
- Debug overlay.
- **Done when:** changing hosted JSON changes difficulty/rewards without a new build.

### Phase 7 — Release prep
- Release export config, keystore, AAB build script.
- Privacy policy page, store listing text draft, screenshot capture mode (hides debug UI).
- Closed test track build.
- **Done when:** AAB uploaded to closed testing, 12+ testers invited.

### Post-launch (v1.1+)
Season pass, skins shop expansion, 2nd map, 3rd hero, cloud save (Play Games), server-side receipt validation, Tamil/Hindi localisation, iOS port.

---

## 18. Prompts to paste into Claude Code (one per phase)

**Phase 0**
> Read CLAUDE.md and docs/GAME_SPEC.md fully. Implement Phase 0 exactly as specified in §17. Create docs/PROGRESS.md. Stop after Phase 0 and summarise what was created and how to run it.

**Phase 1**
> Implement Phase 1 from docs/GAME_SPEC.md §17. Use placeholder shapes only. Follow the architecture in §12 (spatial grid, pooling, data-driven). Write GUT tests where logic is pure. Update docs/PROGRESS.md. Stop and tell me how to test on desktop and Android.

**Phase 2**
> Implement Phase 2. All weapon/passive/enemy/boss numbers must come from data files matching §5–§7. Add tests for the level-up roller and wave spawner. Update PROGRESS.md and stop.

**Phase 3**
> Implement Phase 3 (meta-progression) per §8 and §12.3. Economy formulas as pure functions with tests. Build timers must use UTC wall-clock. Update PROGRESS.md and stop.

**Phase 4**
> Implement Phase 4 (UI polish & juice) per §10–§11. List any Kenney asset packs I need to download and where to place them before you start. Update PROGRESS.md and stop.

**Phase 5**
> Implement Phase 5 (monetization) per §9. Mock services on desktop, real plugins on Android. Use only Google test ad IDs. Tell me exactly which Play Console and AdMob setup steps I must do manually. Update PROGRESS.md and stop.

**Phase 6**
> Implement Phase 6 per §12.4 and §14. Provide the remote_config.json I should host and instructions to host it on GitHub Pages. Update PROGRESS.md and stop.

**Phase 7**
> Implement Phase 7 per §16–§17. Give me a step-by-step release checklist with the commands to build the signed AAB. Draft the store listing text and privacy policy. Update PROGRESS.md and stop.

---

## 19. Open decisions (owner: Jeyadevan)
- Final game name + trademark check.
- Custom art budget after validation (commission vs. stay with packs).
- Organisation vs. personal Play account (organisation skips the 12-tester rule but needs a D-U-N-S number).
- Check employment contract (Aeries) for moonlighting / IP clauses before publishing.

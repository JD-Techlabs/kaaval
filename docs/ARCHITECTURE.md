# Kavaryn: Guardians of Dawn — Architecture and Flows

This document explains how the game is put together: the layers, what happens at run time, and which file owns each piece of behaviour. It describes the code as it stands on 2026-11-16.

Related documents: `docs/GAME_SPEC.md` (the design, source of truth), `docs/PROGRESS.md` (status, decisions, known issues), `docs/RELEASE_CHECKLIST.md` (steps to publish), `CLAUDE.md` (working rules).

## 1. The game in one paragraph

Kavaryn is a portrait, one-thumb survival game for Android built with Godot 4.7 (GDScript, Compatibility renderer, 1080×1920). The player picks a hero and survives a 15-minute night against waves of creatures; weapons fire on their own, defeated creatures drop embers (XP), and each level-up offers a choice of upgrades. Between nights the player spends coins and timber on a village whose buildings make every later night easier. Money comes from optional in-app purchases and rewarded ads.

## 2. Layers

```
┌──────────────────────────────────────────────────────────────────────┐
│ UI            scripts/ui/          screens, HUD, modals (built in code)│
├──────────────────────────────────────────────────────────────────────┤
│ Run           scripts/run/         one night: simulation + flow        │
│               scripts/entities/    hero, creatures, bosses, projectiles│
│               scripts/weapons/     the eight weapons                   │
├──────────────────────────────────────────────────────────────────────┤
│ Meta rules    scripts/meta/        village, chests, gifts, missions,   │
│                                    committing a finished night         │
├──────────────────────────────────────────────────────────────────────┤
│ Singletons    autoload/            profile, save, config, store, ads,  │
│                                    audio, analytics, scene changes     │
│ Backends      scripts/services/    Play Billing / AdMob / mocks        │
├──────────────────────────────────────────────────────────────────────┤
│ Data          data/                every number (.tres and .json)      │
│ Data classes  scripts/resources/   typed Resource classes for .tres    │
│ Registry      scripts/game_data.gd loads and caches everything in data/│
└──────────────────────────────────────────────────────────────────────┘
```

Rules that hold everywhere:

- **Data-driven.** Gameplay and economy numbers live in `data/`. Scripts read them through `GameData`; they do not hard-code them.
- **A night never changes the profile.** `RunManager` writes only to its own `RunState`. The results screen calls `RunCommit.commit()`, the one place a night's rewards reach `GameState`. The single exception is paying gems to revive, which is a purchase.
- **Rules are separate from storage.** `GameState` stores the profile. The rules for changing it are static functions in `scripts/meta/`, which makes them testable without any UI.
- **Systems talk through signals.** For example `EnemyManager.enemy_died` → `RunManager` → embers, potions, kill counts.
- **No physics bodies for creatures.** They move themselves; hits are resolved through a spatial hash grid. Creatures, projectiles and damage numbers are pooled.
- **Same API on every platform.** `BillingService` and `AdsService` pick a backend at start-up: the real plugin on Android, a mock on desktop.

## 3. Singletons (`autoload/`)

Registered in `project.godot` and loaded in this order.

| Singleton | File | Responsibility |
|---|---|---|
| `RemoteConfig` | `autoload/remote_config.gd` | Tunables that can change without an app update. Bundled defaults → cached copy → fetched JSON. Accepts only keys that exist in the defaults, with matching type. |
| `SaveManager` | `autoload/save_manager.gd` | Reads and writes the save file: versioned JSON, salted SHA-256 checksum, temp-file-then-rename. A bad file is copied aside and a fresh profile starts. |
| `GameState` | `autoload/game_state.gd` | The player's profile in memory (`p`): currencies, buildings, heroes, hero pieces, gifts, potions, skins, entitlements, missions, settings. Emits `changed`. |
| `Economy` | `autoload/economy.gd` | Pure cost and reward formulas (run coins, building cost, timers, gem skip price). |
| `Analytics` | `autoload/analytics.gd` | `log_event()` facade with a local logger; `set_sink()` attaches a real backend. |
| `AudioManager` | `autoload/audio_manager.gd` | Music, a pool of sound-effect voices, haptics; follows the saved volume settings. |
| `BillingService` | `autoload/billing_service.gd` | In-app purchases: prices, purchase, grant, consume or acknowledge, restore. |
| `AdsService` | `autoload/ads_service.gd` | Rewarded ads and the consent flow; honours the Ad-Free Pass. |
| `SceneRouter` | `autoload/scene_router.gd` | `goto(screen)` with a short fade. Maps screen names to scenes. |

## 4. Data (`data/`)

`scripts/game_data.gd` (`GameData`) is a static registry. It loads lazily, caches, and exposes typed getters such as `GameData.weapon(id)`, `GameData.heroes()`, `GameData.num("run", "camera_zoom")` and `GameData.json("roster")`.

| Path | Format | Holds |
|---|---|---|
| `data/balance.json` | JSON | Hero base stats, XP curve, combat timings, run settings (camera zoom, soft start, revive), spawn and crowd settings, embers, potions, gifts, darkness, economy constants. |
| `data/weapons/*.tres` | `WeaponData` | Eight weapons: level-1 values and per-level growth. |
| `data/passives/*.tres` | `PassiveData` | Six passives: stat, mode, value per level. |
| `data/evolutions/*.tres` | `EvolutionData` | Weapon + passive pairs and the evolved weapon's overrides. |
| `data/heroes/*.tres` | `HeroData` | Six heroes: stat modifiers, starting weapon, resource bonus, strength band, coin price, pieces needed, Play product. |
| `data/weapon_lines/*.tres` | `WeaponLineData` | Each hero's starting weapon through the seven ages: name, icon, sprite, power, stat gains, called-in strikes. |
| `data/ages/*.tres` | `AgeData` | Seven village ages: resources paid, building cap, building levels and resources needed to enter, creature HP/damage and resource multipliers, hero gear. |
| `data/lands/*.tres` | `LandData` | The village green and six pieces of land: coin price and the age that opens them. |
| `data/enemies/*.tres` | `EnemyData` | Nine creatures: HP, speed, damage, XP, radius, behaviour, split on death. |
| `data/bosses/*.tres` | `BossData` | Three bosses: stats, script, warning text, timber reward. |
| `data/waves/forest_edge.tres` | `WaveData` | The night's timeline: spawn-rate segments, creature mix, timed events (bosses, ring swarm). |
| `data/buildings/*.tres` | `BuildingData` | Sixteen buildings: land, stat bonus and/or production per level, storage hours, extra resource costs, position inside the land, colours. |
| `data/roster.json` | JSON | Creature ranks and which creature debuts at each hero level. |
| `data/chests.json` | JSON | Drop tables for the Free Chest, Guardian Chest and Hero Gift. Rolls and the on-screen odds both read these weights. |
| `data/missions.json` | JSON | Daily mission pool, 7-day login calendar, achievements. |
| `data/products.json` | JSON | Play product IDs, what each grants, example prices for the test store, and skins. |
| `data/remote_config_defaults.json` | JSON | Default values for every remotely tunable key. |
| `data/app_config.json` | JSON | Privacy policy URL, support email, remote config URL, ad unit IDs for debug. |

The Resource classes behind the `.tres` files are in `scripts/resources/` (`weapon_data.gd`, `passive_data.gd`, `evolution_data.gd`, `hero_data.gd`, `enemy_data.gd`, `boss_data.gd`, `wave_data.gd`, `building_data.gd`, `age_data.gd`, `land_data.gd`, `weapon_line_data.gd`).

## 5. Screens and navigation

```
Splash ──► Home (Village) ──► Start Night ──► Run ──► Results ──► Home
                │
                ├──► Heroes   (select, unlock, skins, Hero Gifts)
                ├──► Shop     (gems, supplies, chests, heroes, skins, passes)
                ├──► Missions (login calendar, daily missions, achievements)
                └──► Settings (audio, joystick, privacy, credits)
```

Each screen is a tiny `.tscn` under `scenes/` whose root node carries one script; the script builds the interface in code.

| Screen | Scene | Script | Notes |
|---|---|---|---|
| Splash | `scenes/main.tscn` | `scripts/ui/main.gd` | Logo and loading bar; starts the ad consent flow; never waits on it for long. |
| Home | `scenes/home/home.tscn` | `scripts/ui/home_screen.gd` | Currencies, village, hero row, Start Night, bottom navigation, one-time Starter Pack offer. |
| Run | `scenes/run/run.tscn` | `scripts/run/run_scene.gd` | Creates `RunManager` (the simulation) and `RunUi` (everything drawn over it). |
| Heroes | `scenes/ui/heroes.tscn` | `scripts/ui/heroes_screen.gd` | Hero cards, piece progress, unlock buttons, skin picker, gift opening and odds. |
| Shop | `scenes/ui/shop.tscn` | `scripts/ui/shop_screen.gd` | Every real-money price on a button comes from the store backend. |
| Missions | `scenes/ui/missions.tscn` | `scripts/ui/missions_screen.gd` | Claim buttons for login days, missions and achievements. |
| Settings | `scenes/ui/settings.tscn` | `scripts/ui/settings_screen.gd` | `add_controls()` is reused by the in-run pause menu. |

Shared UI code:

| File | Purpose |
|---|---|
| `scripts/ui/ui_kit.gd` | Palette, theme, and builders for labels, buttons, panels, bars, modals and message boxes. Long messages scroll. |
| `scripts/ui/base_screen.gd` | Frame for menu screens: back button, currency bar, scrolling content. Rebuilds when `GameState.changed` fires. Lets a drag that starts on a card or button scroll the list. |
| `scripts/ui/village_view.gd` | Draws the village ground, paths, lamps, name plates and "can afford" badges; handles taps on buildings. |
| `scripts/ui/village_art.gd` | Draws each building's own shape in four growth stages. |
| `scripts/ui/building_panel.gd` | Building details, upgrade button, build timer and gem skip. |
| `scripts/ui/run_ui.gd` | Joystick, HUD and the run's modals (level-up, chest, pause, revive, results). |
| `scripts/ui/hud.gd` | XP bar with level, HP bar with numbers, timer, kill and coin counters, build icons, pause and potion buttons, boss bar, banners and notices. |
| `scripts/ui/joystick.gd` | Floating joystick: appears under the finger, writes `RunManager.input_dir`. |
| `scripts/ui/edge_pointers.gd` | Edge-of-screen arrows to off-screen bosses, boss chests and (when hurt) potions. |
| `scripts/ui/levelup_modal.gd` | The three-card level-up choice with reroll, and the Boss Chest reveal. |
| `scripts/ui/results_screen.gd` | End-of-night summary, optional ad to double coins, and the Continue button that commits. |
| `scripts/ui/screenshot_tool.gd` | F12 capture and command-line capture options, including a throwaway demo profile. |

## 6. A night (the run)

### 6.1 Objects

`RunManager` (`scripts/run/run_manager.gd`) builds and owns everything in a night:

| Part | File | Role |
|---|---|---|
| State | `scripts/run/run_state.gd` | Time, level, XP, kills, weapons, passives, evolutions, potions used. `summary()` is what the results screen receives. |
| Hero | `scripts/entities/player.gd` | Movement, HP, invulnerability frames, heal, revive, small HP bar. |
| Hero stats | `scripts/run/player_stats.gd` | `(base + flat) × (1 + percent)` from hero, buildings and passives. Pure. |
| Weapons | `scripts/weapons/base_weapon.gd` + one file per weapon | Cooldown loop and data-driven stats; each weapon overrides `fire()` or `step()`. |
| Weapon line | `scripts/run/weapon_line.gd` | `weapon_for()` turns the hero's starting weapon into its tier for the current age (a tiered copy of `WeaponData`). Used by the run and every UI that shows a weapon. |
| Strikes | `scripts/run/strike_caller.gd` | Tank, jet and missile strikes from the tier's data; vehicles drawn on a screen layer above the darkness. |
| Creatures | `scripts/run/enemy_manager.gd`, `scripts/entities/enemy.gd` | Pool, movement, crowd spreading, contact damage, damage and death. |
| Grid | `scripts/run/spatial_grid.gd` | Uniform grid rebuilt each step for fast "who is near here" queries. |
| Bosses | `scripts/entities/boss.gd`, `boss_thorn_queen.gd`, `boss_banyan_wraith.gd`, `boss_eclipse_beast.gd` | Shared chase and charge, plus each boss's own attacks. |
| Wave timeline | `scripts/run/spawner.gd` | Turns `WaveData` into spawn requests. Knows nothing about nodes. |
| Spawn execution | `scripts/run/run_events.gd` | Carries out requests: regular spawns, crow lines, ring swarms, bosses after a 2-second warning; owns boss chests. |
| Level roster | `scripts/run/roster.gd` | Decides which creature and rank a regular spawn becomes, from the hero's level. |
| Projectiles | `scripts/run/projectile_pool.gd`, `scripts/entities/projectile.gd` | Pooled hero projectiles. |
| Boss attacks | `scripts/run/hazards.gd` | Telegraphed circles, charge lines and bullets, drawn in one pass. |
| Embers | `scripts/run/ember_field.gd` | XP pickups in flat arrays, drawn with one MultiMesh; magnet and merge. |
| XP | `scripts/run/xp_system.gd` | XP curve; returns how many levels were gained. |
| Level-up cards | `scripts/run/levelup_roller.gd` | Builds the cards on offer and applies a chosen card. Pure. |
| Boss chest | `scripts/run/boss_chest.gd` | An evolution if one is eligible, otherwise 1–3 upgrades, plus coins. |
| Potions | `scripts/run/potions.gd` | Ground potions (drop odds, pickup) and drinking bought potions. |
| Effects | `scripts/run/fx.gd`, `damage_numbers.gd`, `darkness.gd`, `map_view.gd` | Particles and rings, floating numbers, night overlay with dawn and eclipse, the map and its props. |

### 6.2 One simulation step

`RunManager._process()` calls `advance(delta)` only while the mode is `PLAYING`. Tests and the balance probe call `advance()` directly, so a whole night can run headless. The order inside `advance()`:

1. Advance the clock.
2. Move the hero from joystick or keyboard input.
3. Step every weapon (they spawn projectiles or deal damage).
4. Set the creatures' base rank from the hero's level.
5. Ask the `Spawner` for requests and execute each one.
6. Step pending boss warnings and boss-chest pickup.
7. Step creatures: move, crowd spreading, burn damage, contact damage.
8. Step projectiles, then boss hazards, then potions.
9. Step embers; collected XP may add levels.
10. Step effects and damage numbers; update camera, darkness and dawn.
11. Decide what happens next: dawn reached → victory; hero died → revive offer or defeat; level gained → open the level-up choice.

### 6.3 Modes

```
            level gained                    card chosen
 PLAYING ───────────────► CHOOSING ───────────────────► PLAYING
    │   boss chest picked up            closed
    ├──────────────────────► CHEST ───────────────────► PLAYING
    │   pause / app backgrounded        resume
    ├──────────────────────► PAUSED ──────────────────► PLAYING   (or give up → ENDED)
    │   HP reaches 0 and revive is available
    ├──────────────────────► REVIVE ── ad or gems ────► PLAYING   (or give up / timeout → ENDED)
    │   15:00 reached, or death with no revive
    └──────────────────────► ENDED ──► results screen
```

`RunManager` announces each change with a signal (`levelup_requested`, `chest_opened`, `revive_offered`, `run_ended`, `boss_changed`, `banner_requested`, `notice_requested`, `build_changed`, `hint_requested`); `RunUi` and `Hud` listen and show the matching interface.

### 6.4 Who spawns

Two inputs combine:

- **Time** sets the pace. `WaveData` segments give a spawn rate and a creature mix for each stretch of the night, plus timed events (three bosses, one ring swarm). Enemy HP and damage also rise per minute from `RemoteConfig`. Damage starts at half and reaches full strength at 5:00 (`run.early_damage_mult`).
- **Hero level** sets who shows up. For each regular spawn, `Roster.pick()` either keeps the creature the wave asked for, at the current base rank, or (20% of the time) swaps in one of the three most recent "debut" creatures. Every level from 2 to 36 has one debut. The base rank rises every 6 levels. A rank multiplies HP, damage, speed, size and XP and tints the sprite.

### 6.5 Level-up and evolutions

`XpSystem.add_xp()` reports levels gained → `RunManager` enters `CHOOSING` and emits cards from `LevelupRoller.roll()` → `LevelupModal` shows them → the player's pick goes to `RunManager.choose_card()` → `apply_card()` adds or levels a weapon or passive, or grants the fallback coins or heal. A weapon at max level with its matching passive becomes eligible for evolution; the evolution is delivered by a Boss Chest (`BossChest.open()`).

### 6.6 Ending a night

`RunManager._finish()` emits `run_ended(summary)`. `ResultsScreen.open()` shows time, kills, level, coins, timber, gifts earned and potions used, and offers an ad to double coins. **Continue** calls `RunCommit.commit(summary, coins)`, which grants coins, timber and gifts, removes the potions that were drunk, records mission and achievement progress, and saves.

## 7. Between nights (meta)

All rules are static functions in `scripts/meta/`.

| Area | File | Flow |
|---|---|---|
| Village | `village_logic.gd` | `blocker()` says why an upgrade is refused; `start()` spends coins and timber and either levels up at once (levels 1–3) or creates a job with a finish time; `complete_due()` finishes jobs whose time has passed, including time spent with the app closed; `skip()` finishes a job for gems. One builder unless the Second Builder is owned. |
| Chests | `chest_logic.gd` | `roll()` picks a drop by weight; `odds()` and `odds_text()` turn the same weights into the percentages shown in game. Free Chest has a cooldown and a daily cap on ad-opened extras; Guardian Chest costs gems. |
| Hero Gifts | `gift_logic.gd` | `earned_for_level()` counts gifts for a night's level; `open()` spends one gift and rolls the `hero_gift` table. A hero-piece drop goes to a random collectable hero the player lacks; a complete set unlocks the hero. |
| Supplies | `supply_logic.gd` | Buy a life potion with coins, or a pack with gems. |
| Daily systems | `daily_logic.gd` | Three missions per local day (seeded by date), a looping 7-day login calendar, and achievements read from lifetime stats. |
| Run commit | `run_commit.gd` | Coins, timber and age resources (with the hero's bonus) for a night, the commit itself, hero unlock with coins, skin purchase with gems. |
| Ages | `age_logic.gd` | The current age, what the next one needs (`missing_buildings`, `missing_resources`, `blocker`), `advance()`, and the pure `run_resources()` formula. |
| Land | `land_logic.gd` | Owned land, `blocker()` (age, coins) and `buy()`. |
| Production | `production_logic.gd` | Wall-clock output per producer, storage cap, `collect()` / `collect_all()`, the AI Lab's village-wide bonus. |

Buildings affect a night through `PlayerStats.compute()`, which reads the building levels from `GameState` when the night starts.

## 8. Purchases and ads

### 8.1 Purchases

```
Shop button ─► BillingService.purchase(id) ─► backend.purchase(id)
                                                    │
        backend.purchases_updated  ◄────────────────┘
                 │
                 ├─ pending  ─► purchase_pending (nothing granted yet)
                 ├─ one-time ─► grant if not owned ─► acknowledge
                 └─ consumable ─► grant once per token ─► consume
                 │
        purchase_succeeded ─► screens refresh
```

- `autoload/billing_service.gd` holds the flow and applies a product's `grants` from `data/products.json` (currencies, hero, skin, entitlement).
- `scripts/services/billing_backend.gd` is the interface and also the "store unavailable" backend.
- `scripts/services/billing_android.gd` talks to Google Play through the GodotGooglePlayBilling plugin, with reconnect retries.
- `scripts/services/billing_mock.gd` is a pretend store that behaves like Play, used on desktop and in tests.
- Owned products are re-read on launch, on resume and from **Restore purchases**.
- A **debug** Android build that receives no prices from Play within 8 seconds switches to the mock store and the Shop shows a "Test store" notice. Release builds never do this.

### 8.2 Ads

- `autoload/ads_service.gd`: `start()` runs consent then initialises ads; `show_rewarded(placement, callback)` reports whether the reward was earned. With the Ad-Free Pass every reward is granted at once without an ad.
- `scripts/services/ads_android.gd`: AdMob rewarded ads and UMP consent through the Poing Studios plugin. Loads an ad only after the SDK reports it has initialised.
- `scripts/services/ads_mock.gd`: desktop stand-in that "plays" briefly and rewards.
- Rewarded placements: double coins on results, revive, extra Free Chest opens.
- Debug builds use Google's test ad unit IDs. Real IDs come from a git-ignored release config that `tools/build_release.ps1` injects.

## 9. Saving and remote config

- **Save.** `GameState.save()` → `SaveManager.save_data()` writes `user://save.json`. Saves happen after every rule that changes the profile, and when the app is paused or closed. On load, the saved data is merged over `GameState.default_profile()`, so profiles from older builds gain new fields with their defaults.
- **Remote config.** `RemoteConfig` starts from `data/remote_config_defaults.json`, applies a cached copy if present, then fetches the URL in `data/app_config.json` (empty until the JSON is hosted). It covers enemy scaling per minute, the creature cap, coin and XP multipliers, build-timer multiplier, Free Chest hours and the Starter Pack switch.

## 10. Start-up sequence

1. Godot loads the singletons in the order in section 3. `GameState` loads the profile; `BillingService` and `AdsService` choose their backends.
2. `scenes/main.tscn` shows the splash. `Main` calls `AdsService.start()` and waits a minimum time, or until consent finishes, with an upper limit.
3. `SceneRouter.goto("home")`.
4. `HomeScreen` completes any build jobs that finished while away, refreshes today's missions, and may show the one-time Starter Pack offer.

## 11. Assets

- `assets/sprites/**` — original SVG art, generated by `tools/gen_art.py`.
- `assets/audio/**` — sound effects and music, synthesised by `tools/gen_audio.py`.
- `assets/icons/**` — Android launcher icon PNGs, rendered by `tools/gen_icons.gd`.
- `assets/shaders/` — `darkness.gdshader` (night overlay) and `hit_flash.gdshader` (white flash on hit).

No third-party art or audio is used; see `CREDITS.md`.

## 12. Tests and tools

Tests use GUT and live in `tests/`. `tests/base_test.gd` gives every test a fresh profile, a throwaway save file, a fixed clock and default remote config.

| File | Covers |
|---|---|
| `tests/unit/test_core.gd` | Data loads, hero stats, content counts, spatial grid. |
| `tests/unit/test_economy.gd` | Cost, timer and reward formulas. |
| `tests/unit/test_levelup_roller.gd` | Card rules and evolution eligibility. |
| `tests/unit/test_spawner.gd` | Wave timeline, mix and events. |
| `tests/unit/test_roster.gd` | A new creature at every level, ranks, pooled creatures resetting. |
| `tests/unit/test_save_manager.gd` | Round trip, migration, corruption handling. |
| `tests/unit/test_billing_service.gd` | Purchase, consume, acknowledge, pending, restore, test-store rule, ads. |
| `tests/unit/test_meta.gd` | Village timers, chests and odds, missions, login calendar, achievements. |
| `tests/unit/test_gifts.gd` | Gifts, hero pieces, new heroes, buying potions. |
| `tests/integration/test_run_sim.gd` | A full simulated night, every weapon and evolution, revive, the "run never touches the profile" rule. |
| `tests/integration/test_potions.gd` | Potion drops, pickup, level fall-off, drinking bought potions. |
| `tests/integration/test_crowd.gd` | Crowd spreading and the soft start. |

| Tool | Purpose |
|---|---|
| `tools/gen_art.py`, `tools/gen_audio.py`, `tools/gen_icons.gd` | Regenerate art, audio and launcher icons. |
| `tools/check_scripts.gd` | Compiles every script and loads every resource. |
| `tools/balance_probe.tscn` / `.gd` | Plays nights with a simple bot and prints survival time, step cost and crowd overlap. Uses a throwaway profile. |
| `tools/store_graphics.ps1`, `tools/feature_graphic.tscn` / `.gd` | Produce the Play Store icon, feature graphic and phone screenshots into `docs/store/graphics/`. |
| `tools/build_release.ps1` | Builds the signed release bundle with the real ad IDs injected for that build only. |

Commands for running the game, tests and builds are in `docs/PROGRESS.md` under "How to run".

## 13. Where to change things

| To change… | Edit |
|---|---|
| Any balance number | `data/balance.json`, or the relevant `.tres` in `data/` |
| A weapon's behaviour | its script in `scripts/weapons/`; its numbers in `data/weapons/` |
| Add a creature | a new `.tres` in `data/enemies/`, a sprite in `tools/gen_art.py`, and entries in `data/roster.json` or the wave mix |
| Which creatures appear at which level | `data/roster.json` |
| The night's pacing and bosses | `data/waves/forest_edge.tres` |
| Add a hero | a new `.tres` in `data/heroes/`, a sprite, a default skin and (if sold) a product in `data/products.json` |
| Chest or gift contents and odds | `data/chests.json` |
| Missions, login rewards, achievements | `data/missions.json` |
| Products and example prices | `data/products.json` (real prices are set in Play Console) |
| A screen's layout | its script in `scripts/ui/` |
| A rule about the profile | the matching file in `scripts/meta/`, with a test |
| An age (names, caps, requirements, difficulty) | `data/ages/*.tres` |
| Land prices and order | `data/lands/*.tres` |
| A hero's weapon in each age, or their strikes | `data/weapon_lines/line_<hero>.tres` |
| A hero's age look | `AGE_GEAR` in `tools/gen_art.py`, then run it |

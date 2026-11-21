# PROGRESS — KAAVAL: Guardians of Dawn

Last updated: 2026-11-21

## Status

Phases 0–7 are implemented in code. The owner asked for the whole game in one pass, so the one-phase-at-a-time rule was not followed for this session.

| Phase | State | Verified how |
|---|---|---|
| 0 Project setup | Done | Headless import, 164 GUT tests pass |
| 1 Core loop | Done | Simulated 15-minute run in tests; played on desktop and Android emulator |
| 2 Content | Done | Tests: every weapon damages, every evolution obtainable, 3 bosses spawn, wave timeline |
| 3 Meta-progression | Done | Tests: save round-trip/migration/corruption, wall-clock timers across restart, economy |
| 4 UI polish & juice | Done, with a deviation (original art instead of Kenney packs, see Decisions) | Screenshots on desktop and emulator |
| 5 Monetization | Code done. **Not verified with real purchases or real ads** | Mock store tests; on the emulator the billing and AdMob plugins load and the consent call completes |
| 6 Remote config & analytics | Done. Remote URL is empty until you host the JSON | Tests: overrides change scaling and rewards |
| 7 Release prep | Debug APK builds and runs on the emulator. **Signed AAB not built** (needs your keystore, package name, AdMob IDs) | `build/kaaval-debug.apk` |

## Not verified — needs you

- **A real phone.** The 60 FPS target has not been measured on hardware. The emulator ran ARM code through translation at 27–40 FPS, which says nothing about a phone. Headless simulation costs about 0.5 ms per step on this PC.
- **Real purchases.** Needs the app in Play Console with products and licence testers. On the emulator the shop correctly shows "…" instead of prices because Play returned none.
- **Real ads and the consent form.** Needs an AdMob account, a published GDPR message, and a device with Play services signed in.
- **Balance by a human.** The current bot numbers are in the table under "Owner's second round" (median 3:24 with no village); no person has tuned them. An invulnerable bot reaches level 51 by dawn against the spec's 35–40 estimate; tune with `xp_multiplier` in remote config.

Follow `docs/RELEASE_CHECKLIST.md` for all of these.

## How to run

```powershell
# Play on desktop (mouse drags the joystick; arrow keys also move)
.tools\Godot_v4.7.2-stable_win64.exe --path .

# Tests
.tools\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# How long a simple bot survives (balance check); add --night=paddy_fields or --night=old_fort for later nights
.tools\Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tools/balance_probe.tscn -- --seeds=6 --village=0 --hero=hero_muthu

# Compile every script and load every resource
.tools\Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tools/check_scripts.gd

# Debug APK, then install on a connected phone
$env:JAVA_TOOL_OPTIONS = "-Djava.net.preferIPv4Stack=true"
.tools\Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android" build\kaaval-debug.apk
adb install -r build\kaaval-debug.apk
```

The headless exporter sometimes does not exit after printing `[ DONE ] export`; the APK is complete at that point and the process can be closed.

Desktop uses the mock store (purchases succeed after half a second, prices come from `data/products.json` `mock_price`) and mock ads (reward after 0.8 s).

## Where things are

- `data/` — every gameplay and economy number (`balance.json`, `.tres` per weapon/enemy/boss/building, `chests.json`, `missions.json`, `products.json`).
- `autoload/` — the nine singletons from spec §12.1.
- `scripts/run/` — the night: `run_manager.gd` steps every system from `advance()`.
- `scripts/meta/` — village, chest, daily and run-commit rules (pure logic over `GameState`).
- `scripts/services/` — store and ad backends (mock, Android, unavailable).
- `scripts/ui/` — screens and modals, all built in code.
- `tools/` — `gen_art.py`, `gen_audio.py` (regenerate assets), `check_scripts.gd`, `build_release.ps1`.
- `docs/` — spec, this log, release checklist, store listing, privacy policy, hosted remote config.

## Decisions

Spec gaps and deviations, simplest option chosen each time.

**Art and audio**
- Art is original SVG authored in `tools/gen_art.py` and audio is synthesised by `tools/gen_audio.py`, instead of Kenney packs. Nothing third-party to license; see `CREDITS.md`. Swapping in other art later means replacing files in `assets/sprites` with the same names.
- No texture atlas: there are about 40 small textures and same-texture sprites batch. Embers always use one MultiMesh (the spec asks for it above 100).
- Village buildings are drawn in code from their level, with four visual stages at L1, L4, L7, L10.
- Skins are colour tints of the hero sprite. Besides the Starter Pack's Dawnbringer there are two gem skins (300 and 500 gems) so the spec's Skins section is not empty.

**Gameplay numbers the spec leaves open** (all in `data/`)
- Mud Pup: speed 115, damage 6, XP 1. Boss speed, contact damage, radius and attack timings. Projectile speeds, ranges and hit radii.
- 13:00–15:00 "mixed" wave: 30% wisp, 30% crawler, 30% golem, 10% thief, at 9/s through to dawn.
- Bosses do not scale HP with time (the spec gives fixed HP); their contact damage does.
- Lamp Tower "+2% armor-equivalent" is a 2% cut to damage taken per level, capped at 60%.
- The 300-enemy cap also limits golem splits, boss summons, ring swarms and crow lines.
- Coins: `(kills/8 + minutes*12)`, on dawn `*1.5 + 200`, then bonus coins added, then Granary and remote multipliers. Bonus coins are thief drops (15), boss chests (120) and "+50 coins" cards.
- Boss chest with no evolution available auto-applies 1–3 random upgrades.
- Revive by gems spends the gems immediately, mid-run. This is the one place a run touches the profile before results, because it is a purchase.
- Giving up from the pause menu ends the run as a defeat and keeps what was earned.

**Meta**
- Building cost and time are for the level being bought. The 8-hour cap is never reached at max level 10 (L10 takes 170 minutes); it is implemented and tested.
- Daily missions are picked from a pool of 10 with the date as seed. "Survive" and "reach level" missions count the best single run; kill missions add up.
- Guardian Chest contents (coins and timber) and Free Chest contents are in `data/chests.json`; the odds panel reads the same weights the roll uses.
- Starter pack popup appears once after the first run; the shop shows a 72-hour "featured" countdown that never resets.

**Tech**
- Godot 4.7.2, GUT 9.7.1, GodotGooglePlayBilling 3.3.0, Poing AdMob plugin 5.1.0. Only the plugin's `ads` library is kept; mediation libraries were removed.
- Analytics is the thin local logger the spec allows; `Analytics.set_sink()` attaches a real backend later.
- UI strings are plain English passed through Godot's automatic translation, so a `.po` file can add Tamil/Hindi later without code changes. The language setting lists English only.
- Save file v1 with a v0→v1 migration path, SHA-256 checksum with a salt, temp-file-then-rename writes; a bad file is copied to `save.json.corrupt` and a fresh profile starts.
- The AdMob **App ID** is written into the manifest at export from a project setting; `tools/build_release.ps1` injects the real one for that build only. Debug builds and the repository only ever contain Google's test IDs.
- Two helper folders were added beyond spec §12.1: `scripts/meta/` and `scripts/services/`, to keep autoloads thin.
- `.gutconfig.json` makes the test command in `CLAUDE.md` include sub-folders.

**Readability pass (2026-11-15, after first play on the emulator: "objects look small")**
- Run camera zooms in 1.6× (`data/balance.json` → `run.camera_zoom`). Everything in the world is 60% larger on screen; spawn ring, despawn distance and on-screen targeting follow the zoomed view. Lower the number to see more of the map.
- Hero has a small health bar under the sprite (green → amber → red).
- Edge arrows point to off-screen bosses (red) and boss chests (gold). Not in the spec; added for usability.
- Village buildings and their labels are drawn 1.5× larger with a bigger tap area; a green arrow badge marks buildings you can afford, and a one-line tip explains it.
- HUD build icons are larger (104 px).
- Verified on desktop, and the zoomed run view and restyled hero were seen running on the Android emulator (25 FPS there, shortly after a cold boot).

**Hero restyle (2026-11-15, owner request for a superhero feel)**
- Heroes renamed and redrawn as original caped, masked guardians: `hero_muthu` is **Lampwarden, the Night Watch**; `hero_ammu` is **Kindlecrest, the Flame Keeper**. IDs, stats, weapons and product IDs are unchanged, so saves and Play products are unaffected. This departs from the hero names in spec 5.1.
- Deliberately not modelled on any existing comic character. A quick web search found no existing character with either name; do a proper trademark check before launch. "Dawnguard" (a Skyrim expansion) and the old title "the Lamplighter" (a DC character name) were avoided.

**Life potions (2026-11-15, owner request: "so the player will keep playing")**
- Not in the spec. Defeated creatures have a 1% chance to drop a life potion, 3% while the hero is at or below 40% HP; every boss drops one beside its chest. Walking over a potion heals 20% of max HP.
- A potion is not picked up at full health, so it is never wasted. At most 3 lie on the ground and drops are at least 20 s apart. When the hero is at or below 40% HP a green edge arrow points to off-screen potions.
- Free and in-run only: nothing to buy, no ad. All numbers are in `data/balance.json` → `potion`. Logic in `scripts/run/potions.gd`, tests in `tests/integration/test_potions.gd`.
- Drop chance was later raised to 3% and now falls with the hero's level (see the next section).

**Owner's second round (2026-11-16): easier start, potions to buy, more heroes, Hero Gifts, village art, icon, crowds**

All of this is outside the spec and was asked for by the owner.

- *Easier start.* Creatures deal 50% damage at 0:00, rising in a straight line to full damage at 5:00 (`run.early_damage_mult`, `run.early_ramp_seconds`). Spec enemy stats and wave rates are unchanged. Potion drop chance is 3% (9% at or below 40% HP), at least 15 s apart.
- *Fewer potions at higher levels.* Drop chance is multiplied by `1 - 0.04 * (level - 1)`, never below 0.2 (`potion.level_falloff`, `potion.min_level_mult`). "Level" is the hero's level in that night. Boss potions are not reduced.
- *Potions to buy.* Shop → Supplies: 1 for 250 coins, or 3 for 20 gems. A HUD button drinks one (30% of max HP), at most 2 per night. The run only counts what was drunk; the profile is charged when the results screen commits, like every other run reward.
- *Four more heroes* (`data/heroes/`), original names and art:

  | Hero | Band | How to get it |
  |---|---|---|
  | Galestride, the Swift Gale | Good | 10 hero pieces, or product `hero_gale` |
  | Banyanshield, the Unmoved | Better | 20 hero pieces, or product `hero_banyan` |
  | Voltmantle, the Storm Herald | Elite | product `hero_volt` only |
  | Mornhelm, the First Light | Elite | product `hero_morn` only |

  Mock prices (₹249 / 399 / 599 / 799) are placeholders; real prices come from Play. A web search found no existing character with any of the four names ("Solarch" was dropped: a mobile game has a "Solvarch"). That is not a trademark check.
- *Hero Gifts.* Reaching level 10, 20 and 30 in a night earns one gift each (`gifts.run_levels`), banked when the results screen commits and opened on the Heroes screen. A gift rolls on `hero_gift` in `data/chests.json`: 14% of gifts hold hero pieces (12% one piece, 2% two); the rest hold coins, timber, a potion or gems. Pieces go to a random collectable hero the player has not unlocked; with none left the gift pays 400 coins per piece. The "Drop odds" button shows the odds from the same table the roll uses, plus that rule. Gifts cannot be bought.
- *Village art.* Each building has its own shape (`scripts/ui/village_art.gd`), still with four stages at L1/L4/L7/L10. Name plates are drawn on top and kept inside the view.
- *Launcher icon.* Adaptive foreground and background plus a 192 px legacy icon in `assets/icons/`, rendered by `tools/gen_icons.gd` and set in both export presets. Not yet looked at on a device home screen.
- *Crowds.* Chasers stop at 80% of touching distance, back off half of every overlap with neighbours in the surrounding grid cells, and slow to 25% speed while another creature is in their way. Packs form a ring around the hero. Simulation cost is unchanged (about 0.3 ms per step).

Measured with `tools/balance_probe.tscn` (a simple bot: fetches a potion when under half health, otherwise walks to embers), no village, median of 6–8 nights:

| | Before this round | After |
|---|---|---|
| Lampwarden | 1:58 | 3:24 |
| Lampwarden, every building L4 | 3:20 | 3:54 |
| Galestride | – | 3:39 |
| Banyanshield | – | 4:47 |
| Voltmantle | – | 5:08 |
| Mornhelm | – | 7:03 |

The earlier note of "3–6 minutes with no village" came from a different bot and is not comparable. Kindlecrest's median is 1:39 with this bot; its spec stats were left alone. No human has played these numbers yet.

Things to decide before launch:
- Elite heroes are stronger and purchase-only. That is pay-for-power; some players and reviewers dislike it. Nothing here is PvP.
- Gifts are free and earned, with odds shown. If gifts are ever sold, the rules for paid random items apply.

**Run HUD tidy-up (2026-11-16, owner: "FPS, enemies, projectiles are showing; hard to find what matters")**
- The developer overlay (FPS, entity counts) is now off by default. It still exists in debug builds: Settings → Developer overlay. Release builds never show it.
- The level is written on the XP bar and the health numbers on the HP bar (with a heart icon). Kills and coins are icon chips under the HP bar. Seen on desktop and on the emulator.

**Creatures that change with the hero's level (2026-11-16, owner: "enemies upgrade and different enemies appear on every level update")**
- Not in the spec. The wave table still sets how many creatures spawn and when; the hero's level now decides who they are (`data/roster.json`, `scripts/run/roster.gd`).
- Every level from 2 to 36 introduces one creature that has not been seen before, announced on screen ("New creature: Dusk Gloom Moth"). Levels 2–6 bring five kinds; after that each level brings a stronger rank of a kind. 20% of ordinary spawns are drawn from the three most recent newcomers. Past level 36 the last three keep coming.
- Three new kinds with original art: Gloom Moth (fast, fragile), Shell Beetle (slow, tough), Hollow Shade (medium).
- Six ranks: plain, Dusk, Ember, Frost, Storm, Dread. A higher rank is tinted, larger, has more HP (up to x2.0), damage (up to x1.25) and speed, and gives proportionally more XP. Ordinary wave creatures move up one rank every 6 levels ("The creatures grow stronger"). This stacks with the per-minute scaling from remote config. Bosses are not ranked.
- Kills of ranked creatures count under the base kind, so missions are unaffected.
- Bot median with no village is 3:16 after tuning (3:24 before this change); with every building at L4 it is 3:18 (3:54 before), because a stronger hero levels faster and meets stronger creatures sooner. Late-night difficulty at high levels has only been run with an invulnerable bot.

**Test store on debug Android builds (2026-11-16, owner could not see prices on the emulator)**
- A debug build on Android that gets no prices from Play within 8 seconds switches to the built-in test store (the desktop mock): example prices from `data/products.json`, purchases succeed without payment. The shop shows a "Test store" notice. Release builds never do this; they only ever use Play.
- This bends the rule "real plugin on Android, mock on desktop" for debug builds only.

**Release identity and store assets (2026-11-16)**
- Owner chose package `com.jdtechlabs.kaaval`, developer name JD Techlabs, support email jdtechlabs.support@gmail.com. Set in both export presets, `data/app_config.json`, credits, privacy policy and store listing.
- Store graphics are in `docs/store/graphics/` (512 px icon, 1024×500 feature graphic, five 1080×1920 screenshots), made by `tools/store_graphics.ps1`. The folder has a `.gdignore` so they are not packed into the game.
- The legacy 192 px launcher icon now matches the adaptive icon (hero on the night background).
- Store listing text was brought up to date (six guardians, Hero Gifts, new creatures) and no longer claims everything can be earned by playing, because two heroes are purchase-only.
- Still needed from the owner before a release build: a hosted privacy policy URL, an upload keystore, and real AdMob IDs.

**Owner's third round (2026-11-21): how to play, a clear goal, more nights with their own bosses**

Owner feedback after playing on a phone: (1) add instructions at the start with a Skip option, (2) make the objective clear, (3) "every time I start it is level 0; can we have multiple levels with different bosses?". The "level 0" on the home screen was the village level, which only rises with building upgrades; the hero's level restarts at 1 every night, as in the genre. All of the below is outside the spec and was asked for by the owner.

- *How to play* (`scripts/ui/how_to_play.gd`). Five short pages (goal, moving, embers and upgrades, bosses, village and nights) with Skip and Next. It opens the first time Start Night is pressed (`how_to_play_seen` in the profile), also for existing saves, and any time from Settings → How to play. Boss times and the number of nights are read from the night data. The three in-run first-night hints are unchanged.
- *Clear goal.* Each night opens with a card for 4.5 s: "NIGHT 2 · PADDY FIELDS / Survive until dawn (15:00)". Under the timer a goal line always shows what to do: "Survive to dawn · Boss in 3:12", "Defeat the Thorn Queen! · Dawn in 9:40", and in the last 45 s "Hold on! Dawn in 0:30" (`objective.*` in `data/balance.json`). The results screen says which night was played and either "Night 2 unlocked: Paddy Fields!" or "Survive until dawn (15:00) to unlock Night 2."
- *Three nights* (`data/waves/*.tres`, `scripts/meta/night_logic.gd`). Each night is a WaveData with its own wave table, three bosses, map colours, edge sprite and props, plus difficulty and reward multipliers:

  | Night | Map | Bosses (5:00 / 10:00 / 14:30) | Creature HP / damage | Coins |
  |---|---|---|---|---|
  | 1 | Forest Edge | Thorn Queen 800 · Banyan Wraith 3,000 · Eclipse Beast 8,000 | ×1.0 / ×1.0 | ×1.0 |
  | 2 | Paddy Fields | Mire Serpent 1,100 · Straw Giant 4,000 · Storm Heron 10,500 | ×1.25 / ×1.15 | ×1.3 |
  | 3 | Old Fort | Iron Tusk 1,400 · Hollow Captain 5,200 · Night Colossus 13,500 | ×1.6 / ×1.3 | ×1.7 |

  Night 2 has more moths and a moth ring swarm; Night 3 brings shades and beetles early and a shade ring at 8:00. Spawn rates are 10–30% higher than Night 1.
- *Bosses.* Five new bosses reuse the existing attack scripts with their own numbers and summons (Mire Serpent and Iron Tusk charge like the Thorn Queen; Straw Giant and Hollow Captain raise ground spikes like the Banyan Wraith; Night Colossus darkens the screen like the Eclipse Beast, with more bullets). The Storm Heron has a new attack (`boss_storm_heron.gd`): bursts of a turning feather spiral (capped at 120 bullets on screen), a dive between bursts, more arms and speed below 30% HP. New art is original, made by `tools/gen_art.py` (six bosses, reeds, haystack, fort wall, rubble).
- *Unlocks.* Night 1 is open. Reaching dawn in a night unlocks the next one and selects it. Earlier nights stay playable. The home screen has a night picker above Start Night (arrows step through every night; locked ones show what unlocks them, and Start shows "LOCKED"). It shows the goal, the boss schedule and "Best 6:12" / "Cleared!". Progress is saved in the profile as `nights` and `selected_night`, recorded only when the results screen commits.
- `run.map_id` was removed from `data/balance.json`; the run plays the selected night.
- Tools: `balance_probe` takes `--night=<id>`; the screenshot tool takes `--night=<id>` and `--how-to-play`.

Bot medians (`balance_probe`, Lampwarden, 3–5 seeds): village L4: Forest Edge 3:18, Paddy Fields 1:49, Old Fort 1:38. Village L10: 4:12, 3:20, 3:09. **No bot reaches dawn, even with a full village.** The bot walks to embers and never dodges, so it says little about a person, but if players also cannot reach 15:00, Night 2 will stay locked for them. Decide after playing; easy levers are `run.early_damage_mult`, the remote-config scaling, or unlocking on the first boss instead of dawn.

**Owner's fourth round (2026-11-21): village ages — stage 1 of 4 (resources, ages, advancing)**

The owner asked for a progression through seven ages with new resources, age buildings, buying land, weapons that improve each age, and hero updates. Outside the spec; agreed plan in four stages, one at a time: (1) resources and ages, (2) buildings, production and land, (3) a weapon ladder per hero, (4) hero looks and bonuses, art, balance. Owner's choices: the main weapon steps up each age (tank, jet and missile become called-in strikes), the same 3 nights scaled by age, one "Rare Metals" currency, and heroes get a look per age, a resource bonus and their own weapon line. Age names must be similar to the owner's list but not the exact words (the exact list matches another game's ages).

Stage 1 (done):
- *Ages* (`data/ages/*.tres`, `scripts/resources/age_data.gd`, `scripts/meta/age_logic.gd`): Founders' Age → Age of Keeps → Blackpowder Age → Age of Learning → Age of Steam → Age of Steel → Age of Circuits. Each has the resources it pays, a building level cap (3, 4, 5, 6, 7, 8, 10), the building levels and resources needed to enter it, creature HP/damage multipliers and a resource multiplier.
- *Resources.* Food, stone, knowledge, oil and rare metals are new profile currencies (timber already existed). Food and timber from the start, stone from Keeps, knowledge from Learning, oil from Steam, rare metals from Steel. A run pays `minutes × per_minute + bosses × per_boss (+ dawn)` for each open kind, times the age's and the night's multipliers (`resources` in `data/balance.json`). Rare metals come only from bosses and dawn. Timber keeps its old boss + dawn formula. Rewards are shown on the results screen and granted at commit; the run records the age it was played in.
- *Advancing.* The home screen has an age bar (with "Ready to advance!" when possible) that opens the age panel: resources held, what the next age opens, each building and resource requirement with progress, and Advance. Advancing spends the cost and raises the building cap. Building upgrades above the cap show "Next age needed".
- *Harder ages.* Creature HP ×1.0–1.8 and damage ×1.0–1.2 across the ages, on top of each night's own multipliers.
- How to play has a sixth page about ages. Five new resource icons in `tools/gen_art.py`. The screenshot tool takes `--age-panel`; the demo profile is in the Age of Learning.

Decisions (stage 1):
- Old saves start in Founders' Age with no new resources. Buildings already above the cap keep their level; they just cannot be upgraded until the age allows it, and usually already meet the next age's requirements.
- Building upgrades still cost coins and timber; food, stone and the rest are spent only on advancing for now. Stage 2 adds them to building and land costs.
- Coins do not scale with age (building coin costs do not either), only resources do.
- The night's existing `coin_mult` (×1.0 / ×1.3 / ×1.7) also multiplies resources.
- All numbers are first guesses; tune them after playing.

## Known issues

- Later ages are harder (creature HP up to ×1.8) but nothing makes the hero stronger per age until stage 3 (weapon ladder). Until then, the building cap rising is the only counterweight.
- With bots surviving 3–4 minutes, a run in Founders' Age pays about 30 food; Age of Keeps needs 250 food and 30 timber. Expect several nights per age early on.

- `scripts/run/run_manager.gd` is about 455 lines, over the 300-line preference.
- Package name is `com.jdtechlabs.kaaval`, developer JD Techlabs, support email set (2026-11-16). `data/app_config.json` still has a placeholder privacy policy URL: the policy must be hosted first.
- The first frame after launch on Android compiles shaders (a one-time "Failed to load cached shader, recompiling" warning in logcat).
- Thrown-weapon and hit sounds are throttled to one per 45 ms; no separate volume buses.
- Target API level is Godot's default. Play may require a newer one at upload time.
- GUT reports leaked instances at exit from static data caches; harmless.
- Once, during a scripted screenshot capture of Old Fort skipped to 5:10, Godot printed "Parent node is busy setting up children, add_child() failed". It did not happen again in four repeats, never in tests, and the screenshot was correct. Watch for it.

## Changes made outside the project folder

- Godot export templates 4.7.2 (Android files only) installed to `%APPDATA%\Godot\export_templates\4.7.2.stable`.
- `%APPDATA%\Godot\editor_settings-4.7.tres`: Java SDK path set to `C:/Program Files/Java/jdk-20`, debug keystore set to `~/.android/debug.keystore`. Backup beside it as `.bak`.
- Gradle 8.11.1 and Android dependencies downloaded into `~/.gradle`.

## Not done (post-launch list in the spec)

Season pass, more skins, second map, cloud save, server-side receipt validation, Tamil/Hindi text, iOS.

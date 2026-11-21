# CLAUDE.md — Kavaryn: Guardians of Dawn

Godot 4 roguelite survivor game for Android. Full spec: `docs/GAME_SPEC.md` (source of truth). Progress log: `docs/PROGRESS.md`.

## Working rules
- Work **one phase at a time** (spec §17). Do not start the next phase until asked.
- Never add features, screens, or products not in the spec. If something is ambiguous, ask or choose the simplest option and note it in PROGRESS.md under "Decisions".
- At the end of every phase: update `docs/PROGRESS.md` (done, decisions, known issues, how to test), run tests, and stop.

## Tech
- Godot 4.x latest stable, **Compatibility renderer**, portrait 1080×1920.
- GDScript with **static typing everywhere** (`var hp: int`, typed function signatures).
- Tests: GUT. Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- Import/validate project headlessly: `godot --headless --path . --import`

## Architecture rules
- **Data-driven:** every gameplay/economy number lives in `data/` (`.tres` Resources or JSON) or remote config. No magic numbers in gameplay scripts.
- Custom Resource classes in `scripts/resources/` with `class_name`.
- Autoload singletons live in `autoload/` (see spec §12.1). Keep them thin.
- `BillingService` and `AdsService`: identical API, real plugin on Android, **mock on desktop/editor**. Detect with `OS.has_feature("android")`.
- Enemies: **no physics bodies**. Manual movement + spatial hash grid. Pool enemies, projectiles, embers, damage numbers.
- Systems talk via signals, not deep node paths.
- Run state never mutates `GameState` until the results screen commits rewards.
- Keep `.tscn` files simple and text-editable; build complex/dynamic UI in code when easier.

## Code style
- snake_case files/functions/vars, PascalCase class_names, UPPER_SNAKE constants.
- One responsibility per script. Prefer < 300 lines per file.
- Pure logic (economy, rolls, formulas) in testable functions with GUT tests.
- No `get_node("../../..")` chains; use exported NodePaths or signals.

## Hard constraints
- **Ads:** only Google's official **test ad unit IDs** in debug builds. Real IDs come from a release-only config file that is git-ignored.
- **Billing:** consume consumables after granting; acknowledge non-consumables; restore purchases on launch; handle pending/cancelled/failed.
- **Random chests:** odds must be displayed in-game, rendered from the same data used to roll.
- **Content:** no deities, temples, religious symbols, caste references, or copied names/art/UI from existing games.
- **Assets:** only CC0 or properly licensed assets. Log every asset in `CREDITS.md` with source + licence.
- Never commit keystores, passwords, or real ad/billing IDs. Add them to `.gitignore`.

## Performance targets
60 FPS with 300 enemies on a mid-range Android phone. Use atlases, pooling, MultiMesh for embers. Keep a debug overlay (FPS, entity counts) in debug builds.

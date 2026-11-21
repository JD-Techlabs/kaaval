extends "res://tests/base_test.gd"
## Real runs on the later nights: the run uses the chosen night's settings,
## and each new boss fights without errors and uses its attacks.

const STEP: float = 0.05


func _new_run(night: String) -> RunManager:
	GameState.p["hints_done"] = true
	GameState.p["nights"] = {"forest_edge": {"won": true}, "paddy_fields": {"won": true}}
	GameState.p["selected_night"] = night
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	run.rng.seed = 99
	run.player.invulnerable = true
	return run


func _advance(run: RunManager, seconds: float) -> void:
	var left: float = seconds
	while left > 0.0 and run.mode != RunManager.Mode.ENDED:
		match run.mode:
			RunManager.Mode.CHOOSING:
				run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
			RunManager.Mode.CHEST:
				run.close_chest()
			_:
				run.input_dir = Vector2.from_angle(run.state.time * 0.5)
				run.advance(STEP)
				left -= STEP


func test_run_uses_the_selected_night() -> void:
	var run: RunManager = _new_run("old_fort")
	assert_eq(run.wave.id, "old_fort")
	assert_eq(run.state.night_id, "old_fort")
	assert_almost_eq(run.hp_scale(), 1.6, 0.001, "night HP multiplier at 0:00")
	assert_almost_eq(run.coin_mult(), run.player.stats.coin_mult * 1.7, 0.001)
	_advance(run, 30.0)
	var summary: Dictionary = run.state.summary()
	assert_eq(str(summary["night"]), "old_fort")
	assert_gt(run.state.kills, 0, "creatures spawn and die on the new map")


func test_a_locked_night_is_never_played() -> void:
	GameState.p["selected_night"] = "old_fort"
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	assert_eq(run.wave.id, "forest_edge", "falls back to an unlocked night")


func _fight(run: RunManager, boss_id: String, seconds: float) -> Dictionary:
	var boss: Enemy = run.enemies.spawn_boss(GameData.boss(boss_id), run.player.position + Vector2(400.0, 0.0))
	var peak_bullets: int = 0
	var left: float = seconds
	while left > 0.0 and boss.alive:
		run.advance(STEP)
		left -= STEP
		peak_bullets = maxi(peak_bullets, run.hazards.bullet_count())
	return {"boss": boss, "peak_bullets": peak_bullets}


func test_storm_heron_sprays_a_capped_spiral_and_dives() -> void:
	var run: RunManager = _new_run("paddy_fields")
	var result: Dictionary = _fight(run, "b_storm_heron", 12.0)
	var boss: Boss = result["boss"]
	assert_true(boss.alive)
	assert_gt(int(result["peak_bullets"]), 10, "fires feathers")
	assert_true(int(result["peak_bullets"]) <= int(boss.param("max_bullets")), "bullet cap respected")
	boss.hp = boss.max_hp * 0.2
	var calm_speed: float = boss.speed
	_fight_existing(run, boss, 1.0)
	assert_gt(boss.speed, calm_speed, "enrages below 30%")


func _fight_existing(run: RunManager, boss: Enemy, seconds: float) -> void:
	var left: float = seconds
	while left > 0.0 and boss.alive:
		run.advance(STEP)
		left -= STEP


func test_every_new_boss_fights_and_can_be_beaten() -> void:
	for id: String in ["b_mire_serpent", "b_straw_giant", "b_iron_tusk", "b_hollow_captain", "b_night_colossus"]:
		var run: RunManager = _new_run("old_fort")
		var result: Dictionary = _fight(run, id, 10.0)
		var boss: Enemy = result["boss"]
		assert_true(boss.alive, "%s survives 10 s of a level-1 hero" % id)
		run.enemies.kill(boss)
		assert_eq(run.state.bosses_killed, [id] as Array[String], "%s counts as defeated" % id)
		assert_eq(run.state.boss_timber, GameData.boss(id).timber)

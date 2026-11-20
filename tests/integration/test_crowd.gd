extends "res://tests/base_test.gd"
## Crowd spreading and the soft start to a night.

const STEP: float = 0.05


func _new_run() -> RunManager:
	GameState.p["selected_hero"] = "hero_muthu"
	GameState.p["hints_done"] = true
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	run.rng.seed = 31
	return run


func _stacked_share(run: RunManager) -> float:
	var active: Array[Enemy] = run.enemies.active
	var stacked: int = 0
	for a: Enemy in active:
		for b: Enemy in active:
			if a != b and a.position.distance_to(b.position) < (a.radius + b.radius) * 0.5:
				stacked += 1
				break
	return float(stacked) / float(maxi(active.size(), 1))


func test_a_pack_spawned_on_one_spot_fans_out() -> void:
	var run: RunManager = _new_run()
	run.player.invulnerable = true
	var spot: Vector2 = run.player.position + Vector2(260.0, 0.0)
	for i: int in 40:
		run.enemies.spawn(GameData.enemy("e_wisp"), spot + Vector2(float(i % 3), float(i % 2)))
	assert_almost_eq(_stacked_share(run), 1.0, 0.001, "starts fully stacked")
	for i: int in 80:
		run.enemies.step(STEP)
	assert_eq(run.enemies.count(), 40)
	assert_true(_stacked_share(run) < 0.15, "stacked share after 4 s: %.2f" % _stacked_share(run))


func test_creatures_still_reach_the_hero_while_spreading() -> void:
	var run: RunManager = _new_run()
	for i: int in 30:
		run.enemies.spawn(GameData.enemy("e_wisp"), run.player.position + Vector2(220.0, float(i)))
	var hp: float = run.player.hp
	for i: int in 120:
		run.enemies.step(STEP)
		run.player.step(STEP, Vector2.ZERO, Rect2(Vector2.ZERO, run.wave.map_size))
	assert_true(run.player.hp < hp, "the crowd still lands hits")


func test_night_starts_soft_and_reaches_full_strength() -> void:
	var start: float = GameData.num("run", "early_damage_mult")
	var ramp: float = GameData.num("run", "early_ramp_seconds")
	assert_true(start > 0.0 and start < 1.0)
	assert_almost_eq(RunManager.early_damage_mult(0.0), start, 0.0001)
	assert_almost_eq(RunManager.early_damage_mult(ramp * 0.5), (start + 1.0) * 0.5, 0.0001)
	assert_almost_eq(RunManager.early_damage_mult(ramp), 1.0, 0.0001)
	assert_almost_eq(RunManager.early_damage_mult(ramp * 3.0), 1.0, 0.0001, "never above full strength")
	var run: RunManager = _new_run()
	var early: float = run.dmg_scale()
	run.state.time = ramp
	assert_true(run.dmg_scale() > early * 1.5, "later creatures hit harder")

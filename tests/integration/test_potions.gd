extends "res://tests/base_test.gd"
## Life potions: drop odds, pickup heal, never wasted at full health, ground
## cap, fewer drops at higher levels, and drinking bought potions.


func _new_run() -> RunManager:
	GameState.p["selected_hero"] = "hero_muthu"
	GameState.p["hints_done"] = true
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	run.rng.seed = 77
	return run


func test_drop_chance_rises_when_badly_hurt() -> void:
	var healthy: float = Potions.drop_chance(1.0)
	var hurt: float = Potions.drop_chance(0.2)
	assert_almost_eq(healthy, GameData.num("potion", "drop_chance"), 0.0001)
	assert_almost_eq(hurt, healthy * GameData.num("potion", "low_hp_mult"), 0.0001)
	assert_true(hurt > healthy)


func test_higher_levels_find_fewer_potions() -> void:
	var early: float = Potions.drop_chance(1.0, 1)
	var mid: float = Potions.drop_chance(1.0, 10)
	var late: float = Potions.drop_chance(1.0, 40)
	assert_true(early > mid and mid > late, "%f > %f > %f" % [early, mid, late])
	assert_almost_eq(late, early * GameData.num("potion", "min_level_mult"), 0.0001, "never drops to nothing")
	assert_almost_eq(Potions.drop_chance(1.0, 99), late, 0.0001)


func test_bought_potions_are_drunk_in_the_run_and_charged_at_commit() -> void:
	GameState.grant({"potions": 5})
	var run: RunManager = _new_run()
	var player: Player = run.player
	var limit: int = int(GameData.num("potion", "max_uses_per_run"))
	assert_eq(run.potions.carried_left(), limit, "only the per-night limit is carried")
	assert_false(run.potions.drink(), "not at full health")
	player.hp = 5.0
	assert_true(run.potions.drink())
	assert_almost_eq(player.hp, 5.0 + player.stats.max_hp * GameData.num("potion", "carry_heal_pct"), 0.01)
	for i: int in limit + 2:
		player.hp = 5.0
		run.potions.drink()
	assert_eq(run.state.potions_used, limit)
	assert_eq(run.potions.carried_left(), 0)
	assert_eq(GameState.amount("potions"), 5, "the run does not touch the profile")
	RunCommit.commit(run.state.summary().merged({"coin_mult": 1.0}), 0)
	assert_eq(GameState.amount("potions"), 5 - limit)


func test_potion_heals_a_share_of_max_hp() -> void:
	var run: RunManager = _new_run()
	var player: Player = run.player
	player.hp = 10.0
	run.potions.drop(player.position + Vector2(20.0, 0.0))
	run.potions.step(0.05)
	assert_eq(run.potions.count(), 0, "picked up")
	assert_almost_eq(player.hp, 10.0 + player.stats.max_hp * GameData.num("potion", "heal_pct"), 0.01)


func test_potion_never_heals_above_max() -> void:
	var run: RunManager = _new_run()
	var player: Player = run.player
	player.hp = player.stats.max_hp - 1.0
	run.potions.drop(player.position)
	run.potions.step(0.05)
	assert_almost_eq(player.hp, player.stats.max_hp, 0.01)


func test_potion_is_left_on_the_ground_at_full_health() -> void:
	var run: RunManager = _new_run()
	run.potions.drop(run.player.position)
	run.potions.step(0.05)
	assert_eq(run.potions.count(), 1, "not wasted")
	run.player.hp -= 30.0
	run.potions.step(0.05)
	assert_eq(run.potions.count(), 0, "picked up once hurt")


func test_potion_out_of_reach_is_not_collected() -> void:
	var run: RunManager = _new_run()
	run.player.hp = 10.0
	run.potions.drop(run.player.position + Vector2(GameData.num("potion", "pickup_radius") + 40.0, 0.0))
	run.potions.step(0.05)
	assert_eq(run.potions.count(), 1)
	assert_almost_eq(run.player.hp, 10.0, 0.01)


func test_drops_are_spaced_out_and_capped() -> void:
	var run: RunManager = _new_run()
	run.player.hp = 1.0
	var far: Vector2 = run.player.position + Vector2(900.0, 0.0)
	for i: int in 5000:
		run.potions.on_enemy_died(far)
	assert_eq(run.potions.count(), 1, "one drop, then the gap blocks more")
	var cap: int = int(GameData.num("potion", "max_on_ground"))
	for round_index: int in cap + 3:
		run.potions.step(GameData.num("potion", "min_gap_seconds") + 1.0)
		for i: int in 5000:
			run.potions.on_enemy_died(far)
	assert_eq(run.potions.count(), cap, "never more than the cap on the ground")

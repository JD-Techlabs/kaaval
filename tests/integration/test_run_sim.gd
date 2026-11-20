extends "res://tests/base_test.gd"
## Drives real runs headlessly through RunManager.advance(): a full 15-minute
## night to dawn, every weapon and evolution, revive, and the "run never
## touches the profile" rule.

const STEP: float = 0.05


func _new_run(hero_id: String = "hero_muthu") -> RunManager:
	GameState.p["selected_hero"] = hero_id
	GameState.p["hints_done"] = true
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	run.rng.seed = 1234
	return run


## Steps the run, auto-picking cards and chests, moving in a slow circle.
func _advance(run: RunManager, seconds: float) -> void:
	var left: float = seconds
	while left > 0.0 and run.mode != RunManager.Mode.ENDED and run.mode != RunManager.Mode.REVIVE:
		match run.mode:
			RunManager.Mode.CHOOSING:
				run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
			RunManager.Mode.CHEST:
				run.close_chest()
			_:
				run.input_dir = _bot_direction(run)
				run.advance(STEP)
				left -= STEP


## A plain player: walk to the nearest ember, otherwise drift in a circle.
func _bot_direction(run: RunManager) -> Vector2:
	var ember: Vector2 = run.embers.nearest(run.player.position, 700.0)
	if ember != Vector2.INF and ember.distance_to(run.player.position) > 20.0:
		return (ember - run.player.position).normalized()
	return Vector2.from_angle(run.state.time * 0.4)


func test_full_night_reaches_dawn() -> void:
	var run: RunManager = _new_run()
	var before: String = JSON.stringify(GameState.p)
	run.player.invulnerable = true
	var banners: Array[String] = []
	var peak: Array[int] = [0]
	var ended: Array[Dictionary] = []
	run.banner_requested.connect(func(text: String) -> void: banners.append(text))
	run.run_ended.connect(func(summary: Dictionary) -> void: ended.append(summary))
	var bosses_seen: Array[String] = []
	run.boss_changed.connect(func(boss: Enemy) -> void:
		if boss != null:
			bosses_seen.append(boss.data.id))
	var levels: Dictionary = {}
	while run.mode != RunManager.Mode.ENDED and run.state.time < 905.0:
		_advance(run, 5.0)
		peak[0] = maxi(peak[0], run.enemies.count())
		@warning_ignore("integer_division")
		levels[int(run.state.time) / 60] = run.state.level

	assert_eq(run.mode, RunManager.Mode.ENDED)
	assert_true(run.state.victory, "survived to 15:00 = dawn")
	assert_eq(ended.size(), 1, "run_ended fires exactly once")
	assert_eq(banners.size(), 3, "three boss warnings")
	assert_eq(bosses_seen, ["b_crawler_queen", "b_banyan_wraith", "b_eclipse_beast"] as Array[String])
	assert_true(run.state.kills > 500, "kills: %d" % run.state.kills)
	assert_true(run.state.level >= 15, "level: %d" % run.state.level)
	assert_true(peak[0] <= 300, "enemy cap respected (peak %d)" % peak[0])
	assert_true(run.projectiles.count() <= ProjectilePool.MAX_PROJECTILES)
	assert_true(run.embers.count() <= 420, "embers merge above 400 (now %d)" % run.embers.count())
	assert_eq(JSON.stringify(GameState.p), before, "a run must not change the profile before results commit")
	gut.p("dawn: kills=%d level=%d bosses=%s peak_enemies=%d weapons=%s evolved=%s" % [run.state.kills, run.state.level,
		str(run.state.bosses_killed), peak[0], str(run.state.weapons), str(run.state.evolved)])
	gut.p("level by minute: %s" % str(levels))
	var summary: Dictionary = ended[0]
	assert_true(RunCommit.coins_for(summary) > 200)
	assert_eq(RunCommit.timber_for(summary), int(summary["boss_timber"]) + 10)


func test_every_weapon_deals_damage() -> void:
	for weapon: WeaponData in GameData.weapons():
		var run: RunManager = _new_run()
		run.player.invulnerable = true
		run.player.facing = Vector2.RIGHT
		run.apply_card({"kind": "weapon", "id": weapon.id, "level": weapon.max_level})
		for id: String in run.weapon_nodes.keys():
			if id != weapon.id:
				(run.weapon_nodes[id] as Node).queue_free()
				run.weapon_nodes.erase(id)
		var crawler: EnemyData = GameData.enemy("e_crawler")
		var targets: Array[Enemy] = []
		for i: int in 6:
			targets.append(run.enemies.spawn(crawler, run.player.position + Vector2(90.0 + i * 12.0, (i - 3) * 14.0)))
		var total_before: float = 0.0
		for enemy: Enemy in targets:
			total_before += enemy.hp
		for i: int in 120:
			run.input_dir = Vector2.ZERO
			if run.mode == RunManager.Mode.CHOOSING:
				run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
			run.advance(STEP)
		var total_after: float = 0.0
		for enemy: Enemy in targets:
			total_after += enemy.hp
		assert_true(run.state.kills > 0 or total_after < total_before, "%s should damage nearby creatures" % weapon.id)
		run.free()


func test_every_evolution_is_obtainable_from_a_boss_chest() -> void:
	for evo: EvolutionData in GameData.evolutions():
		var run: RunManager = _new_run()
		run.player.invulnerable = true
		var weapon: WeaponData = GameData.weapon(evo.weapon_id)
		run.apply_card({"kind": "weapon", "id": weapon.id, "level": weapon.max_level})
		run.apply_card({"kind": "passive", "id": evo.passive_id, "level": 1})
		var opened: Array = []
		run.chest_opened.connect(func(lines: Array[Dictionary]) -> void: opened.append(lines))
		run.open_chest()
		assert_eq(run.mode, RunManager.Mode.CHEST)
		assert_eq(str(run.state.evolved.get(weapon.id, "")), evo.id)
		assert_eq(str((opened[0] as Array)[0]["tag"]), "EVOLVE")
		run.close_chest()
		var crawler: EnemyData = GameData.enemy("e_crawler")
		var target: Enemy = run.enemies.spawn(crawler, run.player.position + Vector2(100.0, 0.0))
		for i: int in 100:
			run.advance(STEP)
		assert_true(run.state.kills > 0 or target.hp < target.max_hp, "%s should hit" % evo.id)
		run.free()


func test_boss_chest_without_evolution_gives_upgrades_and_coins() -> void:
	var run: RunManager = _new_run()
	var lines: Array[Dictionary] = BossChest.open(run)
	assert_true(lines.size() >= 2 and lines.size() <= 4, "1-3 upgrades + coins, got %d" % lines.size())
	assert_eq(run.state.bonus_coins, 120)
	assert_true(run.state.weapons.size() + run.state.passives.size() >= 2 or int(run.state.weapons["w_sling"]) > 1)


func test_contact_damage_respects_iframes() -> void:
	var run: RunManager = _new_run()
	var wisp: EnemyData = GameData.enemy("e_wisp")
	for i: int in 5:
		run.enemies.spawn(wisp, run.player.position + Vector2(5.0, i))
	for weapon: Node in run.weapon_nodes.values():
		weapon.queue_free()
	run.weapon_nodes.clear()
	var start_hp: float = run.player.hp
	var hit: float = wisp.contact_damage * RunManager.early_damage_mult(0.0)
	run.advance(0.016)
	assert_almost_eq(start_hp - run.player.hp, hit, 0.2, "one hit, not five, in the same frame")
	for i: int in 20:
		run.advance(0.02)
	assert_almost_eq(start_hp - run.player.hp, hit, 0.2, "still inside the 0.5 s i-frames")
	for i: int in 10:
		run.advance(0.02)
	assert_true(start_hp - run.player.hp >= hit * 2.0 - 0.1, "hit again after i-frames")


func test_golem_splits_and_thief_drops_bonus_coins() -> void:
	var run: RunManager = _new_run()
	var golem: Enemy = run.enemies.spawn(GameData.enemy("e_golem"), run.player.position + Vector2(600.0, 0.0))
	var count_before: int = run.enemies.count()
	run.enemies.damage(golem, 9999.0)
	assert_eq(run.enemies.count(), count_before + 2, "two mud pups")
	var thief: Enemy = run.enemies.spawn(GameData.enemy("e_thief"), run.player.position + Vector2(600.0, 0.0))
	thief.carried_xp = 20.0
	var embers_before: int = run.embers.count()
	run.enemies.damage(thief, 9999.0)
	assert_eq(run.state.bonus_coins, 15)
	assert_eq(run.embers.count(), embers_before + 1, "stolen embers come back")
	assert_eq(run.state.kills, 2)


func test_death_without_lamp_tower_ends_the_run() -> void:
	var run: RunManager = _new_run()
	assert_false(run.can_revive())
	run.player.take_damage(99999.0)
	run.advance(STEP)
	assert_eq(run.mode, RunManager.Mode.ENDED)
	assert_false(run.state.victory)


func test_revive_once_per_run_with_lamp_tower() -> void:
	(GameState.p["buildings"] as Dictionary)["bld_lamp_tower"] = 1
	var run: RunManager = _new_run()
	watch_signals(run)
	run.player.take_damage(99999.0)
	run.advance(STEP)
	assert_eq(run.mode, RunManager.Mode.REVIVE)
	assert_signal_emitted(run, "revive_offered")
	run.revive()
	assert_eq(run.mode, RunManager.Mode.PLAYING)
	assert_almost_eq(run.player.hp, run.player.stats.max_hp * 0.5, 0.01, "revive with 50% HP")
	run.player.iframes = 0.0
	run.player.take_damage(99999.0)
	run.advance(STEP)
	assert_eq(run.mode, RunManager.Mode.ENDED, "only one revive per run")


func test_pause_stops_time() -> void:
	var run: RunManager = _new_run()
	run.set_process(true)
	run.set_paused(true)
	var time: float = run.state.time
	run._process(0.5)
	assert_eq(run.state.time, time)
	run.set_paused(false)
	run._process(0.5)
	assert_true(run.state.time > time)


func test_enemy_scaling_uses_remote_config() -> void:
	var run: RunManager = _new_run()
	run.state.time = 600.0
	assert_almost_eq(run.hp_scale(), 2.2, 0.001)
	assert_almost_eq(run.dmg_scale(), 1.5, 0.001)
	RemoteConfig.apply_overrides({"enemy_hp_scale_per_min": 0.5})
	assert_almost_eq(run.hp_scale(), 6.0, 0.001)
	var wisp: Enemy = run.enemies.spawn(GameData.enemy("e_wisp"), Vector2(100, 100))
	assert_almost_eq(wisp.max_hp, 48.0, 0.01)


func test_library_rerolls_are_added() -> void:
	(GameState.p["buildings"] as Dictionary)["bld_library"] = 6
	var run: RunManager = _new_run()
	assert_eq(run.state.rerolls_left, 3, "1 free + L3 + L6")


func test_ammu_starts_with_lamp_orbit() -> void:
	GameState.unlock_hero("hero_ammu")
	var run: RunManager = _new_run("hero_ammu")
	assert_true(run.state.weapons.has("w_lamp_orbit"))
	assert_almost_eq(run.player.stats.max_hp, 85.0, 0.01)

extends "res://tests/base_test.gd"
## Level-based creature roster: a new creature at every level, ranks that
## upgrade the ordinary wave, and stronger stats on ranked creatures.


func _new_run() -> RunManager:
	GameState.p["selected_hero"] = "hero_muthu"
	GameState.p["hints_done"] = true
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	run.rng.seed = 9
	return run


func test_every_level_brings_a_different_creature() -> void:
	assert_true(Roster.debut(1).is_empty(), "level 1 starts with the plain wave")
	var seen: Dictionary = {}
	var last_level: int = 1 + Roster.debut_count()
	assert_true(last_level >= 30, "debuts cover levels 2..%d" % last_level)
	for level: int in range(2, last_level + 1):
		var entry: Dictionary = Roster.debut(level)
		assert_false(entry.is_empty(), "level %d" % level)
		var key: String = "%s:%d" % [str(entry["enemy"]), int(entry["rank"])]
		assert_false(seen.has(key), "level %d repeats %s" % [level, key])
		seen[key] = true
		var data: EnemyData = GameData.enemy(str(entry["enemy"]))
		assert_not_null(data, key)
		assert_true(ResourceLoader.exists(data.texture), key)
		assert_true(int(entry["rank"]) < Roster.rank_count(), key)
		assert_true(Roster.announcement(level).contains(Roster.display_name(data.id, int(entry["rank"]))))


func test_ranks_get_stronger_and_ordinary_creatures_upgrade_with_level() -> void:
	for index: int in range(1, Roster.rank_count()):
		var lower: Dictionary = Roster.rank(index - 1)
		var higher: Dictionary = Roster.rank(index)
		for stat: String in ["hp", "damage", "speed", "scale", "xp"]:
			assert_true(float(higher[stat]) > float(lower[stat]), "rank %d %s" % [index, stat])
	var every: int = int(GameData.json("roster")["rank_every_levels"])
	assert_eq(Roster.base_rank(1), 0)
	assert_eq(Roster.base_rank(every), 0)
	assert_eq(Roster.base_rank(every + 1), 1)
	assert_eq(Roster.base_rank(999), Roster.rank_count() - 1, "capped at the top rank")
	assert_true(Roster.announcement(every + 1).contains("grow stronger"))
	assert_eq(Roster.announcement(1), "")


func test_pick_mixes_newcomers_into_the_wave() -> void:
	assert_eq(Roster.pick(1, "e_wisp", 0.0, 0.0), {"enemy": "e_wisp", "rank": 0}, "nothing new at level 1")
	var share: float = float(GameData.json("roster")["newcomer_share"])
	var newest: Dictionary = Roster.debut(5)
	assert_eq(Roster.pick(5, "e_wisp", share - 0.01, 0.999), newest, "newest debut")
	assert_eq(Roster.pick(5, "e_wisp", share + 0.01, 0.999), {"enemy": "e_wisp", "rank": Roster.base_rank(5)})
	var window: int = int(GameData.json("roster")["newcomer_window"])
	assert_eq(Roster.newcomers(20).size(), window)
	assert_eq(Roster.newcomers(20)[window - 1], Roster.debut(20))
	assert_eq(Roster.newcomers(2).size(), 1)
	assert_eq(Roster.newcomers(999).size(), window, "past the last debut the final ones keep coming")


func test_ranked_creature_is_tougher_bigger_and_worth_more() -> void:
	var run: RunManager = _new_run()
	var wisp: EnemyData = GameData.enemy("e_wisp")
	var plain: Enemy = run.enemies.spawn(wisp, Vector2(100.0, 100.0), 0)
	var ranked: Enemy = run.enemies.spawn(wisp, Vector2(900.0, 100.0), 3)
	var rank: Dictionary = Roster.rank(3)
	assert_almost_eq(ranked.max_hp, plain.max_hp * float(rank["hp"]), 0.01)
	assert_almost_eq(ranked.contact_damage, plain.contact_damage * float(rank["damage"]), 0.01)
	assert_almost_eq(ranked.radius, plain.radius * float(rank["scale"]), 0.01)
	assert_true(ranked.speed > plain.speed)
	assert_ne(ranked.modulate, plain.modulate, "tinted so the rank is visible")
	var xp: Array[float] = []
	run.enemies.enemy_died.connect(func(data: EnemyData, _pos: Vector2, extra: float) -> void: xp.append(data.xp + extra))
	run.enemies.kill(plain)
	run.enemies.kill(ranked)
	assert_almost_eq(xp[0], wisp.xp, 0.001)
	assert_almost_eq(xp[1], wisp.xp * float(rank["xp"]), 0.001)


func test_pooled_creature_loses_its_old_rank() -> void:
	var run: RunManager = _new_run()
	var wisp: EnemyData = GameData.enemy("e_wisp")
	var first: Enemy = run.enemies.spawn(wisp, Vector2(100.0, 100.0), 5)
	run.enemies.despawn(first)
	run.enemies.step(0.05)
	var again: Enemy = run.enemies.spawn(wisp, Vector2(100.0, 100.0), 0)
	assert_eq(again, first, "same pooled node")
	assert_eq(again.scale, Vector2.ONE)
	assert_eq(again.modulate, Color.WHITE)
	assert_almost_eq(again.xp_mult, 1.0, 0.001)


func test_levelling_up_changes_who_spawns() -> void:
	var run: RunManager = _new_run()
	run.player.invulnerable = true
	var every: int = int(GameData.json("roster")["rank_every_levels"])
	run.state.level = every + 2
	var notices: Array[String] = []
	run.notice_requested.connect(func(text: String) -> void: notices.append(text))
	var kinds: Dictionary = {}
	var ranks: Dictionary = {}
	run.embers.add(run.player.position, 400.0)
	for i: int in 600:
		if run.mode == RunManager.Mode.CHOOSING:
			run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
		run.advance(0.05)
		for enemy: Enemy in run.enemies.active:
			kinds[enemy.data.id] = true
			ranks[enemy.modulate] = true
	assert_true(run.enemies.base_rank >= 1, "ordinary creatures were upgraded")
	assert_true(kinds.size() >= 3, "newcomers joined the wisps: %s" % str(kinds.keys()))
	assert_false(ranks.has(Color.WHITE), "no plain-rank creatures at this level")
	assert_false(notices.is_empty(), "the player is told what is new")

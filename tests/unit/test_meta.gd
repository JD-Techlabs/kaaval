extends "res://tests/base_test.gd"
## Spec §8: village upgrades + wall-clock timers, chests + odds, daily systems.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _rich() -> void:
	GameState.grant({"coins": 1_000_000, "timber": 10_000, "gems": 10_000})


# --- village --------------------------------------------------------------

func test_first_three_levels_are_instant() -> void:
	_rich()
	for level: int in [1, 2, 3]:
		assert_true(VillageLogic.start("bld_blacksmith"))
		assert_eq(GameState.building_level("bld_blacksmith"), level)
	assert_eq(VillageLogic.jobs().size(), 0)
	assert_eq(GameState.amount("coins"), 1_000_000 - 120 - 186 - 288)


func test_level_4_takes_five_minutes_of_wall_clock() -> void:
	_rich()
	(GameState.p["buildings"] as Dictionary)["bld_healer"] = 3
	assert_true(VillageLogic.start("bld_healer"))
	assert_eq(GameState.building_level("bld_healer"), 3, "not finished yet")
	assert_almost_eq(VillageLogic.remaining(VillageLogic.job_for("bld_healer")), 300.0, 0.01)
	GameState.time_override = NOW + 299.0
	assert_eq(VillageLogic.complete_due().size(), 0)
	GameState.time_override = NOW + 301.0
	assert_eq(VillageLogic.complete_due(), ["bld_healer"] as Array[String])
	assert_eq(GameState.building_level("bld_healer"), 4)


func test_timer_progresses_while_the_app_is_closed() -> void:
	_rich()
	(GameState.p["buildings"] as Dictionary)["bld_library"] = 5
	VillageLogic.start("bld_library")
	# App is killed: only the save file survives. Reopen 3 hours later.
	GameState.reset_profile()
	GameState.load_profile()
	assert_eq(GameState.building_level("bld_library"), 5)
	assert_eq(VillageLogic.jobs().size(), 1, "job survived the restart")
	GameState.time_override = NOW + 3.0 * 3600.0
	VillageLogic.complete_due()
	assert_eq(GameState.building_level("bld_library"), 6)


func test_only_one_builder_unless_second_is_owned() -> void:
	_rich()
	(GameState.p["buildings"] as Dictionary)["bld_healer"] = 3
	(GameState.p["buildings"] as Dictionary)["bld_granary"] = 3
	assert_true(VillageLogic.start("bld_healer"))
	assert_eq(VillageLogic.blocker("bld_granary"), "Builder busy")
	assert_true(VillageLogic.start("bld_blacksmith"), "instant upgrades do not need a builder")
	GameState.add_entitlement("builder_2")
	assert_true(VillageLogic.start("bld_granary"))


func test_upgrade_needs_coins_and_timber() -> void:
	assert_eq(VillageLogic.blocker("bld_blacksmith"), "Not enough coins")
	GameState.grant({"coins": 100_000})
	(GameState.p["buildings"] as Dictionary)["bld_blacksmith"] = 3
	assert_eq(VillageLogic.blocker("bld_blacksmith"), "Not enough timber")
	assert_false(VillageLogic.start("bld_blacksmith"))
	assert_eq(GameState.amount("coins"), 100_000, "nothing spent on a refused upgrade")


func test_max_level_is_ten() -> void:
	_rich()
	(GameState.p["buildings"] as Dictionary)["bld_blacksmith"] = 10
	assert_eq(VillageLogic.blocker("bld_blacksmith"), "Max level")


func test_gem_skip_finishes_the_job() -> void:
	_rich()
	(GameState.p["buildings"] as Dictionary)["bld_healer"] = 3
	VillageLogic.start("bld_healer")
	assert_eq(VillageLogic.skip_cost("bld_healer"), 1)
	GameState.time_override = NOW + 60.0
	assert_true(VillageLogic.skip("bld_healer"))
	assert_eq(GameState.building_level("bld_healer"), 4)
	assert_eq(GameState.amount("gems"), 9_999)
	assert_eq(VillageLogic.jobs().size(), 0)


func test_buildings_change_hero_stats() -> void:
	var hero: HeroData = GameData.hero("hero_muthu")
	var base: PlayerStats = PlayerStats.compute(hero, {}, {})
	var built: PlayerStats = PlayerStats.compute(hero, {"bld_blacksmith": 5, "bld_healer": 10, "bld_lamp_tower": 3}, {})
	assert_almost_eq(base.max_hp, 110.0, 0.01, "Lampwarden: +10% of 100")
	assert_almost_eq(built.max_hp, 176.0, 0.01, "(100 + 60) * 1.1")
	assert_almost_eq(built.damage_mult, 1.2, 0.001)
	assert_almost_eq(built.damage_reduction, 0.06, 0.001)


func test_library_gives_rerolls_and_lamp_tower_unlocks_revive() -> void:
	var library: BuildingData = GameData.building("bld_library")
	assert_eq(library.rerolls_at(2), 0)
	assert_eq(library.rerolls_at(3), 1)
	assert_eq(library.rerolls_at(9), 3)
	assert_eq(GameData.building("bld_lamp_tower").revive_unlock_level, 1)
	assert_eq(GameData.buildings().size(), 7)


func test_hero_unlock_with_coins() -> void:
	assert_false(RunCommit.unlock_hero_with_coins("hero_ammu"))
	GameState.grant({"coins": 5000})
	assert_true(RunCommit.unlock_hero_with_coins("hero_ammu"))
	assert_true(GameState.has_hero("hero_ammu"))
	assert_eq(GameState.amount("coins"), 0)
	assert_false(RunCommit.unlock_hero_with_coins("hero_ammu"), "already unlocked")


# --- chests ---------------------------------------------------------------

func test_displayed_odds_come_from_roll_weights_and_sum_to_100() -> void:
	for chest_id: String in ["free_chest", "guardian_chest"]:
		var odds: Array[Dictionary] = ChestLogic.odds(chest_id)
		var drops: Array = ChestLogic.config(chest_id)["drops"]
		assert_eq(odds.size(), drops.size())
		var total: float = 0.0
		for entry: Dictionary in odds:
			total += float(entry["percent"])
		assert_almost_eq(total, 100.0, 0.001, chest_id)


func test_rolls_match_the_displayed_odds() -> void:
	rng.seed = 99
	var counts: Dictionary = {}
	var rolls: int = 20000
	for i: int in rolls:
		var label: String = str(ChestLogic.roll("free_chest", rng)["label"])
		counts[label] = int(counts.get(label, 0)) + 1
	for entry: Dictionary in ChestLogic.odds("free_chest"):
		var seen: float = float(counts.get(entry["label"], 0)) / float(rolls) * 100.0
		assert_almost_eq(seen, float(entry["percent"]), 1.5, str(entry["label"]))


func test_free_chest_has_a_six_hour_cooldown() -> void:
	assert_false(ChestLogic.open_free(rng).is_empty())
	assert_true(ChestLogic.open_free(rng).is_empty(), "second open is refused")
	assert_almost_eq(ChestLogic.free_remaining(), 6.0 * 3600.0, 0.01)
	GameState.time_override = NOW + 6.0 * 3600.0 + 1.0
	assert_false(ChestLogic.open_free(rng).is_empty())


func test_ad_chest_is_capped_at_three_per_day() -> void:
	for i: int in 3:
		assert_false(ChestLogic.open_free_from_ad(rng).is_empty())
	assert_eq(ChestLogic.ad_opens_left(), 0)
	assert_true(ChestLogic.open_free_from_ad(rng).is_empty())
	GameState.date_override = "2026-01-11"
	assert_eq(ChestLogic.ad_opens_left(), 3)


func test_guardian_chest_costs_120_gems() -> void:
	assert_true(ChestLogic.buy_guardian(rng).is_empty(), "cannot afford")
	GameState.grant({"gems": 120})
	assert_false(ChestLogic.buy_guardian(rng).is_empty())
	assert_eq(GameState.amount("gems"), 0)
	assert_true(GameState.amount("coins") + GameState.amount("timber") > 0)


# --- daily systems --------------------------------------------------------

func test_three_missions_per_day_stable_within_the_day() -> void:
	var first: Array = DailyLogic.missions().duplicate(true)
	assert_eq(first.size(), 3)
	assert_eq(DailyLogic.missions(), first)
	GameState.date_override = "2026-01-11"
	assert_eq(DailyLogic.missions().size(), 3)
	assert_eq(int((DailyLogic.missions()[0] as Dictionary)["progress"]), 0)


func test_mission_progress_and_claim() -> void:
	(GameState.p["missions"] as Dictionary)["date"] = GameState.today()
	(GameState.p["missions"] as Dictionary)["list"] = [
		{"id": "m_kill_wisps", "progress": 0, "claimed": false},
		{"id": "m_survive_10", "progress": 0, "claimed": false}]
	var summary: Dictionary = {"victory": false, "time": 400.0, "kills": 320, "kills_by_type": {"e_wisp": 300, "e_crawler": 20},
		"level": 12, "bonus_coins": 0, "boss_timber": 3, "bosses": ["b_crawler_queen"], "evolutions": 0}
	DailyLogic.record_run(summary)
	assert_eq(int((DailyLogic.missions()[0] as Dictionary)["progress"]), 300)
	assert_eq(int((DailyLogic.missions()[1] as Dictionary)["progress"]), 6, "max mode keeps the best run")
	assert_false(DailyLogic.claim_mission(0), "not complete yet")
	DailyLogic.record_run(summary)
	assert_eq(int((DailyLogic.missions()[0] as Dictionary)["progress"]), 600, "sum mode accumulates")
	assert_true(DailyLogic.claim_mission(0))
	assert_eq(GameState.amount("gems"), 10)
	assert_eq(GameState.amount("coins"), 150)
	assert_false(DailyLogic.claim_mission(0), "only once")


func test_login_calendar_loops_over_seven_days() -> void:
	var gems: int = 0
	for day: int in 8:
		GameState.date_override = "2026-02-%02d" % (day + 1)
		assert_true(DailyLogic.login_available())
		var rewards: Dictionary = DailyLogic.claim_login()
		assert_false(rewards.is_empty())
		assert_true(DailyLogic.claim_login().is_empty(), "once per day")
		if day == 6:
			assert_eq(int(rewards["gems"]), 50, "day 7 = 50 gems")
		gems += int(rewards.get("gems", 0))
	assert_eq(DailyLogic.login_day_index(), 1, "day 8 restarted the loop")
	assert_eq(GameState.amount("gems"), gems)


func test_achievement_claims_once_when_reached() -> void:
	assert_false(DailyLogic.claim_achievement("a_first_dawn"))
	GameState.add_stat("dawns", 1)
	assert_true(DailyLogic.claim_achievement("a_first_dawn"))
	assert_eq(GameState.amount("gems"), 30)
	assert_false(DailyLogic.claim_achievement("a_first_dawn"))


func test_all_buildings_level_5_achievement() -> void:
	for data: BuildingData in GameData.buildings():
		(GameState.p["buildings"] as Dictionary)[data.id] = 5
	(GameState.p["buildings"] as Dictionary)["bld_granary"] = 4
	assert_false(DailyLogic.claim_achievement("a_buildings_5"))
	(GameState.p["buildings"] as Dictionary)["bld_granary"] = 5
	assert_true(DailyLogic.claim_achievement("a_buildings_5"))

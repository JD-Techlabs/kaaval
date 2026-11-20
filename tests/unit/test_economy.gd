extends "res://tests/base_test.gd"
## Spec §8: costs, timers, gem skip, run rewards. Expected values are worked
## out by hand from the spec formulas.


func test_building_coin_cost_follows_120_times_1_55_pow() -> void:
	assert_eq(Economy.building_coin_cost(1), 120)
	assert_eq(Economy.building_coin_cost(2), 186)
	assert_eq(Economy.building_coin_cost(3), 288)
	assert_eq(Economy.building_coin_cost(4), 447)
	assert_eq(Economy.building_coin_cost(10), 6197)


func test_timber_is_free_until_level_4() -> void:
	for level: int in [1, 2, 3]:
		assert_eq(Economy.building_timber_cost(level), 0, "L%d" % level)
	assert_eq(Economy.building_timber_cost(4), 2)
	assert_eq(Economy.building_timber_cost(5), 3)
	assert_eq(Economy.building_timber_cost(6), 4)
	assert_eq(Economy.building_timber_cost(7), 5)


func test_build_time_instant_then_5_min_times_1_8() -> void:
	for level: int in [1, 2, 3]:
		assert_eq(Economy.build_seconds(level, 1.0), 0.0, "L%d" % level)
	assert_almost_eq(Economy.build_seconds(4, 1.0), 300.0, 0.01)
	assert_almost_eq(Economy.build_seconds(5, 1.0), 540.0, 0.01)
	assert_almost_eq(Economy.build_seconds(6, 1.0), 972.0, 0.01)


func test_build_time_is_capped_at_8_hours() -> void:
	assert_almost_eq(Economy.build_seconds(12, 1.0), 8.0 * 3600.0, 0.01)
	assert_almost_eq(Economy.build_seconds(30, 1.0), 8.0 * 3600.0, 0.01)


func test_build_time_respects_remote_multiplier() -> void:
	assert_almost_eq(Economy.build_seconds(4, 0.5), 150.0, 0.01)


func test_gem_skip_is_ceil_of_minutes_over_6() -> void:
	assert_eq(Economy.skip_gems(0.0), 0)
	assert_eq(Economy.skip_gems(1.0), 1)
	assert_eq(Economy.skip_gems(300.0), 1)
	assert_eq(Economy.skip_gems(360.0), 1)
	assert_eq(Economy.skip_gems(361.0), 2)
	assert_eq(Economy.skip_gems(37.0 * 60.0), 7)
	assert_eq(Economy.skip_gems(8.0 * 3600.0), 80)


func test_run_coins_on_defeat() -> void:
	# 800 kills / 8 + 10 min * 12 = 220
	assert_eq(Economy.run_coins(800, 600.0, false, 1.0, 1.0, 0), 220)


func test_run_coins_on_dawn_get_multiplier_and_bonus() -> void:
	# (1600 / 8 + 15 * 12) * 1.5 + 200 = 770
	assert_eq(Economy.run_coins(1600, 900.0, true, 1.0, 1.0, 0), 770)


func test_run_coins_apply_granary_remote_and_bonus_coins() -> void:
	assert_eq(Economy.run_coins(800, 600.0, false, 1.1, 1.0, 50), 297)
	assert_eq(Economy.run_coins(800, 600.0, false, 1.0, 2.0, 0), 440)


func test_run_timber() -> void:
	assert_eq(Economy.run_timber(0, false), 0)
	assert_eq(Economy.run_timber(9, false), 9)
	assert_eq(Economy.run_timber(9, true), 19)


func test_builder_slots() -> void:
	assert_eq(Economy.builder_slots(false), 1)
	assert_eq(Economy.builder_slots(true), 2)


func test_run_commit_grants_rewards_once() -> void:
	var summary: Dictionary = {"hero": "hero_muthu", "victory": true, "time": 900.0, "kills": 1600,
		"kills_by_type": {"e_wisp": 1600}, "level": 30, "bonus_coins": 0, "boss_timber": 9,
		"bosses": ["b_crawler_queen", "b_banyan_wraith"], "evolutions": 1, "coin_mult": 1.0}
	var coins: int = RunCommit.coins_for(summary)
	assert_eq(coins, 770)
	RunCommit.commit(summary, coins)
	assert_eq(GameState.amount("coins"), 770)
	assert_eq(GameState.amount("timber"), 19)
	assert_eq(GameState.stat("dawns"), 1)
	assert_eq(GameState.stat("kills"), 1600)
	assert_eq(int(GameState.p["runs_played"]), 1)

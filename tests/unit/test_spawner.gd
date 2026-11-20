extends "res://tests/base_test.gd"
## Spec §7.3: the wave table gives the expected rate, mix and events over time.

var wave: WaveData


func before_each() -> void:
	super.before_each()
	wave = GameData.wave("forest_edge")


func test_rates_match_the_timeline() -> void:
	var expected: Dictionary = {30.0: 1.0, 120.0: 2.0, 240.0: 3.0, 400.0: 4.0, 540.0: 5.5, 700.0: 7.0, 800.0: 9.0}
	for time: float in expected.keys():
		assert_eq(Spawner.rate_at(wave, time), float(expected[time]), "rate at %ds" % int(time))


func test_first_minute_is_only_wisps() -> void:
	var mix: Dictionary = Spawner.mix_at(wave, 10.0)
	assert_eq(mix.size(), 1)
	assert_almost_eq(float(mix["e_wisp"]), 1.0, 0.001)


func test_mix_fractions_sum_to_one() -> void:
	for time: float in [10.0, 100.0, 200.0, 400.0, 500.0, 700.0, 800.0]:
		var total: float = 0.0
		for share: float in Spawner.mix_at(wave, time).values():
			total += share
		assert_almost_eq(total, 1.0, 0.001, "at %ds" % int(time))


func test_mid_game_mix() -> void:
	var mix: Dictionary = Spawner.mix_at(wave, 400.0)
	assert_almost_eq(float(mix["e_wisp"]), 0.5, 0.001)
	assert_almost_eq(float(mix["e_crawler"]), 0.25, 0.001)
	assert_almost_eq(float(mix["e_golem"]), 0.15, 0.001)
	assert_almost_eq(float(mix["e_thief"]), 0.10, 0.001)


func test_pick_enemy_maps_roll_to_mix() -> void:
	var mix: Dictionary = Spawner.mix_at(wave, 400.0)
	assert_eq(Spawner.pick_enemy(mix, 0.0), "e_wisp")
	assert_eq(Spawner.pick_enemy(mix, 0.49), "e_wisp")
	assert_eq(Spawner.pick_enemy(mix, 0.51), "e_crawler")
	assert_eq(Spawner.pick_enemy(mix, 0.80), "e_golem")
	assert_eq(Spawner.pick_enemy(mix, 0.95), "e_thief")
	assert_eq(Spawner.pick_enemy(mix, 0.999999), "e_thief")


func _simulate(from: float, to: float) -> Dictionary:
	var spawner: Spawner = Spawner.new(wave)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var counts: Dictionary = {}
	var time: float = 0.0
	var step: float = 0.05
	while time < to:
		time += step
		for request: Dictionary in spawner.step(step, time, rng):
			if time >= from:
				var key: String = "%s:%s" % [request["type"], request["id"]]
				counts[key] = int(counts.get(key, 0)) + int(request["count"])
	return counts


func test_spawn_count_matches_rate_over_a_segment() -> void:
	var counts: Dictionary = _simulate(60.0, 180.0)
	var total: int = int(counts.get("enemy:e_wisp", 0)) + int(counts.get("enemy:e_crawler", 0))
	assert_almost_eq(float(total), 240.0, 3.0, "2/s for 120 s")
	assert_almost_eq(float(counts["enemy:e_crawler"]) / float(total), 0.2, 0.08)


func test_bosses_fire_once_at_their_times() -> void:
	var counts: Dictionary = _simulate(0.0, 900.0)
	assert_eq(int(counts["boss:b_crawler_queen"]), 1)
	assert_eq(int(counts["boss:b_banyan_wraith"]), 1)
	assert_eq(int(counts["boss:b_eclipse_beast"]), 1)
	assert_eq(int(counts["ring:e_wisp"]), 40, "ring swarm at 9:00")
	assert_eq(_simulate(0.0, 299.0).has("boss:b_crawler_queen"), false, "queen not before 5:00")


func test_crow_lines_come_every_30s_between_3_and_5_minutes() -> void:
	var counts: Dictionary = _simulate(180.0, 300.0)
	assert_eq(int(counts.get("crow_line:e_crow", 0)), 4 * wave.crow_line_count)
	assert_eq(_simulate(0.0, 180.0).has("crow_line:e_crow"), false)


func test_boss_data_matches_spec() -> void:
	assert_eq(GameData.boss("b_crawler_queen").hp, 800.0)
	assert_eq(GameData.boss("b_banyan_wraith").hp, 3000.0)
	assert_eq(GameData.boss("b_eclipse_beast").hp, 8000.0)
	assert_eq(GameData.boss("b_crawler_queen").timber, 3)
	assert_eq(GameData.boss("b_banyan_wraith").timber, 6)

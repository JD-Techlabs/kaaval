extends "res://tests/base_test.gd"
## XP curve, hero stats, weapon data, spatial grid, remote config, content rules.


func test_xp_curve_matches_spec_formula() -> void:
	assert_eq(XpSystem.xp_to_next(1), 11)   # round(6 + 4 + 0.6)
	assert_eq(XpSystem.xp_to_next(10), 70)  # round(6 + 40 + 0.6 * 10^1.6)
	assert_eq(XpSystem.xp_to_next(20), 158)


func test_add_xp_can_gain_several_levels() -> void:
	var state: RunState = RunState.new()
	assert_eq(XpSystem.add_xp(state, 10.0), 0)
	assert_eq(XpSystem.add_xp(state, 1.0), 1)
	assert_eq(state.level, 2)
	assert_eq(XpSystem.add_xp(state, 500.0) > 3, true)
	assert_true(state.xp < XpSystem.xp_to_next(state.level))


func test_hero_modifiers() -> void:
	var muthu: PlayerStats = PlayerStats.compute(GameData.hero("hero_muthu"), {}, {})
	var ammu: PlayerStats = PlayerStats.compute(GameData.hero("hero_ammu"), {}, {})
	assert_almost_eq(muthu.max_hp, 110.0, 0.01)
	assert_almost_eq(muthu.move_speed, 220.0, 0.01)
	assert_almost_eq(ammu.max_hp, 85.0, 0.01)
	assert_almost_eq(ammu.area_mult, 1.15, 0.001)
	assert_almost_eq(ammu.xp_mult, 1.1, 0.001)
	assert_eq(muthu.weapon_slots, 4)
	assert_eq(muthu.passive_slots, 4)
	assert_eq(GameData.hero("hero_ammu").unlock_coins, 5000)


func test_passives_per_level() -> void:
	var hero: HeroData = GameData.hero("hero_muthu")
	var stats: PlayerStats = PlayerStats.compute(hero, {}, {"p_bangle": 3, "p_sandals": 5, "p_neem": 2,
		"p_magnet": 5, "p_whetstone": 5, "p_hourglass": 5})
	assert_almost_eq(stats.armor, 3.0, 0.001)
	assert_almost_eq(stats.move_speed, 220.0 * 1.4, 0.01)
	assert_almost_eq(stats.hp_regen, 0.6, 0.001)
	assert_almost_eq(stats.pickup_radius, 160.0, 0.01)
	assert_almost_eq(stats.damage_mult, 1.4, 0.001)
	assert_almost_eq(stats.cooldown_mult, 0.7, 0.001)


func test_armor_is_flat_with_minimum_damage_of_one() -> void:
	var stats: PlayerStats = PlayerStats.compute(GameData.hero("hero_muthu"), {}, {"p_bangle": 5})
	assert_almost_eq(stats.damage_taken(12.0), 7.0, 0.001)
	assert_almost_eq(stats.damage_taken(3.0), 1.0, 0.001)


func test_weapon_levels_follow_spec_table() -> void:
	var sling: WeaponData = GameData.weapon("w_sling")
	assert_almost_eq(sling.stat("damage", 1), 12.0, 0.001)
	assert_almost_eq(sling.stat("damage", 5), 12.0 * 1.8, 0.001)
	assert_eq(int(sling.stat("projectiles", 2)), 1)
	assert_eq(int(sling.stat("projectiles", 3)), 2)
	assert_eq(int(sling.stat("projectiles", 5)), 3)
	var orbit: WeaponData = GameData.weapon("w_lamp_orbit")
	assert_eq(int(orbit.stat("flames", 1)), 2)
	assert_eq(int(orbit.stat("flames", 5)), 6)
	var spear: WeaponData = GameData.weapon("w_bamboo_spear")
	assert_eq(int(spear.stat("pierce", 1)), 3)
	assert_eq(int(spear.stat("pierce", 5)), 7)
	var cracker: WeaponData = GameData.weapon("w_firecracker")
	assert_almost_eq(cracker.stat("cooldown", 5), 2.2 * (1.0 - 0.32), 0.001)
	assert_eq(int(GameData.weapon("w_thorn_whip").stat("sides", 3)), 2)
	assert_almost_eq(GameData.weapon("w_chilli_smoke").stat("damage", 5), 8.0, 0.001)


func test_content_counts_match_the_mvp() -> void:
	assert_eq(GameData.weapons().size(), 8)
	assert_eq(GameData.passives().size(), 6)
	assert_eq(GameData.heroes().size(), 6)
	for weapon: WeaponData in GameData.weapons():
		assert_true(ResourceLoader.exists(weapon.script_path), weapon.id)
		assert_true(ResourceLoader.exists(weapon.icon), weapon.id)
	for id: String in ["e_wisp", "e_crawler", "e_crow", "e_golem", "e_mud_pup", "e_thief", "e_moth", "e_beetle", "e_shade"]:
		assert_not_null(GameData.enemy(id), id)
		assert_true(ResourceLoader.exists(GameData.enemy(id).texture), id)


func test_spatial_grid_finds_neighbours_only() -> void:
	var grid: SpatialGrid = SpatialGrid.new(Vector2(4000, 4000), 64.0)
	grid.insert("near", Vector2(1000, 1000))
	grid.insert("edge", Vector2(1090, 1000))
	grid.insert("far", Vector2(3000, 3000))
	var found: Array = []
	grid.query(Vector2(1010, 1010), 100.0, found)
	assert_true(found.has("near"))
	assert_true(found.has("edge"))
	assert_false(found.has("far"))
	grid.clear()
	found.clear()
	grid.query(Vector2(1010, 1010), 100.0, found)
	assert_eq(found.size(), 0)


func test_spatial_grid_clamps_out_of_bounds_positions() -> void:
	var grid: SpatialGrid = SpatialGrid.new(Vector2(4000, 4000), 64.0)
	grid.insert("outside", Vector2(-500, 9000))
	var found: Array = []
	grid.query(Vector2(0, 4000), 80.0, found)
	assert_true(found.has("outside"))


func test_remote_config_overrides_known_keys_only() -> void:
	assert_eq(RemoteConfig.num("max_enemies"), 300.0)
	assert_true(RemoteConfig.apply_json_text('{"max_enemies": 150, "coin_multiplier": 2, "starter_pack_enabled": false, "hack": 1, "xp_multiplier": "lots"}'))
	assert_eq(RemoteConfig.num("max_enemies"), 150.0)
	assert_eq(RemoteConfig.num("coin_multiplier"), 2.0)
	assert_false(RemoteConfig.flag("starter_pack_enabled"))
	assert_eq(RemoteConfig.num("hack"), 0.0, "unknown keys are ignored")
	assert_eq(RemoteConfig.num("xp_multiplier"), 1.0, "wrong types are ignored")
	assert_false(RemoteConfig.apply_json_text("not json"))


func test_remote_config_changes_rewards_without_a_new_build() -> void:
	var summary: Dictionary = {"victory": false, "time": 600.0, "kills": 800, "bonus_coins": 0, "coin_mult": 1.0}
	assert_eq(RunCommit.coins_for(summary), 220)
	RemoteConfig.apply_overrides({"coin_multiplier": 1.5})
	assert_eq(RunCommit.coins_for(summary), 330)


func test_dawn_brightens_between_13_and_15_minutes() -> void:
	assert_eq(Darkness.dawn_progress(700.0, 780.0, 900.0), 0.0)
	assert_almost_eq(Darkness.dawn_progress(840.0, 780.0, 900.0), 0.5, 0.001)
	assert_eq(Darkness.dawn_progress(900.0, 780.0, 900.0), 1.0)


func test_village_building_changes_look_at_levels_1_4_7_10() -> void:
	assert_eq(VillageView.tier(0), 0)
	assert_eq(VillageView.tier(1), 1)
	assert_eq(VillageView.tier(3), 1)
	assert_eq(VillageView.tier(4), 2)
	assert_eq(VillageView.tier(7), 3)
	assert_eq(VillageView.tier(10), 4)

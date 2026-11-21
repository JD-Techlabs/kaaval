extends "res://tests/base_test.gd"
## Village ages: data is complete and ordered, building caps, advancing,
## resources from runs, and old saves starting in the first age.


func _run(age: String, victory: bool, time: float, bosses: Array = []) -> Dictionary:
	return {"hero": "hero_muthu", "night": "forest_edge", "age": age, "victory": victory, "time": time,
		"kills": 0, "kills_by_type": {}, "level": 1, "bonus_coins": 0, "boss_timber": 0, "bosses": bosses,
		"evolutions": 0, "gifts": 0, "potions_used": 0, "coin_mult": 1.0}


func _set_levels(levels: Dictionary) -> void:
	for id: String in levels.keys():
		(GameState.p["buildings"] as Dictionary)[id] = int(levels[id])


# --- data -----------------------------------------------------------------

func test_seven_ages_in_order() -> void:
	var names: Array[String] = []
	for age: AgeData in AgeLogic.ages():
		names.append(age.display_name)
	assert_eq(names, ["Founders' Age", "Age of Keeps", "Blackpowder Age", "Age of Learning",
		"Age of Steam", "Age of Steel", "Age of Circuits"] as Array[String])


func test_ages_open_resources_step_by_step() -> void:
	var list: Array[AgeData] = AgeLogic.ages()
	assert_eq(list[0].resources, ["food", "timber"] as Array[String])
	assert_true(list[1].resources.has("stone"))
	assert_true(list[3].resources.has("knowledge"))
	assert_true(list[4].resources.has("oil"))
	assert_true(list[5].resources.has("rare_metals"))
	for i: int in range(1, list.size()):
		for kind: String in list[i - 1].resources:
			assert_true(list[i].resources.has(kind), "%s keeps %s" % [list[i].id, kind])


func test_every_requirement_is_reachable_in_the_age_before() -> void:
	var list: Array[AgeData] = AgeLogic.ages()
	assert_true(list[0].required_buildings.is_empty() and list[0].advance_cost.is_empty())
	for i: int in range(1, list.size()):
		var before: AgeData = list[i - 1]
		assert_gt(list[i].building_cap, before.building_cap, "%s raises the cap" % list[i].id)
		assert_gte(list[i].enemy_hp_mult, before.enemy_hp_mult, "%s is not easier" % list[i].id)
		assert_gt(list[i].resource_mult, before.resource_mult, "%s pays more" % list[i].id)
		for id: String in list[i].required_buildings.keys():
			assert_not_null(GameData.building(id), "%s needs real building %s" % [list[i].id, id])
			var land: LandData = GameData.land(GameData.building(id).land)
			assert_lte(AgeLogic.number(land.required_age), i, "%s: %s stands on land open in an earlier age" % [list[i].id, id])
			assert_lte(int(list[i].required_buildings[id]), before.building_cap, "%s %s fits the earlier cap" % [list[i].id, id])
		for kind: String in list[i].advance_cost.keys():
			assert_true(before.resources.has(kind), "%s costs %s, earned in %s" % [list[i].id, kind, before.id])
	assert_eq(list[-1].building_cap, 10, "the last age allows max level")


# --- state ----------------------------------------------------------------

func test_new_and_old_profiles_start_in_the_first_age() -> void:
	assert_eq(AgeLogic.current().id, "age_founders")
	GameState.p.erase("age")
	assert_eq(AgeLogic.current().id, "age_founders", "missing age falls back to the first")
	# An old save written before ages existed.
	SaveManager.save_data({"coins": 500, "buildings": {"bld_blacksmith": 6}})
	GameState.load_profile()
	assert_eq(AgeLogic.current().id, "age_founders")
	assert_eq(GameState.amount("food"), 0)
	assert_eq(GameState.building_level("bld_blacksmith"), 6, "levels above the cap are kept")


func test_building_cap_blocks_upgrades_until_next_age() -> void:
	GameState.grant({"coins": 1_000_000, "timber": 10_000, "food": 10_000})
	_set_levels({"bld_blacksmith": 3})
	assert_eq(VillageLogic.blocker("bld_blacksmith"), "Next age needed")
	assert_false(VillageLogic.start("bld_blacksmith"))
	GameState.p["age"] = "age_keeps"
	assert_eq(VillageLogic.blocker("bld_blacksmith"), "")


func test_advance_needs_buildings_then_resources() -> void:
	assert_eq(AgeLogic.blocker(), "Upgrade buildings")
	_set_levels({"bld_blacksmith": 3, "bld_healer": 3, "bld_granary": 2, "bld_farm": 2})
	assert_eq(AgeLogic.blocker(), "Need resources")
	GameState.grant({"food": 249, "timber": 30})
	assert_false(AgeLogic.advance())
	assert_eq(AgeLogic.missing_resources(AgeLogic.next_age()), [{"kind": "food", "need": 250, "have": 249}] as Array[Dictionary])
	GameState.grant({"food": 51})
	assert_true(AgeLogic.advance())
	assert_eq(AgeLogic.current().id, "age_keeps")
	assert_eq(GameState.amount("food"), 50, "cost spent")
	assert_eq(GameState.amount("timber"), 0)


func test_final_age_cannot_advance() -> void:
	GameState.p["age"] = "age_circuits"
	assert_null(AgeLogic.next_age())
	assert_eq(AgeLogic.blocker(), "Final age")
	assert_false(AgeLogic.advance())


func test_advance_survives_a_restart() -> void:
	_set_levels({"bld_blacksmith": 3, "bld_healer": 3, "bld_granary": 2, "bld_farm": 2})
	GameState.grant({"food": 300, "timber": 30})
	assert_true(AgeLogic.advance())
	GameState.reset_profile()
	GameState.load_profile()
	assert_eq(AgeLogic.current().id, "age_keeps")


# --- run rewards ----------------------------------------------------------

func test_run_resources_follow_the_age_formula() -> void:
	# Founders: food only (timber has its own formula). 10 min, 1 boss, no dawn.
	var out: Dictionary = AgeLogic.run_resources("age_founders", 600.0, false, 1, 1.0)
	assert_eq(out, {"food": 10 * 8 + 10})
	# Dawn adds the dawn bonus.
	assert_eq(AgeLogic.run_resources("age_founders", 900.0, true, 0, 1.0), {"food": 15 * 8 + 60})
	# Keeps pays stone too, times the age's resource multiplier.
	var keeps: Dictionary = AgeLogic.run_resources("age_keeps", 600.0, false, 0, 1.0)
	assert_eq(int(keeps["food"]), roundi(80 * 1.25))
	assert_eq(int(keeps["stone"]), roundi(50 * 1.25))
	assert_false(keeps.has("oil"))


func test_rare_metals_come_from_bosses_and_dawn_only() -> void:
	var out: Dictionary = AgeLogic.run_resources("age_steel", 600.0, false, 0, 1.0)
	assert_false(out.has("rare_metals"))
	out = AgeLogic.run_resources("age_steel", 900.0, true, 3, 1.0)
	assert_eq(int(out["rare_metals"]), roundi((3 * 1 + 3) * 2.7))


func test_commit_grants_resources_for_the_age_played() -> void:
	RunCommit.commit(_run("age_founders", false, 300.0), 0)
	assert_eq(GameState.amount("food"), 40)
	assert_eq(GameState.amount("stone"), 0, "stone is not open in the first age")
	RunCommit.commit(_run("age_keeps", false, 300.0), 0)
	assert_eq(GameState.amount("stone"), roundi(25 * 1.25))

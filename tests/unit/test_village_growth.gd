extends "res://tests/base_test.gd"
## Stage 2 of the ages: land to buy, buildings that make resources over real
## time, and resource costs on building upgrades.

const HOUR: float = 3600.0


func _level(id: String, level: int) -> void:
	(GameState.p["buildings"] as Dictionary)[id] = level


func _farm() -> BuildingData:
	return GameData.building("bld_farm")


## Owns the fields and builds the farm to `level` through VillageLogic (starts its clock).
func _build_farm(level: int) -> void:
	GameState.grant({"coins": 1_000_000, "timber": 1000, "food": 100_000})
	GameState.p["lands"] = ["land_fields"]
	for i: int in level:
		assert_true(VillageLogic.start("bld_farm"), "farm to L%d" % (i + 1))


# --- data -----------------------------------------------------------------

func test_lands_are_ordered_with_the_green_free() -> void:
	var lands: Array[LandData] = GameData.lands()
	assert_eq(lands[0].id, "land_core")
	assert_eq(lands[0].coin_cost, 0)
	assert_true(LandLogic.owned("land_core"))
	for i: int in range(1, lands.size()):
		assert_gt(lands[i].coin_cost, lands[i - 1].coin_cost, "%s costs more" % lands[i].id)
		assert_gte(AgeLogic.number(lands[i].required_age), AgeLogic.number(lands[i - 1].required_age))
		assert_false(LandLogic.owned(lands[i].id), "%s is not owned at start" % lands[i].id)


func test_every_building_has_land_and_fits_in_its_band() -> void:
	for data: BuildingData in GameData.buildings():
		var land: LandData = GameData.land(data.land)
		assert_not_null(land, "%s land" % data.id)
		assert_between(data.village_pos.x, 0.0, 1.0, "%s x" % data.id)
		assert_between(data.village_pos.y, 0.0, 1.0, "%s y" % data.id)
		assert_true(data.stat != "" or data.produces != "", "%s does something" % data.id)
		if not data.produces.is_empty():
			assert_true(AgeLogic.resource_kinds().has(data.produces), "%s makes a known resource" % data.id)
			assert_gt(data.per_hour, 0.0)


func test_building_costs_use_resources_open_when_its_land_is() -> void:
	for data: BuildingData in GameData.buildings():
		var age: AgeData = AgeLogic.age(GameData.land(data.land).required_age)
		for kind: String in data.extra_costs.keys():
			assert_true(age.resources.has(kind), "%s costs %s, open in %s" % [data.id, kind, age.id])


func test_the_age_list_matches_the_owners_buildings() -> void:
	var by_age: Dictionary = {}
	for data: BuildingData in GameData.buildings():
		var age: String = GameData.land(data.land).required_age
		by_age[age] = (by_age.get(age, []) as Array) + [data.id]
	assert_true((by_age["age_founders"] as Array).has("bld_farm"))
	assert_true((by_age["age_founders"] as Array).has("bld_lumber_camp"))
	assert_true((by_age["age_blackpowder"] as Array).has("bld_food_factory"))
	assert_true((by_age["age_blackpowder"] as Array).has("bld_timber_mill"))
	assert_true((by_age["age_steam"] as Array).has("bld_metal_factory"))
	assert_true((by_age["age_circuits"] as Array).has("bld_ai_lab"))
	assert_eq(GameData.building("bld_library").produces, "knowledge")


# --- land -----------------------------------------------------------------

func test_land_needs_age_then_coins() -> void:
	assert_eq(LandLogic.blocker("land_hill"), "Needs Age of Keeps")
	assert_eq(LandLogic.blocker("land_fields"), "Not enough coins")
	GameState.grant({"coins": 600})
	assert_true(LandLogic.buy("land_fields"))
	assert_eq(GameState.amount("coins"), 100)
	assert_true(LandLogic.owned("land_fields"))
	assert_eq(LandLogic.blocker("land_fields"), "Owned")
	assert_false(LandLogic.buy("land_fields"), "cannot buy twice")
	GameState.reset_profile()
	GameState.load_profile()
	assert_true(LandLogic.owned("land_fields"), "survives a restart")


func test_buildings_need_their_land() -> void:
	GameState.grant({"coins": 10_000, "food": 1000})
	assert_eq(VillageLogic.blocker("bld_farm"), "Buy the land first")
	GameState.p["lands"] = ["land_fields"]
	assert_eq(VillageLogic.blocker("bld_farm"), "")


# --- costs ----------------------------------------------------------------

func test_upgrades_spend_resource_costs() -> void:
	GameState.grant({"coins": 10_000})
	assert_eq(VillageLogic.blocker("bld_blacksmith"), "Not enough food")
	assert_eq(Economy.building_resource_costs(GameData.building("bld_blacksmith"), 1), {"food": 15})
	assert_eq(Economy.building_resource_costs(GameData.building("bld_blacksmith"), 3), {"food": roundi(15 * 1.45 * 1.45)})
	GameState.grant({"food": 20})
	assert_true(VillageLogic.start("bld_blacksmith"))
	assert_eq(GameState.amount("food"), 5)


# --- production -----------------------------------------------------------

func test_farm_makes_food_over_real_time() -> void:
	_build_farm(2)
	var food: int = GameState.amount("food")
	assert_eq(ProductionLogic.ready(_farm()), 0)
	GameState.time_override = NOW + 2.0 * HOUR
	assert_eq(ProductionLogic.ready(_farm()), 2 * 6 * 2, "6 per level per hour")
	assert_eq(ProductionLogic.collect(_farm()), 24)
	assert_eq(GameState.amount("food"), food + 24)
	assert_eq(ProductionLogic.ready(_farm()), 0, "collected")


func test_storage_caps_production() -> void:
	_build_farm(1)
	GameState.time_override = NOW + 100.0 * HOUR
	assert_eq(ProductionLogic.capacity(_farm()), 6 * 8)
	assert_eq(ProductionLogic.ready(_farm()), 48)
	ProductionLogic.collect(_farm())
	GameState.time_override = NOW + 101.0 * HOUR
	assert_eq(ProductionLogic.ready(_farm()), 6, "a full store restarts counting from collection")


func test_part_units_are_kept_between_collections() -> void:
	_build_farm(1)
	var lumber: BuildingData = GameData.building("bld_lumber_camp")
	assert_true(VillageLogic.start("bld_lumber_camp"))
	# 0.5 timber per hour: after 3 hours, 1 unit ready and half a unit left over.
	GameState.time_override = NOW + 3.0 * HOUR
	assert_eq(ProductionLogic.collect(lumber), 1)
	GameState.time_override = NOW + 4.0 * HOUR
	assert_eq(ProductionLogic.ready(lumber), 1, "the left-over half counts")


func test_production_keeps_going_while_the_app_is_closed() -> void:
	_build_farm(1)
	GameState.save()
	GameState.reset_profile()
	GameState.load_profile()
	GameState.time_override = NOW + 5.0 * HOUR
	assert_eq(ProductionLogic.ready(_farm()), 30)


func test_upgrade_banks_production_at_the_old_level() -> void:
	_build_farm(1)
	GameState.time_override = NOW + 2.0 * HOUR
	var food: int = GameState.amount("food")
	assert_true(VillageLogic.start("bld_farm"))
	var spent: int = int(Economy.building_resource_costs(_farm(), 2).get("food", 0))
	assert_eq(GameState.amount("food"), food + 12 - spent, "12 food banked before paying")


func test_library_makes_knowledge_only_from_the_age_of_learning() -> void:
	_level("bld_library", 3)
	var library: BuildingData = GameData.building("bld_library")
	ProductionLogic.sync_clocks()
	GameState.time_override = NOW + HOUR
	assert_false(ProductionLogic.is_active(library))
	assert_eq(ProductionLogic.ready(library), 0)
	GameState.p["age"] = "age_learning"
	ProductionLogic.sync_clocks()
	GameState.time_override = NOW + 3.0 * HOUR
	assert_eq(ProductionLogic.ready(library), 2 * 3 * 2, "counts from when knowledge opened")


func test_ai_lab_boosts_every_producer() -> void:
	_build_farm(1)
	GameState.time_override = NOW + HOUR
	assert_eq(ProductionLogic.ready(_farm()), 6)
	_level("bld_ai_lab", 5)
	assert_almost_eq(ProductionLogic.production_mult(), 1.3, 0.0001)
	assert_eq(ProductionLogic.ready(_farm()), floori(6 * 1.3))


func test_collect_all_gathers_every_kind() -> void:
	_build_farm(1)
	assert_true(VillageLogic.start("bld_lumber_camp"))
	GameState.time_override = NOW + 4.0 * HOUR
	assert_eq(ProductionLogic.total_ready(), 24 + 2)
	assert_eq(ProductionLogic.collect_all(), {"food": 24, "timber": 2})
	assert_eq(ProductionLogic.total_ready(), 0)


func test_armory_speeds_up_attacks() -> void:
	var hero: HeroData = GameData.hero("hero_muthu")
	var base: PlayerStats = PlayerStats.compute(hero, {}, {})
	var armed: PlayerStats = PlayerStats.compute(hero, {"bld_armory": 5}, {})
	assert_almost_eq(armed.cooldown_mult, base.cooldown_mult - 0.1, 0.0001)

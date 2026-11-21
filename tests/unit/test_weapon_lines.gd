extends "res://tests/base_test.gd"
## Stage 3 of the ages: every hero's starting weapon steps up each age, with
## called-in strikes (tank, jet, missiles) in the last two ages.

const STRIKE_TYPES: Array[String] = ["tank", "jet", "missiles"]
const STEP: float = 0.05


# --- data -----------------------------------------------------------------

func test_every_hero_has_a_seven_tier_line() -> void:
	for hero: HeroData in GameData.heroes():
		var line: WeaponLineData = WeaponLine.line(hero.id)
		assert_not_null(line, "%s has a line" % hero.id)
		if line == null:
			continue
		assert_eq(line.tiers.size(), AgeLogic.ages().size(), "%s: one tier per age" % hero.id)


func test_tiers_get_stronger_and_point_at_real_files() -> void:
	for hero: HeroData in GameData.heroes():
		var base: WeaponData = GameData.weapon(hero.starting_weapon)
		var previous: float = 0.0
		var names: Dictionary = {}
		for tier: Dictionary in WeaponLine.line(hero.id).tiers:
			var name: String = str(tier["name"])
			assert_false(names.has(name), "%s: %s is used once" % [hero.id, name])
			names[name] = true
			assert_gt(float(tier["power"]), previous, "%s: %s is stronger" % [hero.id, name])
			previous = float(tier["power"])
			assert_true(ResourceLoader.exists(str(tier["icon"])), "%s icon" % name)
			if tier.has("sprite"):
				assert_true(ResourceLoader.exists(str(tier["sprite"])), "%s sprite" % name)
			for key: String in (tier["add"] as Dictionary).keys():
				var known: bool = base.params.has(key) or (base.id == "w_sling" and key == "explode_radius")
				assert_true(known, "%s: %s changes a stat the weapon uses" % [name, key])


func test_strikes_arrive_in_the_last_two_ages() -> void:
	for hero: HeroData in GameData.heroes():
		var tiers: Array[Dictionary] = WeaponLine.line(hero.id).tiers
		for i: int in tiers.size():
			var strikes: Array = tiers[i].get("strikes", [])
			if i < 5:
				assert_eq(strikes.size(), 0, "%s tier %d has no strikes yet" % [hero.id, i + 1])
			else:
				assert_gt(strikes.size(), 0, "%s tier %d calls strikes" % [hero.id, i + 1])
			for strike: Dictionary in strikes:
				assert_true(STRIKE_TYPES.has(str(strike["type"])), "known strike %s" % strike["type"])
				assert_gt(float(strike["cooldown"]), 0.0)
				assert_gt(float(strike["damage"]), 0.0)


func test_lampwarden_follows_the_owners_ladder() -> void:
	var names: Array[String] = []
	for age: AgeData in AgeLogic.ages():
		names.append(WeaponLine.weapon_for("w_sling", "hero_muthu", age.id).display_name)
	assert_eq(names, ["Sling Stone", "Longbow", "Musket", "Rifle", "Heavy Gun", "Heavy Gun + Tank",
		"Heavy Gun + Air Support"] as Array[String])
	var last: Array[Dictionary] = WeaponLine.strikes("hero_muthu", "age_circuits")
	assert_eq(last.map(func(s: Dictionary) -> String: return str(s["type"])), ["jet", "missiles"])


# --- tiered weapon --------------------------------------------------------

func test_tier_applies_power_params_and_art_without_touching_the_base() -> void:
	var base: WeaponData = GameData.weapon("w_sling")
	var rifle: WeaponData = WeaponLine.weapon_for("w_sling", "hero_muthu", "age_learning")
	assert_eq(rifle.display_name, "Rifle")
	assert_almost_eq(rifle.power, 1.7, 0.0001)
	assert_eq(rifle.stat("pierce", 1), base.stat("pierce", 1) + 2.0)
	assert_eq(rifle.stat("projectiles", 3), base.stat("projectiles", 3) + 1.0, "level steps still apply")
	assert_eq(rifle.sprite, "res://assets/sprites/bullet.svg")
	assert_eq(base.display_name, "Sling Stone", "base weapon unchanged")
	assert_eq(base.power, 1.0)
	assert_eq(base.sprite, "")


func test_only_the_heros_own_starting_weapon_is_tiered() -> void:
	var picked_up: WeaponData = WeaponLine.weapon_for("w_valari", "hero_muthu", "age_steel")
	assert_eq(picked_up, GameData.weapon("w_valari"))
	assert_eq(WeaponLine.weapon_for("w_valari", "hero_gale", "age_steel").display_name, "Buzz Blades + Rotor Strike")


func test_ui_lookup_uses_the_selected_hero_and_age() -> void:
	GameState.p["selected_hero"] = "hero_muthu"
	assert_eq(WeaponLine.weapon_for("w_sling").display_name, "Sling Stone")
	GameState.p["age"] = "age_blackpowder"
	assert_eq(WeaponLine.weapon_for("w_sling").display_name, "Musket")
	var card: Dictionary = BossChest.describe_card({"kind": "weapon", "id": "w_sling", "level": 1})
	assert_eq(str(card["title"]), "Musket")


# --- in a run -------------------------------------------------------------

func _new_run(hero_id: String, age_id: String) -> RunManager:
	GameState.p["selected_hero"] = hero_id
	GameState.p["hints_done"] = true
	GameState.p["age"] = age_id
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	run.rng.seed = 99
	return run


func _advance(run: RunManager, seconds: float) -> void:
	var left: float = seconds
	while left > 0.0 and run.mode != RunManager.Mode.ENDED:
		if run.mode == RunManager.Mode.CHOOSING:
			run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
		elif run.mode == RunManager.Mode.CHEST:
			run.close_chest()
		else:
			run.advance(STEP)
			left -= STEP


func test_run_uses_the_tiered_starting_weapon() -> void:
	var run: RunManager = _new_run("hero_muthu", "age_keeps")
	var weapon: BaseWeapon = run.weapon_nodes["w_sling"]
	assert_eq(weapon.data.display_name, "Longbow")
	assert_almost_eq(weapon.damage(), 12.0 * 1.2 * run.player.stats.damage_mult, 0.001)
	assert_eq(run.strikes.strike_count(), 0, "no strikes before the Age of Steel")


func test_tank_strike_drives_in_and_shells_creatures() -> void:
	var run: RunManager = _new_run("hero_muthu", "age_steel")
	assert_eq(run.strikes.strike_count(), 1)
	var wisp: EnemyData = GameData.enemy("e_wisp")
	run.enemies.spawn_around(wisp, run.player.position, 12, 300.0)
	_advance(run, StrikeCaller.FIRST_DELAY + 0.2)
	assert_eq(run.strikes.vehicle_count(), 1, "the tank is on screen")
	_advance(run, 8.0)
	assert_gt(run.state.kills, 0)


func test_missile_strike_needs_a_target_and_then_fires() -> void:
	var run: RunManager = _new_run("hero_muthu", "age_circuits")
	var missiles: Dictionary = WeaponLine.strikes("hero_muthu", "age_circuits")[1]
	run.enemies.clear_around(run.player.position, 99999.0)
	assert_false(run.strikes.call_strike(missiles), "nothing to hit")
	run.enemies.spawn_around(GameData.enemy("e_wisp"), run.player.position, 3, 250.0)
	var before: int = run.projectiles.count()
	assert_true(run.strikes.call_strike(missiles))
	assert_eq(run.projectiles.count() - before, 3, "one missile per creature, up to the volley size")


func test_jet_pass_hits_creatures_along_its_path() -> void:
	var run: RunManager = _new_run("hero_gale", "age_steel")
	run.enemies.clear_around(run.player.position, 99999.0)
	var jet: Dictionary = WeaponLine.strikes("hero_gale", "age_steel")[0]
	run.enemies.spawn_around(GameData.enemy("e_golem"), run.player.position, 1, 200.0)
	var target: Enemy = run.enemies.nearest(run.player.position, 9999.0, 1)[0]
	var hp: float = target.hp
	assert_true(run.strikes.call_strike(jet))
	for i: int in 60:
		run.enemies.step(STEP)
		run.strikes.step(STEP)
	assert_lt(target.hp, hp, "the jet hit the creature on its row")
	assert_eq(run.strikes.vehicle_count(), 0, "and flew off the screen")

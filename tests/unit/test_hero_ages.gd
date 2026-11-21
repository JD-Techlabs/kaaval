extends "res://tests/base_test.gd"
## Stage 4 of the ages: heroes wear each age's gear and each brings a resource bonus.


func test_every_hero_has_a_look_for_every_later_age() -> void:
	for hero: HeroData in GameData.heroes():
		for age: AgeData in AgeLogic.ages():
			var path: String = hero.texture_for(age)
			assert_true(ResourceLoader.exists(path), "%s in %s: %s" % [hero.id, age.id, path])
			if age.hero_gear.is_empty():
				assert_eq(path, hero.texture, "%s keeps their own look in %s" % [hero.id, age.id])
			else:
				assert_string_contains(path, "hero_looks/%s_%s" % [hero.id, age.hero_gear])


func test_each_age_after_the_first_has_its_own_gear() -> void:
	var seen: Dictionary = {}
	for age: AgeData in AgeLogic.ages():
		if AgeLogic.number(age.id) == 1:
			assert_eq(age.hero_gear, "")
			continue
		assert_false(age.hero_gear.is_empty(), "%s has gear" % age.id)
		assert_false(seen.has(age.hero_gear), "%s gear is its own" % age.id)
		seen[age.hero_gear] = true


func test_every_hero_has_a_valid_resource_bonus() -> void:
	for hero: HeroData in GameData.heroes():
		assert_false(hero.resource_bonus.is_empty(), "%s has a bonus" % hero.id)
		for kind: String in hero.resource_bonus.keys():
			assert_true(AgeLogic.resource_kinds().has(kind), "%s: %s is a resource" % [hero.id, kind])
			assert_between(float(hero.resource_bonus[kind]), 0.01, 0.5)
	assert_eq(GameData.hero("hero_muthu").bonus_text(), "+10% food from nights")


func test_bonus_raises_only_its_resource() -> void:
	var plain: Dictionary = AgeLogic.run_resources("age_learning", 600.0, false, 0, 1.0)
	var boosted: Dictionary = AgeLogic.run_resources("age_learning", 600.0, false, 0, 1.0, {"knowledge": 0.15})
	assert_eq(int(boosted["knowledge"]), roundi(30 * 1.8 * 1.15))
	assert_eq(boosted["food"], plain["food"])
	assert_eq(boosted["stone"], plain["stone"])


func test_commit_uses_the_hero_who_played() -> void:
	var summary: Dictionary = {"hero": "hero_banyan", "night": "forest_edge", "age": "age_keeps", "victory": false,
		"time": 600.0, "kills": 0, "kills_by_type": {}, "level": 1, "bonus_coins": 0, "boss_timber": 0,
		"bosses": [], "evolutions": 0, "gifts": 0, "potions_used": 0, "coin_mult": 1.0}
	assert_eq(int(RunCommit.resources_for(summary)["stone"]), roundi(50 * 1.25 * 1.15))
	assert_eq(int(RunCommit.resources_for(summary)["food"]), roundi(80 * 1.25))


func test_run_sprite_wears_the_age_gear() -> void:
	GameState.p["selected_hero"] = "hero_gale"
	GameState.p["hints_done"] = true
	GameState.p["age"] = "age_steam"
	var run: RunManager = RunManager.new()
	add_child_autofree(run)
	run.set_process(false)
	var sprite: Sprite2D = null
	for child: Node in run.player.get_children():
		if child is Sprite2D:
			sprite = child
	assert_not_null(sprite)
	assert_eq(sprite.texture.resource_path, "res://assets/sprites/hero_looks/hero_gale_steam.svg")

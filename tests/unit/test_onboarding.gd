extends "res://tests/base_test.gd"
## The first minutes: first-night bonus, systems that appear after the first
## night, a short intro, and one home popup per visit in a fixed order.


func _night(time: float) -> Dictionary:
	return {"hero": "hero_muthu", "night": "forest_edge", "age": "age_founders", "victory": false, "time": time,
		"kills": 0, "kills_by_type": {}, "level": 1, "bonus_coins": 0, "boss_timber": 0, "bosses": [],
		"evolutions": 0, "gifts": 0, "potions_used": 0, "coin_mult": 1.0}


# --- first-night bonus ----------------------------------------------------

func test_first_night_bonus_only_once() -> void:
	assert_eq(Onboarding.first_night_bonus(), {"coins": 150, "food": 20})
	RunCommit.commit(_night(60.0), 10)
	assert_eq(GameState.amount("coins"), 10 + 150)
	assert_eq(Onboarding.first_night_bonus(), {}, "gone after the first night")
	var coins: int = GameState.amount("coins")
	RunCommit.commit(_night(60.0), 10)
	assert_eq(GameState.amount("coins"), coins + 10, "no bonus the second time")


func test_even_a_short_first_night_buys_the_first_building() -> void:
	var summary: Dictionary = _night(30.0)
	RunCommit.commit(summary, RunCommit.coins_for(summary))
	var blacksmith: BuildingData = GameData.building("bld_blacksmith")
	assert_gte(GameState.amount("coins"), Economy.building_coin_cost(1))
	assert_gte(GameState.amount("food"), int(Economy.building_resource_costs(blacksmith, 1)["food"]))
	assert_eq(VillageLogic.blocker("bld_blacksmith"), "")


# --- systems appear after the first night ---------------------------------

func test_village_systems_unlock_after_the_first_night() -> void:
	assert_false(Onboarding.village_unlocked())
	RunCommit.commit(_night(60.0), 0)
	assert_true(Onboarding.village_unlocked())


func test_tip_is_for_new_villages_only() -> void:
	assert_true(Onboarding.show_tip())
	for id: String in ["bld_blacksmith", "bld_healer", "bld_granary"]:
		(GameState.p["buildings"] as Dictionary)[id] = 1
	assert_false(Onboarding.show_tip())


# --- How to play ----------------------------------------------------------

func test_intro_is_two_pages_and_village_guide_follows() -> void:
	assert_eq(HowToPlay.pages("intro").size(), 2)
	assert_eq(HowToPlay.pages("village").size(), 2)
	assert_eq(HowToPlay.pages().size(), 5, "Settings shows every page")
	for page: Dictionary in HowToPlay.pages("intro"):
		assert_lt(str(page["text"]).length(), 200, "intro pages stay short")


# --- one popup per visit --------------------------------------------------

func test_no_popup_before_the_first_night() -> void:
	assert_eq(Onboarding.next_home_popup(), "")


func test_popups_come_one_per_visit_in_order() -> void:
	GameState.p["runs_played"] = 1
	assert_eq(Onboarding.next_home_popup(), "village_intro")
	Onboarding.mark_village_intro_seen()
	assert_eq(Onboarding.next_home_popup(), "daily", "today's login reward is waiting")
	Onboarding.mark_daily_popup_shown()
	assert_eq(Onboarding.next_home_popup(), "starter_pack")
	GameState.p["starter_pack_shown_at"] = GameState.now()
	assert_eq(Onboarding.next_home_popup(), "")


func test_daily_popup_once_a_day_and_not_after_claiming() -> void:
	GameState.p["runs_played"] = 2
	GameState.p["village_intro_seen"] = true
	assert_true(Onboarding.daily_popup_due())
	DailyLogic.claim_login()
	assert_false(Onboarding.daily_popup_due(), "claimed today")
	GameState.date_override = "2026-01-11"
	assert_true(Onboarding.daily_popup_due(), "a new day")
	Onboarding.mark_daily_popup_shown()
	assert_false(Onboarding.daily_popup_due(), "closed with Later: not again today")

extends "res://tests/base_test.gd"
## Nights (stages): data is complete and consistent, unlocks follow dawn
## victories, progress is recorded at commit, and the goal text is right.


func _night_summary(night: String, victory: bool, time: float) -> Dictionary:
	return {"hero": "hero_muthu", "night": night, "victory": victory, "time": time, "kills": 100,
		"kills_by_type": {}, "level": 8, "bonus_coins": 0, "boss_timber": 0, "bosses": [], "evolutions": 0,
		"gifts": 0, "potions_used": 0, "coin_mult": 1.0}


# --- data -----------------------------------------------------------------

func test_three_nights_in_order() -> void:
	var ids: Array[String] = []
	for wave: WaveData in NightLogic.nights():
		ids.append(wave.id)
	assert_eq(ids, ["forest_edge", "paddy_fields", "old_fort"] as Array[String])
	assert_eq(NightLogic.number("paddy_fields"), 2)
	assert_eq(NightLogic.number("nowhere"), 0)


func test_every_night_has_three_bosses_of_its_own() -> void:
	var seen: Dictionary = {}
	for wave: WaveData in NightLogic.nights():
		var bosses: Array[Dictionary] = NightLogic.bosses(wave)
		assert_eq(bosses.size(), 3, "%s boss count" % wave.id)
		for entry: Dictionary in bosses:
			var id: String = str(entry["id"])
			assert_not_null(GameData.boss(id), "%s exists" % id)
			assert_true(ResourceLoader.exists(GameData.boss(id).script_path), "%s script" % id)
			assert_true(ResourceLoader.exists(GameData.boss(id).texture), "%s art" % id)
			assert_false(seen.has(id), "%s appears in only one night" % id)
			seen[id] = true
		assert_lt(float(bosses[2]["time"]), wave.duration, "final boss before dawn")


func test_every_night_timeline_is_complete_and_valid() -> void:
	for wave: WaveData in NightLogic.nights():
		var expected_start: float = 0.0
		for segment: Dictionary in wave.segments:
			assert_eq(float(segment["start"]), expected_start, "%s segments are contiguous" % wave.id)
			expected_start = float(segment["end"])
			for enemy_id: String in (segment["mix"] as Dictionary).keys():
				assert_not_null(GameData.enemy(enemy_id), "%s: %s exists" % [wave.id, enemy_id])
		assert_eq(expected_start, wave.duration, "%s covers the whole night" % wave.id)
		for time: float in [10.0, 200.0, 500.0, 850.0]:
			var total: float = 0.0
			for share: float in Spawner.mix_at(wave, time).values():
				total += share
			assert_almost_eq(total, 1.0, 0.001, "%s mix at %ds" % [wave.id, int(time)])
		for event: Dictionary in wave.events:
			var found: EnemyData = GameData.boss(str(event["id"])) if str(event["type"]) == "boss" else GameData.enemy(str(event["id"]))
			assert_not_null(found, "%s event %s" % [wave.id, event["id"]])
		assert_true(ResourceLoader.exists(wave.edge_sprite), "%s edge sprite" % wave.id)
		for prop: String in wave.props:
			assert_true(ResourceLoader.exists(prop), "%s prop %s" % [wave.id, prop])


func test_later_nights_are_harder_and_pay_more() -> void:
	var list: Array[WaveData] = NightLogic.nights()
	for i: int in range(1, list.size()):
		assert_gt(list[i].enemy_hp_mult, list[i - 1].enemy_hp_mult)
		assert_gt(list[i].enemy_dmg_mult, list[i - 1].enemy_dmg_mult)
		assert_gt(list[i].coin_mult, list[i - 1].coin_mult)
		assert_gt(GameData.boss(str(NightLogic.bosses(list[i])[2]["id"])).hp,
			GameData.boss(str(NightLogic.bosses(list[i - 1])[2]["id"])).hp, "final boss tougher")


func test_bosses_of_a_later_night_fire_once() -> void:
	var spawner: Spawner = Spawner.new(GameData.wave("old_fort"))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var bosses: Array[String] = []
	var time: float = 0.0
	while time < 900.0:
		time += 0.1
		for request: Dictionary in spawner.step(0.1, time, rng):
			if str(request["type"]) == "boss":
				bosses.append(str(request["id"]))
	assert_eq(bosses, ["b_iron_tusk", "b_hollow_captain", "b_night_colossus"] as Array[String])


# --- unlocks and progress -------------------------------------------------

func test_only_the_first_night_starts_unlocked() -> void:
	assert_true(NightLogic.is_unlocked("forest_edge"))
	assert_false(NightLogic.is_unlocked("paddy_fields"))
	assert_false(NightLogic.is_unlocked("old_fort"))
	assert_eq(NightLogic.selected().id, "forest_edge")
	assert_false(NightLogic.select("paddy_fields"), "cannot pick a locked night")
	assert_eq(NightLogic.selected().id, "forest_edge")


func test_defeat_records_best_time_but_unlocks_nothing() -> void:
	assert_eq(NightLogic.record_run(_night_summary("forest_edge", false, 312.0)), "")
	assert_eq(NightLogic.record_run(_night_summary("forest_edge", false, 200.0)), "")
	assert_eq(NightLogic.best_time("forest_edge"), 312.0, "best time keeps the longest night")
	assert_false(NightLogic.won("forest_edge"))
	assert_false(NightLogic.is_unlocked("paddy_fields"))


func test_dawn_unlocks_and_selects_the_next_night() -> void:
	var summary: Dictionary = _night_summary("forest_edge", true, 900.0)
	assert_eq(NightLogic.unlocks_after(summary), "paddy_fields", "results screen can announce it")
	assert_eq(NightLogic.record_run(summary), "paddy_fields")
	assert_true(NightLogic.is_unlocked("paddy_fields"))
	assert_false(NightLogic.is_unlocked("old_fort"))
	assert_eq(NightLogic.selected().id, "paddy_fields", "the new night is picked for the player")
	assert_eq(NightLogic.unlocks_after(summary), "", "winning again unlocks nothing new")
	assert_eq(NightLogic.record_run(summary), "")
	assert_true(NightLogic.select("forest_edge"), "earlier nights stay playable")


func test_last_night_unlocks_nothing() -> void:
	GameState.p["nights"] = {"forest_edge": {"won": true}, "paddy_fields": {"won": true}}
	assert_true(NightLogic.is_unlocked("old_fort"))
	assert_null(NightLogic.next_night("old_fort"))
	assert_eq(NightLogic.record_run(_night_summary("old_fort", true, 900.0)), "")
	assert_true(NightLogic.won("old_fort"))


func test_commit_records_night_progress() -> void:
	RunCommit.commit(_night_summary("forest_edge", true, 900.0), 100)
	assert_true(NightLogic.won("forest_edge"))
	assert_true(NightLogic.is_unlocked("paddy_fields"))
	GameState.load_profile()
	assert_true(NightLogic.is_unlocked("paddy_fields"), "survives a reload")


func test_results_text_explains_progress() -> void:
	assert_eq(ResultsScreen.night_progress_text(_night_summary("forest_edge", true, 900.0)), "Night 2 unlocked: Paddy Fields!")
	assert_eq(ResultsScreen.night_progress_text(_night_summary("forest_edge", false, 300.0)),
		"Survive until dawn (15:00) to unlock Night 2.")
	GameState.p["nights"] = {"forest_edge": {"won": true}}
	assert_eq(ResultsScreen.night_progress_text(_night_summary("forest_edge", false, 300.0)), "", "already unlocked")


func test_saved_selection_of_a_locked_night_falls_back() -> void:
	GameState.p["selected_night"] = "old_fort"
	assert_eq(NightLogic.selected().id, "forest_edge")
	GameState.p["nights"] = {"forest_edge": {"won": true}}
	assert_eq(NightLogic.selected().id, "paddy_fields", "latest unlocked night")


# --- objective ------------------------------------------------------------

func test_objective_line_follows_the_night() -> void:
	var wave: WaveData = GameData.wave("forest_edge")
	assert_eq(NightLogic.objective(wave, 0.0, ""), "Survive to dawn · Boss in 5:00")
	assert_eq(NightLogic.objective(wave, 299.5, ""), "Survive to dawn · Boss in 0:01")
	assert_eq(NightLogic.objective(wave, 320.0, "Thorn Queen"), "Defeat the Thorn Queen! · Dawn in 9:40")
	assert_eq(NightLogic.objective(wave, 400.0, ""), "Survive to dawn · Boss in 3:20")
	assert_eq(NightLogic.objective(wave, 870.0, "Eclipse Beast"), "Hold on! Dawn in 0:30")
	assert_eq(NightLogic.objective(wave, 900.0, ""), "Hold on! Dawn in 0:00")


func test_boss_schedule_and_intro_text() -> void:
	var wave: WaveData = GameData.wave("paddy_fields")
	assert_eq(NightLogic.boss_schedule(wave), "Mire Serpent 5:00 · Straw Giant 10:00 · Storm Heron 14:30")
	assert_eq(Hud.intro_text(wave), "NIGHT 2 · PADDY FIELDS\nSurvive until dawn (15:00)")
	assert_eq(NightLogic.clock(75.0), "1:15")
	assert_eq(NightLogic.clock(0.0), "0:00")


# --- how to play ----------------------------------------------------------

func test_how_to_play_pages_use_game_data() -> void:
	var pages: Array[Dictionary] = HowToPlay.pages()
	assert_eq(pages.size(), 5)
	for page: Dictionary in pages:
		assert_true(ResourceLoader.exists(str(page["icon"])), "icon %s" % page["icon"])
		assert_false(str(page["text"]).is_empty())
	assert_string_contains(str(pages[0]["text"]), "15:00")
	assert_string_contains(str(pages[3]["text"]), "Thorn Queen 5:00")
	assert_string_contains(str(pages[4]["text"]), "3 nights")


func test_how_to_play_is_remembered() -> void:
	assert_false(HowToPlay.seen(), "new players see it")
	HowToPlay.mark_seen()
	assert_true(HowToPlay.seen())
	GameState.load_profile()
	assert_true(HowToPlay.seen(), "saved")

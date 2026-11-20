extends "res://tests/base_test.gd"
## Spec §12.3: round-trip, migration, corrupt/tampered fallback, atomic write.


func test_round_trip_keeps_the_profile() -> void:
	GameState.add("coins", 1234)
	GameState.add("gems", 56)
	(GameState.p["buildings"] as Dictionary)["bld_blacksmith"] = 4
	GameState.unlock_hero("hero_ammu")
	GameState.set_setting("music_volume", 0.25)
	GameState.save()
	GameState.reset_profile()
	assert_eq(GameState.amount("coins"), 0)
	GameState.load_profile()
	assert_eq(GameState.amount("coins"), 1234)
	assert_eq(GameState.amount("gems"), 56)
	assert_eq(GameState.building_level("bld_blacksmith"), 4)
	assert_true(GameState.has_hero("hero_ammu"))
	assert_almost_eq(float(GameState.setting("music_volume")), 0.25, 0.0001)
	assert_false(SaveManager.last_load_was_corrupt)


func test_missing_file_gives_a_fresh_profile() -> void:
	GameState.load_profile()
	assert_eq(GameState.amount("coins"), 0)
	assert_true(GameState.has_hero("hero_muthu"))
	assert_false(SaveManager.last_load_was_corrupt)


func test_new_fields_get_defaults_when_loading_an_older_save() -> void:
	SaveManager.save_data({"coins": 77})
	GameState.load_profile()
	assert_eq(GameState.amount("coins"), 77)
	assert_true((GameState.p["settings"] as Dictionary).has("haptics"), "missing sections are filled from defaults")
	assert_eq(str(GameState.p["selected_hero"]), "hero_muthu")


func test_migration_from_version_0() -> void:
	var old: Dictionary = {"coins": 500, "music_volume": 0.3, "haptics": false}
	var migrated: Dictionary = SaveManager.migrate(old, 0)
	assert_false(migrated.has("music_volume"), "v0 top-level settings are moved")
	assert_almost_eq(float((migrated["settings"] as Dictionary)["music_volume"]), 0.3, 0.0001)
	assert_eq(bool((migrated["settings"] as Dictionary)["haptics"]), false)
	assert_true(migrated.has("stats"))
	assert_eq(int(migrated["coins"]), 500)


func test_version_0_file_is_migrated_on_load() -> void:
	var payload: String = JSON.stringify({"save_version": 0, "data": {"coins": 9, "sfx_volume": 0.1}})
	var file: FileAccess = FileAccess.open(SaveManager.path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"checksum": SaveManager.checksum(payload), "payload": payload}))
	file.close()
	GameState.load_profile()
	assert_eq(GameState.amount("coins"), 9)
	assert_almost_eq(float(GameState.setting("sfx_volume")), 0.1, 0.0001)


func test_garbage_file_falls_back_to_defaults() -> void:
	var file: FileAccess = FileAccess.open(SaveManager.path, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()
	GameState.load_profile()
	assert_true(SaveManager.last_load_was_corrupt)
	assert_eq(GameState.amount("coins"), 0)
	assert_true(FileAccess.file_exists(SaveManager.path + ".corrupt"), "bad file is kept for support")
	assert_push_warning("unreadable")


func test_tampered_file_fails_the_checksum() -> void:
	GameState.add("gems", 5)
	GameState.save()
	var text: String = FileAccess.get_file_as_string(SaveManager.path)
	assert_true(text.contains('\\"gems\\":5'), "sanity: payload has the value we will edit")
	var file: FileAccess = FileAccess.open(SaveManager.path, FileAccess.WRITE)
	file.store_string(text.replace('\\"gems\\":5', '\\"gems\\":99999'))
	file.close()
	GameState.load_profile()
	assert_true(SaveManager.last_load_was_corrupt)
	assert_eq(GameState.amount("gems"), 0)
	assert_push_warning("unreadable")


func test_save_leaves_no_temp_file_and_overwrites() -> void:
	GameState.add("coins", 1)
	GameState.save()
	GameState.add("coins", 1)
	GameState.save()
	assert_false(FileAccess.file_exists(SaveManager.path + ".tmp"))
	GameState.load_profile()
	assert_eq(GameState.amount("coins"), 2)

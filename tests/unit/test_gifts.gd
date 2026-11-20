extends "res://tests/base_test.gd"
## Hero Gifts and hero pieces, bought life potions, and the new hero roster.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _run_summary(level: int, potions_used: int = 0) -> Dictionary:
	return {"victory": false, "time": 300.0, "kills": 100, "kills_by_type": {}, "level": level, "bonus_coins": 0,
		"boss_timber": 0, "bosses": [], "evolutions": 0, "gifts": GiftLogic.earned_for_level(level), "potions_used": potions_used}


# --- gifts ------------------------------------------------------------------

func test_gifts_are_earned_at_the_set_levels() -> void:
	assert_eq(GiftLogic.run_levels(), [10, 20, 30] as Array[int])
	assert_eq(GiftLogic.earned_for_level(9), 0)
	assert_eq(GiftLogic.earned_for_level(10), 1)
	assert_eq(GiftLogic.earned_for_level(25), 2)
	assert_eq(GiftLogic.earned_for_level(60), 3)


func test_run_state_reports_gifts_and_commit_banks_them() -> void:
	var state: RunState = RunState.new()
	state.level = 21
	assert_eq(int(state.summary()["gifts"]), 2)
	assert_eq(GiftLogic.count(), 0, "nothing reaches the profile before the commit")
	RunCommit.commit(_run_summary(21), 0)
	assert_eq(GiftLogic.count(), 2)


func test_opening_needs_a_gift_and_uses_one() -> void:
	assert_true(GiftLogic.open(rng).is_empty())
	GameState.grant({"gifts": 2})
	assert_false(GiftLogic.open(rng).is_empty())
	assert_eq(GiftLogic.count(), 1)


func test_gift_odds_sum_to_100_and_pieces_are_rare() -> void:
	var total: float = 0.0
	var piece_share: float = 0.0
	var drops: Array = ChestLogic.config(GiftLogic.CHEST_ID)["drops"]
	var odds: Array[Dictionary] = ChestLogic.odds(GiftLogic.CHEST_ID)
	for i: int in odds.size():
		total += float(odds[i]["percent"])
		if (drops[i]["rewards"] as Dictionary).has("hero_pieces"):
			piece_share += float(odds[i]["percent"])
	assert_almost_eq(total, 100.0, 0.001)
	assert_true(piece_share > 0.0 and piece_share <= 20.0, "pieces are a minority drop (%.1f%%)" % piece_share)
	assert_true(ChestLogic.odds_text(GiftLogic.CHEST_ID).contains("hero piece"))


func test_opened_gifts_match_the_displayed_piece_odds() -> void:
	rng.seed = 5
	var opens: int = 8000
	GameState.grant({"gifts": opens})
	var with_pieces: int = 0
	for i: int in opens:
		GameState.p["hero_pieces"] = {}
		if not str(GiftLogic.open(rng)["hero"]).is_empty():
			with_pieces += 1
	var expected: float = 0.0
	var drops: Array = ChestLogic.config(GiftLogic.CHEST_ID)["drops"]
	var odds: Array[Dictionary] = ChestLogic.odds(GiftLogic.CHEST_ID)
	for i: int in odds.size():
		if (drops[i]["rewards"] as Dictionary).has("hero_pieces"):
			expected += float(odds[i]["percent"])
	assert_almost_eq(float(with_pieces) / float(opens) * 100.0, expected, 1.5)


func test_collecting_every_piece_unlocks_the_hero() -> void:
	var hero: HeroData = GameData.hero("hero_gale")
	assert_true(hero.pieces_needed > 0)
	assert_false(GiftLogic.add_pieces(hero.id, hero.pieces_needed - 1))
	assert_false(GameState.has_hero(hero.id))
	assert_eq(GiftLogic.pieces(hero.id), hero.pieces_needed - 1)
	assert_true(GiftLogic.add_pieces(hero.id, 5), "last piece unlocks")
	assert_true(GameState.has_hero(hero.id))
	assert_eq(GiftLogic.pieces(hero.id), hero.pieces_needed, "never above the full set")


func test_pieces_only_go_to_collectable_locked_heroes() -> void:
	assert_false(GiftLogic.add_pieces("hero_volt", 99), "purchase-only hero takes no pieces")
	assert_false(GameState.has_hero("hero_volt"))
	var ids: Array[String] = []
	for hero: HeroData in GiftLogic.locked_piece_heroes():
		ids.append(hero.id)
	assert_eq(ids, ["hero_gale", "hero_banyan"] as Array[String])
	GameState.unlock_hero("hero_gale")
	assert_eq(GiftLogic.locked_piece_heroes().size(), 1)


func test_piece_drop_becomes_coins_when_every_collectable_hero_is_owned() -> void:
	GameState.unlock_hero("hero_gale")
	GameState.unlock_hero("hero_banyan")
	rng.seed = 11
	GameState.grant({"gifts": 400})
	for i: int in 400:
		assert_eq(str(GiftLogic.open(rng)["hero"]), "")
	assert_true((GameState.p["hero_pieces"] as Dictionary).is_empty())
	assert_true(GameState.amount("coins") > 0)


func test_gifts_and_pieces_survive_a_restart() -> void:
	GameState.grant({"gifts": 3, "potions": 2})
	GiftLogic.add_pieces("hero_banyan", 4)
	GameState.save()
	GameState.reset_profile()
	GameState.load_profile()
	assert_eq(GiftLogic.count(), 3)
	assert_eq(GameState.amount("potions"), 2)
	assert_eq(GiftLogic.pieces("hero_banyan"), 4)


# --- heroes -----------------------------------------------------------------

func test_roster_has_free_collectable_and_purchase_only_heroes() -> void:
	assert_eq(GameData.heroes().size(), 6)
	var products: PackedStringArray = BillingService.product_ids()
	for hero: HeroData in GameData.heroes():
		assert_true(ResourceLoader.exists(hero.texture), hero.id)
		assert_not_null(GameData.weapon(hero.starting_weapon), hero.id)
		if hero.tier == "Elite":
			assert_eq(hero.unlock_coins, 0, hero.id)
			assert_eq(hero.pieces_needed, 0, hero.id)
		if hero.id != "hero_muthu":
			assert_true(products.has(hero.product_id), "%s has a store product" % hero.id)
			assert_eq(str((GameData.product(hero.product_id)["grants"] as Dictionary)["hero"]), hero.id)


func test_purchase_only_hero_cannot_be_bought_with_coins() -> void:
	GameState.grant({"coins": 1_000_000})
	assert_false(RunCommit.unlock_hero_with_coins("hero_volt"))
	assert_false(RunCommit.unlock_hero_with_coins("hero_gale"))
	assert_eq(GameState.amount("coins"), 1_000_000)


func test_stronger_tiers_have_stronger_stats() -> void:
	var starter: PlayerStats = PlayerStats.compute(GameData.hero("hero_muthu"), {}, {})
	var good: PlayerStats = PlayerStats.compute(GameData.hero("hero_gale"), {}, {})
	var better: PlayerStats = PlayerStats.compute(GameData.hero("hero_banyan"), {}, {})
	var elite: PlayerStats = PlayerStats.compute(GameData.hero("hero_morn"), {}, {})
	var storm: PlayerStats = PlayerStats.compute(GameData.hero("hero_volt"), {}, {})
	assert_true(good.damage_mult > starter.damage_mult and good.move_speed > starter.move_speed)
	assert_true(better.max_hp > good.max_hp and better.armor > 0.0 and better.damage_mult >= good.damage_mult)
	assert_true(elite.max_hp > starter.max_hp and elite.damage_mult > better.damage_mult)
	assert_true(storm.damage_mult > elite.damage_mult and storm.cooldown_mult < good.cooldown_mult)


# --- bought potions ---------------------------------------------------------

func test_buying_potions_with_coins_and_gems() -> void:
	assert_false(SupplyLogic.buy_with_coins(), "cannot afford")
	GameState.grant({"coins": SupplyLogic.price_coins(), "gems": SupplyLogic.pack_gems()})
	assert_true(SupplyLogic.buy_with_coins())
	assert_eq(GameState.amount("coins"), 0)
	assert_true(SupplyLogic.buy_pack_with_gems())
	assert_eq(GameState.amount("gems"), 0)
	assert_eq(GameState.amount("potions"), 1 + SupplyLogic.pack_size())
	assert_false(SupplyLogic.buy_pack_with_gems())


func test_commit_takes_the_potions_that_were_drunk() -> void:
	GameState.grant({"potions": 3})
	RunCommit.commit(_run_summary(5, 2), 0)
	assert_eq(GameState.amount("potions"), 1)
	RunCommit.commit(_run_summary(5, 9), 0)
	assert_eq(GameState.amount("potions"), 0, "never below zero")

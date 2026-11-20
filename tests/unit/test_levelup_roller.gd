extends "res://tests/base_test.gd"
## Spec §5.4 / §5.5: card rules and evolution eligibility.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _state() -> RunState:
	var state: RunState = RunState.new()
	state.weapons = {"w_sling": 1}
	return state


func test_offers_three_distinct_cards() -> void:
	for seed_value: int in 50:
		rng.seed = seed_value
		var cards: Array[Dictionary] = LevelupRoller.roll(_state(), rng)
		assert_eq(cards.size(), 3)
		var ids: Dictionary = {}
		for card: Dictionary in cards:
			ids[card["id"]] = true
		assert_eq(ids.size(), 3, "cards must be distinct")


func test_never_offers_maxed_items() -> void:
	var state: RunState = _state()
	state.weapons = {"w_sling": 5, "w_valari": 5}
	state.passives = {"p_bangle": 5}
	for seed_value: int in 200:
		rng.seed = seed_value
		for card: Dictionary in LevelupRoller.roll(state, rng):
			assert_false(str(card["id"]) in ["w_sling", "w_valari", "p_bangle"], "maxed item offered: %s" % card["id"])


func test_respects_weapon_and_passive_slots() -> void:
	var state: RunState = _state()
	state.weapons = {"w_sling": 1, "w_valari": 1, "w_war_drum": 1, "w_firecracker": 1}
	state.passives = {"p_bangle": 1, "p_neem": 1, "p_magnet": 1, "p_sandals": 1}
	for card: Dictionary in LevelupRoller.candidates(state):
		assert_false(bool(card["is_new"]), "no new items when slots are full: %s" % card["id"])
		assert_true(state.weapons.has(card["id"]) or state.passives.has(card["id"]))


func test_new_cards_start_at_level_1_and_upgrades_add_one() -> void:
	var state: RunState = _state()
	state.weapons = {"w_sling": 3}
	for card: Dictionary in LevelupRoller.candidates(state):
		if str(card["id"]) == "w_sling":
			assert_eq(int(card["level"]), 4)
			assert_false(bool(card["is_new"]))
		else:
			assert_eq(int(card["level"]), 1)
			assert_true(bool(card["is_new"]))


func test_owned_items_weigh_one_and_a_half() -> void:
	for card: Dictionary in LevelupRoller.candidates(_state()):
		assert_eq(float(card["weight"]), 1.5 if str(card["id"]) == "w_sling" else 1.0)


func test_fallback_when_nothing_is_available() -> void:
	var state: RunState = _state()
	state.weapons = {"w_sling": 5, "w_valari": 5, "w_war_drum": 5, "w_firecracker": 5}
	state.passives = {"p_bangle": 5, "p_neem": 5, "p_magnet": 5, "p_sandals": 5}
	var cards: Array[Dictionary] = LevelupRoller.roll(state, rng)
	assert_eq(cards.size(), 2)
	assert_eq(str(cards[0]["kind"]), "coins")
	assert_eq(str(cards[1]["kind"]), "heal")


func test_fewer_cards_when_pool_is_small() -> void:
	var state: RunState = _state()
	state.weapons = {"w_sling": 5, "w_valari": 5, "w_war_drum": 5, "w_firecracker": 4}
	state.passives = {"p_bangle": 5, "p_neem": 5, "p_magnet": 5, "p_sandals": 5}
	var cards: Array[Dictionary] = LevelupRoller.roll(state, rng)
	assert_eq(cards.size(), 1)
	assert_eq(str(cards[0]["id"]), "w_firecracker")


func test_evolution_needs_max_weapon_and_paired_passive() -> void:
	var state: RunState = _state()
	state.weapons = {"w_sling": 4}
	state.passives = {"p_whetstone": 1}
	assert_eq(LevelupRoller.eligible_evolutions(state).size(), 0, "weapon not maxed")
	state.weapons = {"w_sling": 5}
	state.passives = {"p_bangle": 3}
	assert_eq(LevelupRoller.eligible_evolutions(state).size(), 0, "wrong passive")
	state.passives = {"p_whetstone": 1}
	var evolutions: Array[EvolutionData] = LevelupRoller.eligible_evolutions(state)
	assert_eq(evolutions.size(), 1)
	assert_eq(evolutions[0].id, "evo_meteor_sling")


func test_evolved_weapon_is_not_eligible_or_offered_again() -> void:
	var state: RunState = _state()
	state.weapons = {"w_sling": 5}
	state.passives = {"p_whetstone": 1}
	state.evolved = {"w_sling": "evo_meteor_sling"}
	assert_eq(LevelupRoller.eligible_evolutions(state).size(), 0)
	for card: Dictionary in LevelupRoller.candidates(state):
		assert_ne(str(card["id"]), "w_sling")


func test_all_four_evolutions_pair_real_items() -> void:
	assert_eq(GameData.evolutions().size(), 4)
	for evo: EvolutionData in GameData.evolutions():
		assert_not_null(GameData.weapon(evo.weapon_id), evo.id)
		assert_not_null(GameData.passive(evo.passive_id), evo.id)


func test_apply_updates_state() -> void:
	var state: RunState = _state()
	LevelupRoller.apply(state, {"kind": "weapon", "id": "w_valari", "level": 1})
	LevelupRoller.apply(state, {"kind": "passive", "id": "p_neem", "level": 2})
	assert_eq(int(state.weapons["w_valari"]), 1)
	assert_eq(int(state.passives["p_neem"]), 2)

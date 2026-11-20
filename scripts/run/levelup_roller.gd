class_name LevelupRoller
extends RefCounted
## Builds level-up cards (spec §5.4). Pure: state + rng in, cards out.
## Card: {"kind": "weapon"|"passive"|"coins"|"heal", "id", "level", "is_new"}


## Every card that could legally be offered right now, with its weight.
static func candidates(state: RunState) -> Array[Dictionary]:
	var owned_weight: float = GameData.num("run", "owned_weight")
	var out: Array[Dictionary] = []
	for weapon: WeaponData in GameData.weapons():
		if state.weapons.has(weapon.id):
			var level: int = int(state.weapons[weapon.id])
			if level < weapon.max_level and not state.evolved.has(weapon.id):
				out.append({"kind": "weapon", "id": weapon.id, "level": level + 1, "is_new": false, "weight": owned_weight})
		elif state.weapons.size() < state.weapon_slots:
			out.append({"kind": "weapon", "id": weapon.id, "level": 1, "is_new": true, "weight": 1.0})
	for passive: PassiveData in GameData.passives():
		if state.passives.has(passive.id):
			var level: int = int(state.passives[passive.id])
			if level < passive.max_level:
				out.append({"kind": "passive", "id": passive.id, "level": level + 1, "is_new": false, "weight": owned_weight})
		elif state.passives.size() < state.passive_slots:
			out.append({"kind": "passive", "id": passive.id, "level": 1, "is_new": true, "weight": 1.0})
	return out


static func roll(state: RunState, rng: RandomNumberGenerator, count: int = -1) -> Array[Dictionary]:
	if count < 0:
		count = int(GameData.num("run", "card_count"))
	var pool: Array[Dictionary] = candidates(state)
	if pool.is_empty():
		return fallback_cards()
	var picked: Array[Dictionary] = []
	while picked.size() < count and not pool.is_empty():
		var total: float = 0.0
		for card: Dictionary in pool:
			total += float(card["weight"])
		var roll_value: float = rng.randf() * total
		var index: int = pool.size() - 1
		for i: int in pool.size():
			roll_value -= float(pool[i]["weight"])
			if roll_value < 0.0:
				index = i
				break
		picked.append(pool[index])
		pool.remove_at(index)
	return picked


static func fallback_cards() -> Array[Dictionary]:
	return [
		{"kind": "coins", "id": "coins", "level": 0, "is_new": false, "weight": 1.0},
		{"kind": "heal", "id": "heal", "level": 0, "is_new": false, "weight": 1.0},
	]


## Evolutions whose weapon is at max level (not yet evolved) with the paired passive owned.
static func eligible_evolutions(state: RunState) -> Array[EvolutionData]:
	var out: Array[EvolutionData] = []
	for evo: EvolutionData in GameData.evolutions():
		if state.evolved.has(evo.weapon_id) or not state.weapons.has(evo.weapon_id):
			continue
		var weapon: WeaponData = GameData.weapon(evo.weapon_id)
		if int(state.weapons[evo.weapon_id]) >= weapon.max_level and state.passives.has(evo.passive_id):
			out.append(evo)
	return out


## Applies a card to the state. Coins/heal cards are handled by the caller.
static func apply(state: RunState, card: Dictionary) -> void:
	match str(card["kind"]):
		"weapon":
			state.weapons[card["id"]] = int(card["level"])
		"passive":
			state.passives[card["id"]] = int(card["level"])

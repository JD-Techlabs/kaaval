class_name BossChest
extends RefCounted
## Boss Chest contents (spec §6.2): an evolution if one is eligible,
## otherwise 1-3 random upgrades; always some coins.
## Returns display lines: {"title", "tag", "icon", "desc"}


static func open(run: RunManager) -> Array[Dictionary]:
	var state: RunState = run.state
	var rng: RandomNumberGenerator = run.rng
	var lines: Array[Dictionary] = []
	var evolutions: Array[EvolutionData] = LevelupRoller.eligible_evolutions(state)
	if not evolutions.is_empty():
		var evo: EvolutionData = evolutions[rng.randi() % evolutions.size()]
		run.apply_evolution(evo)
		lines.append({"title": evo.display_name, "tag": "EVOLVE", "desc": evo.description,
			"icon": WeaponLine.weapon_for(evo.weapon_id).icon})
	else:
		var low: int = int(GameData.num("boss_chest", "min_upgrades"))
		var high: int = int(GameData.num("boss_chest", "max_upgrades"))
		for i: int in rng.randi_range(low, high):
			var cards: Array[Dictionary] = LevelupRoller.roll(state, rng, 1)
			if cards.is_empty() or str(cards[0]["kind"]) in ["coins", "heal"]:
				break
			run.apply_card(cards[0])
			lines.append(describe_card(cards[0]))
	var coins: int = int(GameData.num("boss_chest", "coins"))
	state.bonus_coins += coins
	lines.append({"title": "%d coins" % coins, "tag": "", "desc": "", "icon": "res://assets/sprites/icons/coin.svg"})
	return lines


## Shared card text for the chest and the level-up modal.
static func describe_card(card: Dictionary) -> Dictionary:
	var level: int = int(card["level"])
	match str(card["kind"]):
		"weapon":
			var weapon: WeaponData = WeaponLine.weapon_for(str(card["id"]))
			var desc: String = weapon.description if level <= 1 else "\n".join(weapon.level_changes(level))
			return {"title": weapon.display_name, "tag": "NEW" if level <= 1 else "Lv %d" % level, "desc": desc, "icon": weapon.icon}
		"passive":
			var passive: PassiveData = GameData.passive(str(card["id"]))
			return {"title": passive.display_name, "tag": "NEW" if level <= 1 else "Lv %d" % level, "desc": passive.description, "icon": passive.icon}
		"coins":
			return {"title": "+%d coins" % int(GameData.num("run", "fallback_coins")), "tag": "", "desc": "A purse for the village.",
				"icon": "res://assets/sprites/icons/coin.svg"}
	return {"title": "Heal %d%% HP" % roundi(GameData.num("run", "fallback_heal_pct") * 100.0), "tag": "", "desc": "Catch your breath.",
		"icon": "res://assets/sprites/icons/heal.svg"}

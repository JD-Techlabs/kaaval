class_name XpSystem
extends RefCounted
## XP curve (spec §4.4): round(6 + 4*level + 0.6*level^1.6).


static func xp_to_next(level: int) -> int:
	var c: Dictionary = GameData.balance("xp_curve")
	return roundi(float(c["base"]) + float(c["linear"]) * level + float(c["power_coeff"]) * pow(level, float(c["power"])))


## Adds XP to the state and returns how many levels were gained.
static func add_xp(state: RunState, amount: float) -> int:
	var gained: int = 0
	state.xp += amount
	while state.xp >= xp_to_next(state.level):
		state.xp -= xp_to_next(state.level)
		state.level += 1
		gained += 1
	return gained

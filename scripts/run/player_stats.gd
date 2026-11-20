class_name PlayerStats
extends RefCounted
## Final hero stats = (base + flat bonuses) * (1 + percentage bonuses).
## Sources: hero modifiers, village buildings, passives. Pure and testable.

var values: Dictionary = {}

var max_hp: float:
	get: return get_stat("max_hp")
var move_speed: float:
	get: return get_stat("move_speed")
var armor: float:
	get: return get_stat("armor")
var pickup_radius: float:
	get: return get_stat("pickup_radius")
var damage_mult: float:
	get: return get_stat("damage_mult")
var cooldown_mult: float:
	get: return get_stat("cooldown_mult")
var area_mult: float:
	get: return get_stat("area_mult")
var hp_regen: float:
	get: return get_stat("hp_regen")
var xp_mult: float:
	get: return get_stat("xp_mult")
var coin_mult: float:
	get: return get_stat("coin_mult")
var damage_reduction: float:
	get: return get_stat("damage_reduction")
var weapon_slots: int:
	get: return int(get_stat("weapon_slots"))
var passive_slots: int:
	get: return int(get_stat("passive_slots"))


func get_stat(key: String) -> float:
	return float(values.get(key, 0.0))


## building_levels / passive_levels: {id: level}
static func compute(hero: HeroData, building_levels: Dictionary, passive_levels: Dictionary) -> PlayerStats:
	var base: Dictionary = GameData.balance("hero_base")
	var flat: Dictionary = {}
	var pct: Dictionary = {}
	if hero != null:
		for mod: Dictionary in hero.mods:
			_collect(flat, pct, str(mod["stat"]), str(mod["mode"]), float(mod["value"]))
	for id: String in building_levels.keys():
		var building: BuildingData = GameData.building(id)
		if building != null:
			_collect(flat, pct, building.stat, building.mode, building.bonus_at(int(building_levels[id])))
	for id: String in passive_levels.keys():
		var passive: PassiveData = GameData.passive(id)
		if passive != null:
			_collect(flat, pct, passive.stat, passive.mode, passive.per_level * int(passive_levels[id]))
	var stats: PlayerStats = PlayerStats.new()
	for key: String in base.keys():
		var value: float = (float(base[key]) + float(flat.get(key, 0.0))) * (1.0 + float(pct.get(key, 0.0)))
		stats.values[key] = value
	stats.values["cooldown_mult"] = maxf(stats.cooldown_mult, GameData.num("combat", "min_cooldown_mult"))
	stats.values["damage_reduction"] = minf(stats.damage_reduction, GameData.num("combat", "max_damage_reduction"))
	return stats


static func _collect(flat: Dictionary, pct: Dictionary, stat: String, mode: String, value: float) -> void:
	var target: Dictionary = pct if mode == "pct" else flat
	target[stat] = float(target.get(stat, 0.0)) + value


## Damage actually taken from one hit (armor is flat, min 1; Lamp Tower is a % cut).
func damage_taken(raw: float) -> float:
	var after_armor: float = maxf(raw - armor, GameData.num("combat", "min_damage"))
	return maxf(after_armor * (1.0 - damage_reduction), GameData.num("combat", "min_damage"))

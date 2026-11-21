class_name BuildingData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var max_level: int = 10
@export var sort_order: int = 0
## Stat key understood by PlayerStats.
@export var stat: String = ""
@export var mode: String = "add"
@export var per_level: float = 0.0
## Text template for the bonus, with %s for the formatted value.
@export var bonus_text: String = ""
## Whether the bonus is shown as a percentage.
@export var bonus_is_percent: bool = true
## Levels that grant +1 reroll per run.
@export var reroll_levels: Array[int] = []
## Level that unlocks the revive slot (0 = never).
@export var revive_unlock_level: int = 0
## Land the building stands on (LandData id). It can be built once the land is owned.
@export var land: String = "land_core"
## Resource made over real time ("" = none) and how much per level per hour.
@export var produces: String = ""
@export var per_hour: float = 0.0
## Hours of production the building can hold before it must be collected.
@export var storage_hours: float = 8.0
## Extra resource cost at level 1: {kind: amount}, scaled per level by
## economy.resource_cost_growth in data/balance.json.
@export var extra_costs: Dictionary = {}
## Village layout: normalised position (0..1) inside its land, and colours for the drawn building.
@export var village_pos: Vector2 = Vector2(0.5, 0.5)
@export var wall_color: Color = Color(0.8, 0.6, 0.4)
@export var roof_color: Color = Color(0.7, 0.3, 0.2)
@export var emblem: String = ""


func bonus_at(level: int) -> float:
	return per_level * level


func rerolls_at(level: int) -> int:
	var count: int = 0
	for reroll_level: int in reroll_levels:
		if level >= reroll_level:
			count += 1
	return count


func production_at(level: int) -> float:
	return per_hour * level


func describe(level: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if not produces.is_empty():
		parts.append("%s %s per hour" % [_amount(production_at(level)), produces.replace("_", " ")])
	if not stat.is_empty():
		var value: float = bonus_at(level)
		var shown: String = ("%d%%" % roundi(absf(value) * 100.0)) if bonus_is_percent else str(roundi(value))
		parts.append(bonus_text % shown)
	var text: String = ", ".join(parts)
	var rerolls: int = rerolls_at(level)
	if rerolls > 0:
		text += ", +%d reroll%s" % [rerolls, "" if rerolls == 1 else "s"]
	if revive_unlock_level > 0 and level >= revive_unlock_level:
		text += ", revive unlocked"
	return text


## 12.0 -> "12", 1.5 -> "1.5", 0.45 -> "0.45"
static func _amount(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(value, 2)

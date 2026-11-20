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
## Village layout: normalised position (0..1) and colours for the drawn building.
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


func describe(level: int) -> String:
	var value: float = bonus_at(level)
	var shown: String = ("%d%%" % roundi(value * 100.0)) if bonus_is_percent else str(roundi(value))
	var text: String = bonus_text % shown
	var rerolls: int = rerolls_at(level)
	if rerolls > 0:
		text += ", +%d reroll%s" % [rerolls, "" if rerolls == 1 else "s"]
	if revive_unlock_level > 0 and level >= revive_unlock_level:
		text += ", revive unlocked"
	return text

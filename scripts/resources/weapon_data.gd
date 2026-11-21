class_name WeaponData
extends Resource
## One weapon. Every number lives in `params`; per-level growth is declared
## in the three level_* dictionaries so nothing is hard-coded in weapon scripts.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var script_path: String = ""
@export var max_level: int = 5
@export var sort_order: int = 0
## Projectile/flame sprite path overriding the weapon's own ("" = its default).
@export var sprite: String = ""
## Damage multiplier from the hero's weapon line (age tier); 1.0 = base weapon.
@export var power: float = 1.0
## Level-1 values, e.g. {"damage": 12.0, "cooldown": 0.9}
@export var params: Dictionary = {}
## Flat gain per level above 1, e.g. {"pierce": 1.0}
@export var level_add: Dictionary = {}
## Fractional gain per level above 1, e.g. {"damage": 0.2}; negative shrinks.
@export var level_mult: Dictionary = {}
## Levels that grant +1, e.g. {"projectiles": [3, 5]}
@export var level_steps: Dictionary = {}


func stat(key: String, level: int) -> float:
	var value: float = float(params.get(key, 0.0))
	var steps_above: int = maxi(level - 1, 0)
	value += float(level_add.get(key, 0.0)) * steps_above
	value *= 1.0 + float(level_mult.get(key, 0.0)) * steps_above
	var steps: Array = level_steps.get(key, [])
	for step_level: Variant in steps:
		if level >= int(step_level):
			value += 1.0
	return value


## Human-readable list of what changes when going from `level - 1` to `level`.
func level_changes(level: int) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for key: String in params.keys():
		var before: float = stat(key, level - 1)
		var after: float = stat(key, level)
		if not is_equal_approx(before, after):
			out.append("%s %s → %s" % [key.capitalize(), _fmt(before), _fmt(after)])
	return out


static func _fmt(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % value

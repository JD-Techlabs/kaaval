class_name HeroData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var title: String = ""
@export var description: String = ""
@export var texture: String = ""
@export var starting_weapon: String = ""
@export var sort_order: int = 0
## Array of {"stat": String, "mode": "add"|"pct", "value": float}
@export var mods: Array[Dictionary] = []
## Extra share of a night's resources: {kind: fraction}, e.g. {"food": 0.1} = +10% food.
@export var resource_bonus: Dictionary = {}
## Strength band shown on the hero card: "Starter", "Good", "Better", "Elite".
@export var tier: String = "Starter"
## Coin price; 0 = cannot be bought with coins.
@export var unlock_coins: int = 0
## Hero pieces (from Hero Gifts) that unlock the hero; 0 = not collectable.
@export var pieces_needed: int = 0
## Play product that unlocks the hero instantly ("" = none).
@export var product_id: String = ""


## The hero's sprite in an age: their own art plus that age's gear, when drawn.
func texture_for(age: AgeData) -> String:
	if age == null or age.hero_gear.is_empty():
		return texture
	var path: String = "res://assets/sprites/hero_looks/%s_%s.svg" % [id, age.hero_gear]
	return path if ResourceLoader.exists(path) else texture


## "+10% food" / "+8% food, stone, knowledge, oil, rare metals"
func bonus_text() -> String:
	if resource_bonus.is_empty():
		return ""
	var groups: Dictionary = {}
	for kind: String in resource_bonus.keys():
		var pct: int = roundi(float(resource_bonus[kind]) * 100.0)
		groups[pct] = (groups.get(pct, []) as Array) + [kind.replace("_", " ")]
	var parts: PackedStringArray = PackedStringArray()
	for pct: int in groups.keys():
		parts.append("+%d%% %s" % [pct, ", ".join(PackedStringArray(groups[pct]))])
	return "; ".join(parts) + " from nights"

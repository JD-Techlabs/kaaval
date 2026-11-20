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
## Strength band shown on the hero card: "Starter", "Good", "Better", "Elite".
@export var tier: String = "Starter"
## Coin price; 0 = cannot be bought with coins.
@export var unlock_coins: int = 0
## Hero pieces (from Hero Gifts) that unlock the hero; 0 = not collectable.
@export var pieces_needed: int = 0
## Play product that unlocks the hero instantly ("" = none).
@export var product_id: String = ""

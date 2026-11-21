class_name WeaponLineData
extends Resource
## A hero's starting weapon through the seven ages. Tier i is used in age i+1.
## Tier: {"name", "desc", "icon", "sprite" (optional), "power" (damage mult),
##        "add": {param: flat change}, "strikes": [strike, ...]}
## Strike: {"type": "tank"|"jet"|"missiles", "name", "cooldown", "damage",
##          "area", "count" (shells / missiles)}

@export var id: String = ""
## HeroData id this line belongs to.
@export var hero: String = ""
@export var tiers: Array[Dictionary] = []

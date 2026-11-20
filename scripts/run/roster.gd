class_name Roster
extends RefCounted
## Which creatures a night sends, by the hero's level (data/roster.json).
## Every level from `first_debut_level` on brings one new creature (a new kind,
## or a stronger rank of a known kind), and every `rank_every_levels` levels the
## ordinary wave creatures move up a rank. Pure functions over data.


static func _data() -> Dictionary:
	return GameData.json("roster")


static func rank_count() -> int:
	return (_data()["ranks"] as Array).size()


## {"name", "tint", "hp", "damage", "speed", "scale", "xp"}
static func rank(index: int) -> Dictionary:
	var ranks: Array = _data()["ranks"]
	var entry: Dictionary = ranks[clampi(index, 0, ranks.size() - 1)]
	return entry


## Rank of the ordinary wave creatures at a hero level.
static func base_rank(level: int) -> int:
	@warning_ignore("integer_division")
	return clampi((level - 1) / maxi(int(_data()["rank_every_levels"]), 1), 0, rank_count() - 1)


static func debut_count() -> int:
	return (_data()["debuts"] as Array).size()


## The creature that first appears at this level: {"enemy": id, "rank": int}, or {} if none.
static func debut(level: int) -> Dictionary:
	var debuts: Array = _data()["debuts"]
	var index: int = level - int(_data()["first_debut_level"])
	if index < 0 or index >= debuts.size():
		return {}
	var entry: Dictionary = debuts[index]
	return entry


## The most recent debuts up to this level, newest last.
static func newcomers(level: int) -> Array[Dictionary]:
	var debuts: Array = _data()["debuts"]
	var last: int = mini(level - int(_data()["first_debut_level"]), debuts.size() - 1)
	var out: Array[Dictionary] = []
	for index: int in range(maxi(last - int(_data()["newcomer_window"]) + 1, 0), last + 1):
		out.append(debuts[index])
	return out


## What actually spawns when the wave table asks for `wave_enemy`. Rolls are in [0, 1).
static func pick(level: int, wave_enemy: String, share_roll: float, pick_roll: float) -> Dictionary:
	var pool: Array[Dictionary] = newcomers(level)
	if not pool.is_empty() and share_roll < float(_data()["newcomer_share"]):
		return pool[mini(int(pick_roll * pool.size()), pool.size() - 1)]
	return {"enemy": wave_enemy, "rank": base_rank(level)}


static func display_name(enemy_id: String, rank_index: int) -> String:
	var prefix: String = str(rank(rank_index)["name"])
	var base: String = GameData.enemy(enemy_id).display_name
	return base if prefix.is_empty() else "%s %s" % [prefix, base]


## One line for the HUD when a level is reached ("" when nothing changes).
static func announcement(level: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var entry: Dictionary = debut(level)
	if not entry.is_empty():
		parts.append("New creature: %s" % display_name(str(entry["enemy"]), int(entry["rank"])))
	if level > 1 and base_rank(level) > base_rank(level - 1):
		parts.append("The creatures grow stronger")
	return "\n".join(parts)

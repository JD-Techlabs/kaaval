class_name RunState
extends RefCounted
## Everything that belongs to one night. Never touches GameState; the results
## screen turns summary() into committed rewards.

var hero_id: String = ""
var night_id: String = ""
var time: float = 0.0
var level: int = 1
var xp: float = 0.0
var kills: int = 0
var kills_by_type: Dictionary = {}
var bonus_coins: int = 0
var boss_timber: int = 0
var bosses_killed: Array[String] = []
var evolutions_made: int = 0
## id -> level, in the order they were picked up.
var weapons: Dictionary = {}
var passives: Dictionary = {}
## weapon id -> evolution id
var evolved: Dictionary = {}
var rerolls_left: int = 0
var revive_used: bool = false
## Bought life potions drunk this night (taken from the profile at commit).
var potions_used: int = 0
var victory: bool = false
var weapon_slots: int = 4
var passive_slots: int = 4


func add_kill(enemy_id: String) -> void:
	kills += 1
	kills_by_type[enemy_id] = int(kills_by_type.get(enemy_id, 0)) + 1


func summary() -> Dictionary:
	return {
		"hero": hero_id, "night": night_id, "victory": victory, "time": time, "kills": kills,
		"kills_by_type": kills_by_type.duplicate(), "level": level,
		"bonus_coins": bonus_coins, "boss_timber": boss_timber,
		"bosses": bosses_killed.duplicate(), "evolutions": evolutions_made,
		"gifts": GiftLogic.earned_for_level(level), "potions_used": potions_used,
	}

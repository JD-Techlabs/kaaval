extends Node
## The player's persistent profile. Rules for changing it live in scripts/meta;
## this node only stores, reads and saves.

signal changed

## Whole profile as plain JSON-friendly data.
var p: Dictionary = {}
## Test hooks: fixed clock / calendar day.
var time_override: float = -1.0
var date_override: String = ""


func _ready() -> void:
	load_profile()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save()


static func default_profile() -> Dictionary:
	return {
		"coins": 0, "timber": 0, "gems": 0,
		"food": 0, "stone": 0, "knowledge": 0, "oil": 0, "rare_metals": 0,
		"age": "age_founders",
		"lands": [],
		"production": {},
		"potions": 0, "gifts": 0,
		"hero_pieces": {},
		"buildings": {},
		"jobs": [],
		"heroes": ["hero_muthu"],
		"selected_hero": "hero_muthu",
		"skins": [],
		"selected_skins": {},
		"entitlements": [],
		"processed_tokens": [],
		"missions": {"date": "", "list": []},
		"login": {"last_date": "", "day": 0},
		"free_chest": {"next_time": 0, "ad_date": "", "ad_count": 0},
		"achievements": [],
		"stats": {},
		"settings": {
			"music_volume": 0.7, "sfx_volume": 0.9, "haptics": true,
			"damage_numbers": true, "joystick_size": 1.0, "language": "en",
			"debug_overlay": false,
		},
		"runs_played": 0,
		"hints_done": false,
		"how_to_play_seen": false,
		"selected_night": "",
		"nights": {},
		"starter_pack_shown_at": 0,
		"consent_done": false,
	}


func load_profile() -> void:
	p = default_profile()
	_merge(p, SaveManager.load_data())
	changed.emit()


func reset_profile() -> void:
	p = default_profile()
	changed.emit()


static func _merge(into: Dictionary, from: Dictionary) -> void:
	for key: Variant in from.keys():
		var incoming: Variant = from[key]
		if into.has(key) and into[key] is Dictionary and incoming is Dictionary and not (into[key] as Dictionary).is_empty():
			_merge(into[key], incoming)
		else:
			into[key] = incoming


func save() -> void:
	SaveManager.save_data(p)


func now() -> float:
	return time_override if time_override >= 0.0 else Time.get_unix_time_from_system()


## Local calendar day, used for daily resets at 00:00 local time.
func today() -> String:
	return date_override if not date_override.is_empty() else Time.get_date_string_from_system()


# --- currencies -----------------------------------------------------------

func amount(kind: String) -> int:
	return int(p.get(kind, 0))


func add(kind: String, value: int) -> void:
	p[kind] = maxi(amount(kind) + value, 0)
	changed.emit()


func spend(kind: String, value: int) -> bool:
	if value < 0 or amount(kind) < value:
		return false
	p[kind] = amount(kind) - value
	changed.emit()
	return true


const GRANTABLE: Array[String] = ["coins", "timber", "gems", "potions", "gifts", "food", "stone", "knowledge", "oil", "rare_metals"]


## rewards: {kind: n} for any kind in GRANTABLE; other keys are ignored.
func grant(rewards: Dictionary) -> void:
	for kind: String in GRANTABLE:
		if rewards.has(kind):
			p[kind] = amount(kind) + int(rewards[kind])
	changed.emit()


# --- collections ----------------------------------------------------------

func building_level(id: String) -> int:
	var levels: Dictionary = p["buildings"]
	return int(levels.get(id, 0))


func building_levels() -> Dictionary:
	var out: Dictionary = {}
	for data: BuildingData in GameData.buildings():
		out[data.id] = building_level(data.id)
	return out


func has_hero(id: String) -> bool:
	return (p["heroes"] as Array).has(id)


func unlock_hero(id: String) -> void:
	if not has_hero(id):
		(p["heroes"] as Array).append(id)
		changed.emit()


func has_skin(id: String) -> bool:
	return bool(GameData.skin(id).get("default", false)) or (p["skins"] as Array).has(id)


func add_skin(id: String) -> void:
	if not (p["skins"] as Array).has(id):
		(p["skins"] as Array).append(id)
		changed.emit()


func selected_skin(hero_id: String) -> Dictionary:
	var chosen: String = str((p["selected_skins"] as Dictionary).get(hero_id, ""))
	if not chosen.is_empty() and has_skin(chosen):
		return GameData.skin(chosen)
	for entry: Dictionary in GameData.skins():
		if str(entry.get("hero", "")) == hero_id and bool(entry.get("default", false)):
			return entry
	return {}


func has_entitlement(id: String) -> bool:
	return (p["entitlements"] as Array).has(id)


func add_entitlement(id: String) -> void:
	if not has_entitlement(id):
		(p["entitlements"] as Array).append(id)
		changed.emit()


func setting(key: String) -> Variant:
	return (p["settings"] as Dictionary).get(key)


func set_setting(key: String, value: Variant) -> void:
	(p["settings"] as Dictionary)[key] = value
	changed.emit()


# --- lifetime stats -------------------------------------------------------

func stat(key: String) -> int:
	match key:
		"min_building_level":
			var lowest: int = 999
			for data: BuildingData in GameData.buildings():
				lowest = mini(lowest, building_level(data.id))
			return lowest
		"heroes_unlocked":
			return (p["heroes"] as Array).size()
	return int((p["stats"] as Dictionary).get(key, 0))


func add_stat(key: String, value: int) -> void:
	var stats: Dictionary = p["stats"]
	stats[key] = int(stats.get(key, 0)) + value

class_name NightLogic
extends RefCounted
## Nights (stages): their order, which are unlocked, best times, and the
## objective line the HUD shows. Reaching dawn in a night unlocks the next.
## Progress lives in GameState.p["nights"] = {night_id: {"best_time", "won"}}.


static func nights() -> Array[WaveData]:
	return GameData.waves()


static func night(id: String) -> WaveData:
	return GameData.wave(id)


## 1-based position in the night list, 0 if unknown.
static func number(id: String) -> int:
	var list: Array[WaveData] = nights()
	for i: int in list.size():
		if list[i].id == id:
			return i + 1
	return 0


static func _progress(id: String) -> Dictionary:
	var all: Dictionary = GameState.p["nights"]
	var entry: Dictionary = all.get(id, {})
	return entry


static func won(id: String) -> bool:
	return bool(_progress(id).get("won", false))


static func best_time(id: String) -> float:
	return float(_progress(id).get("best_time", 0.0))


static func is_unlocked(id: String) -> bool:
	var index: int = number(id) - 1
	if index < 0:
		return false
	return index == 0 or won(nights()[index - 1].id)


## The night after `id`, or null for the last one.
static func next_night(id: String) -> WaveData:
	var index: int = number(id)
	var list: Array[WaveData] = nights()
	return list[index] if index > 0 and index < list.size() else null


## The chosen night if it is unlocked, otherwise the latest unlocked one.
static func selected() -> WaveData:
	var chosen: String = str(GameState.p.get("selected_night", ""))
	if is_unlocked(chosen):
		return night(chosen)
	var latest: WaveData = nights()[0]
	for wave: WaveData in nights():
		if is_unlocked(wave.id):
			latest = wave
	return latest


static func select(id: String) -> bool:
	if not is_unlocked(id):
		return false
	GameState.p["selected_night"] = id
	return true


## The night this run would unlock if committed, or "" (shown on the results screen).
static func unlocks_after(summary: Dictionary) -> String:
	var id: String = str(summary.get("night", ""))
	var next: WaveData = next_night(id)
	if not bool(summary.get("victory", false)) or next == null or is_unlocked(next.id):
		return ""
	return next.id


## Records a finished night. Returns the id of a newly unlocked night (now selected), or "".
static func record_run(summary: Dictionary) -> String:
	var id: String = str(summary.get("night", ""))
	if number(id) == 0:
		return ""
	var unlocked: String = unlocks_after(summary)
	var all: Dictionary = GameState.p["nights"]
	var entry: Dictionary = all.get(id, {})
	entry["best_time"] = maxf(float(entry.get("best_time", 0.0)), float(summary.get("time", 0.0)))
	entry["won"] = bool(entry.get("won", false)) or bool(summary.get("victory", false))
	all[id] = entry
	if not unlocked.is_empty():
		GameState.p["selected_night"] = unlocked
	return unlocked


## Boss events in time order: [{"time", "id"}].
static func bosses(wave: WaveData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in wave.events:
		if str(event["type"]) == "boss":
			out.append({"time": float(event["time"]), "id": str(event["id"])})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time"]) < float(b["time"]))
	return out


## The first boss still to come after `time`, or {}.
static func next_boss(wave: WaveData, time: float) -> Dictionary:
	for entry: Dictionary in bosses(wave):
		if float(entry["time"]) > time:
			return entry
	return {}


## "Thorn Queen 5:00 · Banyan Wraith 10:00 · Eclipse Beast 14:30"
static func boss_schedule(wave: WaveData) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for entry: Dictionary in bosses(wave):
		parts.append("%s %s" % [GameData.boss(str(entry["id"])).display_name, clock(float(entry["time"]))])
	return " · ".join(parts)


## The one-line goal under the run timer. `boss_name` is the living boss, or "".
static func objective(wave: WaveData, time: float, boss_name: String) -> String:
	var to_dawn: float = maxf(wave.duration - time, 0.0)
	var dawn_text: String = "Dawn in %s" % clock(to_dawn)
	var hold_seconds: float = GameData.num("objective", "hold_on_seconds")
	if to_dawn <= hold_seconds:
		return "Hold on! %s" % dawn_text
	if not boss_name.is_empty():
		return "Defeat the %s! · %s" % [boss_name, dawn_text]
	var next: Dictionary = next_boss(wave, time)
	if next.is_empty():
		return "Survive! %s" % dawn_text
	return "Survive to dawn · Boss in %s" % clock(float(next["time"]) - time)


## 75.0 -> "1:15" (rounded up so a countdown never shows 0:00 early).
static func clock(seconds: float) -> String:
	var total: int = maxi(ceili(seconds - 0.001), 0)
	@warning_ignore("integer_division")
	return "%d:%02d" % [total / 60, total % 60]

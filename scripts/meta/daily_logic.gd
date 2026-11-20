class_name DailyLogic
extends RefCounted
## Daily missions, the 7-day login calendar and achievements (spec §8.5).


static func _config() -> Dictionary:
	return GameData.json("missions")


# --- daily missions -------------------------------------------------------

static func mission_def(id: String) -> Dictionary:
	for entry: Dictionary in _config()["daily_pool"]:
		if str(entry["id"]) == id:
			return entry
	return {}


## Picks today's missions (same for the whole local day) if the day changed.
static func ensure_today() -> void:
	var state: Dictionary = GameState.p["missions"]
	var today: String = GameState.today()
	if str(state["date"]) == today:
		return
	var pool: Array = (_config()["daily_pool"] as Array).duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(today)
	var list: Array = []
	for i: int in int(_config()["daily_count"]):
		if pool.is_empty():
			break
		var entry: Dictionary = pool.pop_at(rng.randi() % pool.size())
		list.append({"id": str(entry["id"]), "progress": 0, "claimed": false})
	state["date"] = today
	state["list"] = list


## [{"id","progress","claimed"}] for today.
static func missions() -> Array:
	ensure_today()
	var list: Array = (GameState.p["missions"] as Dictionary)["list"]
	return list


## Stat values a finished run contributes to missions and lifetime stats.
static func run_stats(summary: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"kills": int(summary["kills"]),
		"minutes": int(float(summary["time"]) / 60.0),
		"evolutions": int(summary["evolutions"]),
		"bosses": (summary["bosses"] as Array).size(),
		"level": int(summary["level"]),
		"runs": 1,
		"dawns": 1 if bool(summary["victory"]) else 0,
	}
	var by_type: Dictionary = summary["kills_by_type"]
	for id: String in by_type.keys():
		out["kills_" + id] = int(by_type[id])
	return out


static func record_run(summary: Dictionary) -> void:
	var stats: Dictionary = run_stats(summary)
	for entry: Dictionary in missions():
		var def: Dictionary = mission_def(str(entry["id"]))
		var value: int = int(stats.get(str(def.get("stat", "")), 0))
		if str(def.get("mode", "sum")) == "max":
			entry["progress"] = maxi(int(entry["progress"]), value)
		else:
			entry["progress"] = int(entry["progress"]) + value
	for key: String in stats.keys():
		if key != "minutes" and key != "level":
			GameState.add_stat(key, int(stats[key]))


static func mission_complete(entry: Dictionary) -> bool:
	return int(entry["progress"]) >= int(mission_def(str(entry["id"])).get("target", 1))


static func claim_mission(index: int) -> bool:
	var list: Array = missions()
	if index < 0 or index >= list.size():
		return false
	var entry: Dictionary = list[index]
	if bool(entry["claimed"]) or not mission_complete(entry):
		return false
	entry["claimed"] = true
	GameState.grant({"coins": int(mission_def(str(entry["id"])).get("coins", 0)),
		"gems": int(GameData.num("economy", "mission_reward_gems"))})
	Analytics.log_event("mission_complete", {"id": str(entry["id"])})
	GameState.save()
	return true


# --- login calendar -------------------------------------------------------

static func calendar() -> Array:
	var list: Array = _config()["login_calendar"]
	return list


## Index (0-based) of the next day to claim in the 7-day loop.
static func login_day_index() -> int:
	return int((GameState.p["login"] as Dictionary)["day"]) % calendar().size()


static func login_available() -> bool:
	return str((GameState.p["login"] as Dictionary)["last_date"]) != GameState.today()


static func claim_login() -> Dictionary:
	if not login_available():
		return {}
	var login: Dictionary = GameState.p["login"]
	var entry: Dictionary = calendar()[login_day_index()]
	var rewards: Dictionary = entry["rewards"]
	login["last_date"] = GameState.today()
	login["day"] = int(login["day"]) + 1
	GameState.grant(rewards)
	GameState.save()
	return rewards


# --- achievements ---------------------------------------------------------

static func achievements() -> Array:
	var list: Array = _config()["achievements"]
	return list


static func achievement_done(def: Dictionary) -> bool:
	return GameState.stat(str(def["stat"])) >= int(def["target"])


static func achievement_claimed(id: String) -> bool:
	return (GameState.p["achievements"] as Array).has(id)


static func claim_achievement(id: String) -> bool:
	for def: Dictionary in achievements():
		if str(def["id"]) == id:
			if achievement_claimed(id) or not achievement_done(def):
				return false
			(GameState.p["achievements"] as Array).append(id)
			GameState.grant({"gems": int(def["gems"])})
			GameState.save()
			return true
	return false


## True when anything on the Missions screen can be claimed (nav badge).
static func anything_claimable() -> bool:
	if login_available():
		return true
	for entry: Dictionary in missions():
		if not bool(entry["claimed"]) and mission_complete(entry):
			return true
	for def: Dictionary in achievements():
		if achievement_done(def) and not achievement_claimed(str(def["id"])):
			return true
	return false

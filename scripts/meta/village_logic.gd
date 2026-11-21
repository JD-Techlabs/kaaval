class_name VillageLogic
extends RefCounted
## Building upgrades (spec §8.3). Timers are wall-clock UTC timestamps, so
## they keep running while the app is closed.
## Job: {"id": building id, "finish": unix seconds}


static func jobs() -> Array:
	var list: Array = GameState.p["jobs"]
	return list


static func job_for(id: String) -> Dictionary:
	for job: Dictionary in jobs():
		if str(job["id"]) == id:
			return job
	return {}


static func remaining(job: Dictionary) -> float:
	return maxf(float(job.get("finish", 0.0)) - GameState.now(), 0.0)


static func builder_slots() -> int:
	return Economy.builder_slots(GameState.has_entitlement("builder_2"))


static func total_level() -> int:
	var total: int = 0
	for data: BuildingData in GameData.buildings():
		total += GameState.building_level(data.id)
	return total


## "" when the upgrade can start, otherwise a short reason for the UI.
static func blocker(id: String) -> String:
	var data: BuildingData = GameData.building(id)
	var target: int = GameState.building_level(id) + 1
	if target > data.max_level:
		return "Max level"
	if target > AgeLogic.building_cap():
		return "Next age needed"
	if not job_for(id).is_empty():
		return "Upgrading"
	if Economy.build_seconds(target, 1.0) > 0.0 and jobs().size() >= builder_slots():
		return "Builder busy"
	if GameState.amount("coins") < Economy.building_coin_cost(target):
		return "Not enough coins"
	if GameState.amount("timber") < Economy.building_timber_cost(target):
		return "Not enough timber"
	return ""


static func start(id: String) -> bool:
	if not blocker(id).is_empty():
		return false
	var target: int = GameState.building_level(id) + 1
	GameState.spend("coins", Economy.building_coin_cost(target))
	GameState.spend("timber", Economy.building_timber_cost(target))
	var seconds: float = Economy.build_seconds(target, RemoteConfig.num("build_timer_multiplier"))
	if seconds <= 0.0:
		_finish(id)
	else:
		jobs().append({"id": id, "finish": GameState.now() + seconds})
	GameState.save()
	GameState.changed.emit()
	return true


## Completes every job whose time has passed. Returns the finished building ids.
static func complete_due() -> Array[String]:
	var done: Array[String] = []
	var list: Array = jobs()
	for i: int in range(list.size() - 1, -1, -1):
		var job: Dictionary = list[i]
		if remaining(job) <= 0.0:
			list.remove_at(i)
			_finish(str(job["id"]))
			done.append(str(job["id"]))
	if not done.is_empty():
		GameState.save()
		GameState.changed.emit()
	return done


static func skip_cost(id: String) -> int:
	return Economy.skip_gems(remaining(job_for(id)))


static func skip(id: String) -> bool:
	var job: Dictionary = job_for(id)
	if job.is_empty() or not GameState.spend("gems", skip_cost(id)):
		return false
	jobs().erase(job)
	_finish(id)
	GameState.save()
	GameState.changed.emit()
	return true


static func _finish(id: String) -> void:
	var levels: Dictionary = GameState.p["buildings"]
	levels[id] = GameState.building_level(id) + 1
	Analytics.log_event("building_upgrade", {"id": id, "level": int(levels[id])})

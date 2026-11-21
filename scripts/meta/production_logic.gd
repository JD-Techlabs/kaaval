class_name ProductionLogic
extends RefCounted
## Buildings that make resources over real time (wall clock, so it keeps
## going while the app is closed). Each producer stores up to `storage_hours`
## of output until collected. GameState.p["production"] = {building_id: unix
## time production is counted from}.


static func _clock() -> Dictionary:
	var clock: Dictionary = GameState.p["production"]
	return clock


## Village-wide production bonus (AI Lab and any other "production_mult" building).
static func production_mult() -> float:
	var bonus: float = 0.0
	for data: BuildingData in GameData.buildings():
		if data.stat == "production_mult":
			bonus += data.bonus_at(GameState.building_level(data.id))
	return 1.0 + bonus


## Producing now: built, on owned land, and its resource is open in this age.
static func is_active(data: BuildingData) -> bool:
	return not data.produces.is_empty() and GameState.building_level(data.id) > 0 \
		and LandLogic.owned(data.land) and AgeLogic.open_resources().has(data.produces)


## Units per hour at the building's current level, with the village bonus.
static func rate(data: BuildingData) -> float:
	return data.production_at(GameState.building_level(data.id)) * production_mult()


static func capacity(data: BuildingData) -> int:
	return floori(rate(data) * data.storage_hours)


## Whole units waiting to be collected.
static func ready(data: BuildingData) -> int:
	if not is_active(data) or not _clock().has(data.id):
		return 0
	var hours: float = maxf(GameState.now() - float(_clock()[data.id]), 0.0) / 3600.0
	return mini(floori(rate(data) * hours), capacity(data))


## Starts the clock for a producer that has none (first built, or just opened).
static func start_clock(data: BuildingData) -> void:
	if not data.produces.is_empty() and not _clock().has(data.id):
		_clock()[data.id] = GameState.now()


## Collects one building. Returns the amount granted. Leftover part-units
## keep counting; a full store restarts from now.
static func collect(data: BuildingData) -> int:
	if not is_active(data):
		return 0
	start_clock(data)
	var amount: int = ready(data)
	if amount <= 0:
		return 0
	if amount >= capacity(data):
		_clock()[data.id] = GameState.now()
	else:
		_clock()[data.id] = float(_clock()[data.id]) + float(amount) / rate(data) * 3600.0
	GameState.grant({data.produces: amount})
	return amount


## Collects every producer. Returns {kind: amount} of what was granted.
static func collect_all() -> Dictionary:
	var out: Dictionary = {}
	for data: BuildingData in GameData.buildings():
		var amount: int = collect(data)
		if amount > 0:
			out[data.produces] = int(out.get(data.produces, 0)) + amount
	if not out.is_empty():
		GameState.save()
	return out


## Total units waiting across the village.
static func total_ready() -> int:
	var total: int = 0
	for data: BuildingData in GameData.buildings():
		total += ready(data)
	return total


## Producers whose resource is not open yet start their clock when it opens,
## so the first collection after an age change is not empty forever.
static func sync_clocks() -> void:
	for data: BuildingData in GameData.buildings():
		if is_active(data):
			start_clock(data)

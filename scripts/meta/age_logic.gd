class_name AgeLogic
extends RefCounted
## Village ages: which age the player is in, what the next one needs, and
## advancing. The current age id lives in GameState.p["age"].


static func ages() -> Array[AgeData]:
	return GameData.ages()


static func age(id: String) -> AgeData:
	return GameData.age(id)


## 1-based position in the age list, 0 if unknown.
static func number(id: String) -> int:
	var list: Array[AgeData] = ages()
	for i: int in list.size():
		if list[i].id == id:
			return i + 1
	return 0


## The player's age; an unknown or missing id falls back to the first age.
static func current() -> AgeData:
	var found: AgeData = age(str(GameState.p.get("age", "")))
	return found if found != null else ages()[0]


## The age after the current one, or null in the last age.
static func next_age() -> AgeData:
	var index: int = number(current().id)
	var list: Array[AgeData] = ages()
	return list[index] if index < list.size() else null


## Every resource kind used by any age, in the order of data/balance.json "resources".
static func resource_kinds() -> Array[String]:
	var out: Array[String] = []
	out.assign(GameData.balance("resources").keys())
	return out


## Resources the current age pays out.
static func open_resources() -> Array[String]:
	return current().resources


## Highest level any building may reach right now.
static func building_cap() -> int:
	return current().building_cap


## Unmet building requirements for `target`: [{"id", "need", "have"}].
static func missing_buildings(target: AgeData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in target.required_buildings.keys():
		var need: int = int(target.required_buildings[id])
		var have: int = GameState.building_level(id)
		if have < need:
			out.append({"id": id, "need": need, "have": have})
	return out


## Unpaid resource costs for `target`: [{"kind", "need", "have"}].
static func missing_resources(target: AgeData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for kind: String in target.advance_cost.keys():
		var need: int = int(target.advance_cost[kind])
		var have: int = GameState.amount(kind)
		if have < need:
			out.append({"kind": kind, "need": need, "have": have})
	return out


## "" when the next age can be reached, otherwise a short reason for the UI.
static func blocker() -> String:
	var target: AgeData = next_age()
	if target == null:
		return "Final age"
	if not missing_buildings(target).is_empty():
		return "Upgrade buildings"
	if not missing_resources(target).is_empty():
		return "Need resources"
	return ""


static func advance() -> bool:
	if not blocker().is_empty():
		return false
	var target: AgeData = next_age()
	for kind: String in target.advance_cost.keys():
		GameState.spend(kind, int(target.advance_cost[kind]))
	GameState.p["age"] = target.id
	ProductionLogic.sync_clocks()
	Analytics.log_event("age_advance", {"age": target.id})
	GameState.save()
	GameState.changed.emit()
	return true


## Resources a finished run pays: {kind: amount}. `age_id` is the age the run was played in.
## Timber is not included; it keeps its own boss + dawn formula (RunCommit.timber_for).
## `bonus` is the hero's {kind: fraction} on top.
static func run_resources(age_id: String, seconds: float, victory: bool, bosses: int, night_mult: float,
		bonus: Dictionary = {}) -> Dictionary:
	var played: AgeData = age(age_id)
	if played == null:
		played = ages()[0]
	var out: Dictionary = {}
	for kind: String in played.resources:
		var rates: Dictionary = GameData.balance("resources").get(kind, {})
		if rates.is_empty():
			continue
		var base: float = seconds / 60.0 * float(rates.get("per_minute", 0.0)) + bosses * float(rates.get("per_boss", 0.0))
		if victory:
			base += float(rates.get("dawn", 0.0))
		var value: int = roundi(base * played.resource_mult * night_mult * (1.0 + float(bonus.get(kind, 0.0))))
		if value > 0:
			out[kind] = value
	return out

class_name LandLogic
extends RefCounted
## Land around the village: bought with coins once the village reaches the
## land's age. Owned land ids live in GameState.p["lands"].


static func owned(id: String) -> bool:
	var data: LandData = GameData.land(id)
	if data == null:
		return false
	return data.coin_cost <= 0 or (GameState.p["lands"] as Array).has(id)


static func age_reached(data: LandData) -> bool:
	return AgeLogic.number(AgeLogic.current().id) >= AgeLogic.number(data.required_age)


## "" when the land can be bought, otherwise a short reason for the UI.
static func blocker(id: String) -> String:
	var data: LandData = GameData.land(id)
	if data == null:
		return "Unknown land"
	if owned(id):
		return "Owned"
	if not age_reached(data):
		return "Needs " + AgeLogic.age(data.required_age).display_name
	if GameState.amount("coins") < data.coin_cost:
		return "Not enough coins"
	return ""


static func buy(id: String) -> bool:
	if not blocker(id).is_empty():
		return false
	GameState.spend("coins", GameData.land(id).coin_cost)
	(GameState.p["lands"] as Array).append(id)
	Analytics.log_event("land_buy", {"id": id})
	GameState.save()
	GameState.changed.emit()
	return true


static func buildings_on(id: String) -> Array[BuildingData]:
	var out: Array[BuildingData] = []
	for data: BuildingData in GameData.buildings():
		if data.land == id:
			out.append(data)
	return out

class_name ChestLogic
extends RefCounted
## Random chests (spec §8.5, §9.4). The odds shown in-game come from odds(),
## which reads the very same weights that roll() uses.


static func config(chest_id: String) -> Dictionary:
	var data: Dictionary = GameData.json("chests").get(chest_id, {})
	return data


## [{"label": String, "percent": float}] — rendered in the chest info panel.
static func odds(chest_id: String) -> Array[Dictionary]:
	var drops: Array = config(chest_id).get("drops", [])
	var total: float = 0.0
	for drop: Dictionary in drops:
		total += float(drop["weight"])
	var out: Array[Dictionary] = []
	for drop: Dictionary in drops:
		out.append({"label": str(drop["label"]), "percent": float(drop["weight"]) / total * 100.0})
	return out


## The odds as display lines, one per drop.
static func odds_text(chest_id: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for entry: Dictionary in odds(chest_id):
		lines.append("%s — %s%%" % [str(entry["label"]), String.num(float(entry["percent"]), 1)])
	return "\n".join(lines)


static func roll(chest_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var drops: Array = config(chest_id).get("drops", [])
	var total: float = 0.0
	for drop: Dictionary in drops:
		total += float(drop["weight"])
	var value: float = rng.randf() * total
	for drop: Dictionary in drops:
		value -= float(drop["weight"])
		if value < 0.0:
			return drop
	var last: Dictionary = drops[drops.size() - 1]
	return last


static func _open(chest_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var drop: Dictionary = roll(chest_id, rng)
	var rewards: Dictionary = drop["rewards"]
	GameState.grant(rewards)
	GameState.save()
	return drop


# --- free chest -----------------------------------------------------------

static func _free() -> Dictionary:
	var data: Dictionary = GameState.p["free_chest"]
	return data


static func free_remaining() -> float:
	return maxf(float(_free()["next_time"]) - GameState.now(), 0.0)


## Returns the drop, or {} when the chest is still on cooldown.
static func open_free(rng: RandomNumberGenerator) -> Dictionary:
	if free_remaining() > 0.0:
		return {}
	_free()["next_time"] = GameState.now() + RemoteConfig.num("free_chest_hours") * 3600.0
	return _open("free_chest", rng)


static func ad_opens_left() -> int:
	var data: Dictionary = _free()
	var used: int = int(data["ad_count"]) if str(data["ad_date"]) == GameState.today() else 0
	return maxi(int(config("free_chest").get("ad_extra_per_day", 0)) - used, 0)


## Call after the rewarded ad completed. Returns {} when the daily cap is hit.
static func open_free_from_ad(rng: RandomNumberGenerator) -> Dictionary:
	if ad_opens_left() <= 0:
		return {}
	var data: Dictionary = _free()
	if str(data["ad_date"]) != GameState.today():
		data["ad_date"] = GameState.today()
		data["ad_count"] = 0
	data["ad_count"] = int(data["ad_count"]) + 1
	return _open("free_chest", rng)


# --- guardian chest -------------------------------------------------------

static func guardian_price() -> int:
	return int(config("guardian_chest").get("price_gems", 0))


static func buy_guardian(rng: RandomNumberGenerator) -> Dictionary:
	if not GameState.spend("gems", guardian_price()):
		return {}
	return _open("guardian_chest", rng)

class_name WeaponLine
extends RefCounted
## Turns a hero's starting weapon into its tier for the village's age: new
## name, icon, sprite, more power and extra params, plus called-in strikes.
## Pure lookups over data; the run and the UI use the same tiered weapon.

static var _cache: Dictionary = {}


static func line(hero_id: String) -> WeaponLineData:
	return GameData.weapon_line(hero_id)


## The tier for `hero_id` in `age_id` (clamped to the line), or {} when the hero has no line.
static func tier(hero_id: String, age_id: String) -> Dictionary:
	var data: WeaponLineData = line(hero_id)
	if data == null or data.tiers.is_empty():
		return {}
	var index: int = clampi(AgeLogic.number(age_id) - 1, 0, data.tiers.size() - 1)
	return data.tiers[index]


## A copy of the base weapon with the tier applied.
static func apply(base: WeaponData, tier_data: Dictionary) -> WeaponData:
	var out: WeaponData = base.duplicate(true) as WeaponData
	out.display_name = str(tier_data.get("name", base.display_name))
	out.description = str(tier_data.get("desc", base.description))
	out.icon = str(tier_data.get("icon", base.icon))
	out.sprite = str(tier_data.get("sprite", base.sprite))
	out.power = base.power * float(tier_data.get("power", 1.0))
	var add: Dictionary = tier_data.get("add", {})
	for key: String in add.keys():
		out.params[key] = float(out.params.get(key, 0.0)) + float(add[key])
	return out


## The weapon as `hero_id` wields it in `age_id`: tiered for the starting weapon, plain otherwise.
static func weapon_for(id: String, hero_id: String = "", age_id: String = "") -> WeaponData:
	if hero_id.is_empty():
		hero_id = str(GameState.p.get("selected_hero", ""))
	if age_id.is_empty():
		age_id = AgeLogic.current().id
	var base: WeaponData = GameData.weapon(id)
	var hero: HeroData = GameData.hero(hero_id)
	if base == null or hero == null or hero.starting_weapon != id:
		return base
	var tier_data: Dictionary = tier(hero_id, age_id)
	if tier_data.is_empty():
		return base
	var key: String = "%s|%s|%s" % [hero_id, age_id, id]
	if not _cache.has(key):
		_cache[key] = apply(base, tier_data)
	var cached: WeaponData = _cache[key]
	return cached


## Called-in strikes for the hero in this age.
static func strikes(hero_id: String, age_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(tier(hero_id, age_id).get("strikes", []))
	return out

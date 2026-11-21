class_name GameData
extends RefCounted
## Static registry for everything under res://data. Loads lazily and caches.

static var _json_cache: Dictionary = {}
static var _dir_cache: Dictionary = {}


static func json(name: String) -> Dictionary:
	if not _json_cache.has(name):
		_json_cache[name] = _load_json("res://data/%s.json" % name)
	var data: Dictionary = _json_cache[name]
	return data


static func balance(section: String) -> Dictionary:
	var data: Dictionary = json("balance").get(section, {})
	return data


static func num(section: String, key: String) -> float:
	return float(balance(section).get(key, 0.0))


## JSON.parse_string logs an engine error on bad input; this stays quiet and returns null.
static func parse_json(text: String) -> Variant:
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("GameData: missing %s" % path)
		return {}
	var parsed: Variant = parse_json(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		var data: Dictionary = parsed
		return data
	push_error("GameData: %s is not a JSON object" % path)
	return {}


static func _dir(folder: String) -> Dictionary:
	if _dir_cache.has(folder):
		var cached: Dictionary = _dir_cache[folder]
		return cached
	var out: Dictionary = {}
	var base: String = "res://data/%s" % folder
	var files: PackedStringArray = ResourceLoader.list_directory(base)
	files.sort()
	for file: String in files:
		if not file.ends_with(".tres"):
			continue
		var res: Resource = load("%s/%s" % [base, file])
		if res != null:
			out[str(res.get("id"))] = res
	_dir_cache[folder] = out
	return out


static func _sorted(folder: String) -> Array:
	var list: Array = _dir(folder).values()
	list.sort_custom(func(a: Resource, b: Resource) -> bool:
		return int(a.get("sort_order")) < int(b.get("sort_order")))
	return list


static func weapon(id: String) -> WeaponData:
	return _dir("weapons").get(id) as WeaponData


static func weapons() -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	out.assign(_sorted("weapons"))
	return out


static func passive(id: String) -> PassiveData:
	return _dir("passives").get(id) as PassiveData


static func passives() -> Array[PassiveData]:
	var out: Array[PassiveData] = []
	out.assign(_sorted("passives"))
	return out


static func evolutions() -> Array[EvolutionData]:
	var out: Array[EvolutionData] = []
	out.assign(_dir("evolutions").values())
	return out


static func evolution(id: String) -> EvolutionData:
	return _dir("evolutions").get(id) as EvolutionData


static func hero(id: String) -> HeroData:
	return _dir("heroes").get(id) as HeroData


static func heroes() -> Array[HeroData]:
	var out: Array[HeroData] = []
	out.assign(_sorted("heroes"))
	return out


static func enemy(id: String) -> EnemyData:
	return _dir("enemies").get(id) as EnemyData


static func enemies() -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	out.assign(_dir("enemies").values())
	out.append_array(_dir("bosses").values())
	return out


static func boss(id: String) -> BossData:
	return _dir("bosses").get(id) as BossData


static func wave(id: String) -> WaveData:
	return _dir("waves").get(id) as WaveData


## Every night, in play order.
static func waves() -> Array[WaveData]:
	var out: Array[WaveData] = []
	out.assign(_sorted("waves"))
	return out


static func building(id: String) -> BuildingData:
	return _dir("buildings").get(id) as BuildingData


static func buildings() -> Array[BuildingData]:
	var out: Array[BuildingData] = []
	out.assign(_sorted("buildings"))
	return out


static func age(id: String) -> AgeData:
	return _dir("ages").get(id) as AgeData


## Every age, in order.
static func ages() -> Array[AgeData]:
	var out: Array[AgeData] = []
	out.assign(_sorted("ages"))
	return out


static func land(id: String) -> LandData:
	return _dir("lands").get(id) as LandData


## Every piece of land, in map order (village green first).
static func lands() -> Array[LandData]:
	var out: Array[LandData] = []
	out.assign(_sorted("lands"))
	return out


static func product(id: String) -> Dictionary:
	var list: Array = json("products").get("products", [])
	for entry: Dictionary in list:
		if str(entry.get("id", "")) == id:
			return entry
	return {}


static func skins() -> Array:
	var list: Array = json("products").get("skins", [])
	return list


static func skin(id: String) -> Dictionary:
	for entry: Dictionary in skins():
		if str(entry.get("id", "")) == id:
			return entry
	return {}

extends Node
## Versioned JSON save: atomic write (temp + rename) and a checksum that
## catches casual edits. A bad or tampered file falls back to a fresh profile.

const SAVE_VERSION: int = 1
const DEFAULT_PATH: String = "user://save.json"
const _SALT: String = "kaaval-lamp-7f3a"

## Overridable so tests never touch the real save.
var path: String = DEFAULT_PATH
var last_load_was_corrupt: bool = false


func save_data(data: Dictionary) -> bool:
	var payload: String = JSON.stringify({"save_version": SAVE_VERSION, "data": data})
	var wrapper: String = JSON.stringify({"checksum": checksum(payload), "payload": payload})
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot open %s" % tmp_path)
		return false
	file.store_string(wrapper)
	file.close()
	var err: Error = DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		push_error("SaveManager: rename failed (%d)" % err)
		return false
	return true


## Returns the saved profile data, or {} when there is no usable save.
func load_data() -> Dictionary:
	last_load_was_corrupt = false
	if not FileAccess.file_exists(path):
		return {}
	var wrapper: Variant = GameData.parse_json(FileAccess.get_file_as_string(path))
	if not wrapper is Dictionary:
		return _corrupt()
	var wrapper_dict: Dictionary = wrapper
	var payload: String = str(wrapper_dict.get("payload", ""))
	if payload.is_empty() or str(wrapper_dict.get("checksum", "")) != checksum(payload):
		return _corrupt()
	var parsed: Variant = GameData.parse_json(payload)
	if not parsed is Dictionary:
		return _corrupt()
	var envelope: Dictionary = parsed
	var data: Variant = envelope.get("data", {})
	if not data is Dictionary:
		return _corrupt()
	var data_dict: Dictionary = data
	return migrate(data_dict, int(envelope.get("save_version", 0)))


func checksum(payload: String) -> String:
	return (payload + _SALT).sha256_text()


## Upgrades data written by an older build, one version at a time.
func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var version: int = from_version
	while version < SAVE_VERSION:
		match version:
			0:
				data = _migrate_0_to_1(data)
		version += 1
	return data


## v0 (pre-release builds) stored settings at the top level and had no stats.
func _migrate_0_to_1(data: Dictionary) -> Dictionary:
	var settings: Dictionary = data.get("settings", {})
	for key: String in ["music_volume", "sfx_volume", "haptics", "damage_numbers", "joystick_size"]:
		if data.has(key):
			settings[key] = data[key]
			data.erase(key)
	data["settings"] = settings
	if not data.has("stats"):
		data["stats"] = {}
	return data


func _corrupt() -> Dictionary:
	last_load_was_corrupt = true
	push_warning("SaveManager: save file unreadable, starting fresh")
	DirAccess.copy_absolute(path, path + ".corrupt")
	return {}


func delete_save() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

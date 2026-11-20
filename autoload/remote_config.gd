extends Node
## Remote tunables: bundled defaults -> cached copy -> freshly fetched JSON.
## Only keys that exist in the bundled defaults are accepted, with matching type.

signal updated

const CACHE_PATH: String = "user://remote_config.json"

var _values: Dictionary = {}
var _request: HTTPRequest


func _ready() -> void:
	_values = GameData.json("remote_config_defaults").duplicate(true)
	if FileAccess.file_exists(CACHE_PATH):
		apply_json_text(FileAccess.get_file_as_string(CACHE_PATH))
	fetch()


func fetch() -> void:
	var app: Dictionary = GameData.json("app_config")
	var url: String = str(app.get("remote_config_url", ""))
	if url.is_empty() or _request != null:
		return
	_request = HTTPRequest.new()
	_request.timeout = float(app.get("remote_config_timeout", 3.0))
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	if _request.request(url) != OK:
		_clear_request()


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_clear_request()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var text: String = body.get_string_from_utf8()
	if apply_json_text(text):
		var file: FileAccess = FileAccess.open(CACHE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(text)
			file.close()


func _clear_request() -> void:
	if _request != null:
		_request.queue_free()
		_request = null


## Returns true when the text was a JSON object (unknown keys are ignored).
func apply_json_text(text: String) -> bool:
	var parsed: Variant = GameData.parse_json(text)
	if not parsed is Dictionary:
		return false
	var incoming: Dictionary = parsed
	apply_overrides(incoming)
	return true


func apply_overrides(incoming: Dictionary) -> void:
	for key: String in incoming.keys():
		if not _values.has(key):
			continue
		var current: Variant = _values[key]
		var value: Variant = incoming[key]
		var both_numbers: bool = (current is float or current is int) and (value is float or value is int)
		if both_numbers or typeof(current) == typeof(value):
			_values[key] = value
	updated.emit()


func reset_to_defaults() -> void:
	_values = GameData.json("remote_config_defaults").duplicate(true)
	updated.emit()


func num(key: String) -> float:
	return float(_values.get(key, 0.0))


func flag(key: String) -> bool:
	return bool(_values.get(key, false))

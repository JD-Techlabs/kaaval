extends Node
## Event logging facade (spec §14). Ships with a thin local logger; a real
## backend can be attached with set_sink() without touching call sites.

const MAX_BUFFER: int = 200

var _sink: Callable = Callable()
var _buffer: Array[Dictionary] = []


func _ready() -> void:
	log_event("app_open")


## sink signature: func(event_name: String, params: Dictionary) -> void
func set_sink(sink: Callable) -> void:
	_sink = sink


func log_event(event_name: String, params: Dictionary = {}) -> void:
	_buffer.append({"name": event_name, "params": params, "time": Time.get_unix_time_from_system()})
	if _buffer.size() > MAX_BUFFER:
		_buffer.pop_front()
	if _sink.is_valid():
		_sink.call(event_name, params)
	elif OS.is_debug_build() and not OS.has_feature("headless") and DisplayServer.get_name() != "headless":
		print("[analytics] ", event_name, " ", params)


func recent_events() -> Array[Dictionary]:
	return _buffer

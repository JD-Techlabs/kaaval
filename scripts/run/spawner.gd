class_name Spawner
extends RefCounted
## Turns the wave table into spawn requests. Knows nothing about nodes, so the
## timeline can be tested directly.
## Request: {"type": "enemy"|"boss"|"ring"|"crow_line", "id": String, "count": int}

var wave: WaveData
var _accum: float = 0.0
var _crow_timer: float = 0.0
var _fired: Dictionary = {}


func _init(p_wave: WaveData) -> void:
	wave = p_wave


static func segment_at(p_wave: WaveData, time: float) -> Dictionary:
	for segment: Dictionary in p_wave.segments:
		if time >= float(segment["start"]) and time < float(segment["end"]):
			return segment
	return {}


static func rate_at(p_wave: WaveData, time: float) -> float:
	return float(segment_at(p_wave, time).get("rate", 0.0))


## Normalised enemy mix at a time: {enemy_id: fraction 0..1}
static func mix_at(p_wave: WaveData, time: float) -> Dictionary:
	var mix: Dictionary = segment_at(p_wave, time).get("mix", {})
	var total: float = 0.0
	for id: String in mix.keys():
		total += float(mix[id])
	var out: Dictionary = {}
	if total > 0.0:
		for id: String in mix.keys():
			out[id] = float(mix[id]) / total
	return out


## roll in [0, 1)
static func pick_enemy(mix: Dictionary, roll: float) -> String:
	var last: String = ""
	for id: String in mix.keys():
		last = id
		roll -= float(mix[id])
		if roll < 0.0:
			return id
	return last


func step(delta: float, time: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	for i: int in wave.events.size():
		var event: Dictionary = wave.events[i]
		if not _fired.has(i) and time >= float(event["time"]):
			_fired[i] = true
			requests.append({"type": str(event["type"]), "id": str(event["id"]), "count": int(event["count"])})
	var segment: Dictionary = segment_at(wave, time)
	if segment.is_empty():
		return requests
	_accum += float(segment["rate"]) * delta
	if _accum >= 1.0:
		var mix: Dictionary = mix_at(wave, time)
		while _accum >= 1.0:
			_accum -= 1.0
			requests.append({"type": "enemy", "id": pick_enemy(mix, rng.randf()), "count": 1})
	var crow_interval: float = float(segment.get("crow_interval", 0.0))
	if crow_interval > 0.0:
		_crow_timer += delta
		if _crow_timer >= crow_interval:
			_crow_timer = 0.0
			requests.append({"type": "crow_line", "id": wave.crow_id, "count": wave.crow_line_count})
	else:
		_crow_timer = 0.0
	return requests

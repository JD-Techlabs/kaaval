class_name Fx
extends Node2D
## Lightweight juice: expanding rings and small square particles, all drawn by
## this one node. Hard caps keep it inside the frame budget.

const MAX_PARTICLES: int = 260
const MAX_RINGS: int = 40
const RING_SECONDS: float = 0.28

var _particles: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func ring(pos: Vector2, radius: float, color: Color, seconds: float = RING_SECONDS) -> void:
	if _rings.size() >= MAX_RINGS:
		_rings.pop_front()
	_rings.append({"pos": pos, "radius": radius, "color": color, "t": 0.0, "life": seconds})


func burst(pos: Vector2, color: Color, amount: int, speed: float = 220.0, size: float = 7.0, life: float = 0.4) -> void:
	for i: int in amount:
		if _particles.size() >= MAX_PARTICLES:
			return
		var velocity: Vector2 = Vector2.from_angle(_rng.randf() * TAU) * speed * _rng.randf_range(0.4, 1.0)
		_particles.append({"pos": pos, "vel": velocity, "color": color, "size": size, "t": 0.0, "life": life})


func particle_count() -> int:
	return _particles.size()


func step(delta: float) -> void:
	if _particles.is_empty() and _rings.is_empty():
		return
	for i: int in range(_particles.size() - 1, -1, -1):
		var particle: Dictionary = _particles[i]
		particle["t"] = float(particle["t"]) + delta
		if float(particle["t"]) >= float(particle["life"]):
			_particles.remove_at(i)
			continue
		var vel: Vector2 = particle["vel"]
		var pos: Vector2 = particle["pos"]
		particle["pos"] = pos + vel * delta
		particle["vel"] = vel * (1.0 - minf(3.0 * delta, 1.0))
	for i: int in range(_rings.size() - 1, -1, -1):
		var entry: Dictionary = _rings[i]
		entry["t"] = float(entry["t"]) + delta
		if float(entry["t"]) >= float(entry["life"]):
			_rings.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for entry: Dictionary in _rings:
		var progress: float = float(entry["t"]) / float(entry["life"])
		var color: Color = entry["color"]
		var pos: Vector2 = entry["pos"]
		var radius: float = float(entry["radius"]) * (0.35 + 0.65 * progress)
		color.a = (1.0 - progress) * 0.25
		draw_circle(pos, radius, color)
		color.a = 1.0 - progress
		draw_arc(pos, radius, 0.0, TAU, 36, color, 6.0)
	for particle: Dictionary in _particles:
		var progress: float = float(particle["t"]) / float(particle["life"])
		var color: Color = particle["color"]
		color.a = 1.0 - progress
		var size: float = float(particle["size"]) * (1.0 - progress * 0.5)
		var pos: Vector2 = particle["pos"]
		draw_rect(Rect2(pos - Vector2(size, size) * 0.5, Vector2(size, size)), color)

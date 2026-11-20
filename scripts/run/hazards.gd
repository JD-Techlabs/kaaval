class_name Hazards
extends Node2D
## Boss attacks: telegraphed ground circles, charge warning lines and bright
## bullets. Drawn in one _draw call; nothing here uses physics.

const TELEGRAPH_COLOR: Color = Color(1.0, 0.2, 0.2, 0.3)
const TELEGRAPH_EDGE: Color = Color(1.0, 0.35, 0.3, 0.95)
const BULLET_COLOR: Color = Color(1.0, 0.95, 0.5)
const BULLET_CORE: Color = Color(1.0, 0.4, 0.2)

var run: RunManager
var _circles: Array[Dictionary] = []
var _lines: Array[Dictionary] = []
var _bullets: Array[Dictionary] = []


func add_circle(pos: Vector2, radius: float, delay: float, damage: float) -> void:
	_circles.append({"pos": pos, "radius": radius, "delay": delay, "t": 0.0, "damage": damage})


func add_line(from: Vector2, to: Vector2, width: float, duration: float) -> void:
	_lines.append({"from": from, "to": to, "width": width, "t": duration})


func add_bullet(pos: Vector2, velocity: Vector2, radius: float, damage: float, life: float) -> void:
	_bullets.append({"pos": pos, "vel": velocity, "radius": radius, "damage": damage, "life": life})


func bullet_count() -> int:
	return _bullets.size()


func clear() -> void:
	_circles.clear()
	_lines.clear()
	_bullets.clear()
	queue_redraw()


func step(delta: float) -> void:
	if _circles.is_empty() and _lines.is_empty() and _bullets.is_empty():
		return
	var hero: Vector2 = run.player.position
	var hero_radius: float = GameData.num("combat", "player_radius")
	for i: int in range(_circles.size() - 1, -1, -1):
		var circle: Dictionary = _circles[i]
		circle["t"] = float(circle["t"]) + delta
		if float(circle["t"]) >= float(circle["delay"]):
			var pos: Vector2 = circle["pos"]
			var radius: float = circle["radius"]
			run.fx.ring(pos, radius, Color(0.5, 0.9, 0.6))
			if pos.distance_to(hero) <= radius + hero_radius * 0.5:
				run.player.take_damage(float(circle["damage"]))
			_circles.remove_at(i)
	for i: int in range(_lines.size() - 1, -1, -1):
		var line: Dictionary = _lines[i]
		line["t"] = float(line["t"]) - delta
		if float(line["t"]) <= 0.0:
			_lines.remove_at(i)
	for i: int in range(_bullets.size() - 1, -1, -1):
		var bullet: Dictionary = _bullets[i]
		var pos: Vector2 = bullet["pos"]
		var vel: Vector2 = bullet["vel"]
		pos += vel * delta
		bullet["pos"] = pos
		bullet["life"] = float(bullet["life"]) - delta
		var hit: bool = pos.distance_to(hero) <= float(bullet["radius"]) + hero_radius
		if hit:
			run.player.take_damage(float(bullet["damage"]))
		if hit or float(bullet["life"]) <= 0.0:
			_bullets.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for circle: Dictionary in _circles:
		var pos: Vector2 = circle["pos"]
		var radius: float = circle["radius"]
		var progress: float = clampf(float(circle["t"]) / maxf(float(circle["delay"]), 0.01), 0.0, 1.0)
		draw_circle(pos, radius, TELEGRAPH_COLOR)
		draw_circle(pos, radius * progress, TELEGRAPH_COLOR)
		draw_arc(pos, radius, 0.0, TAU, 40, TELEGRAPH_EDGE, 5.0)
	for line: Dictionary in _lines:
		var from: Vector2 = line["from"]
		var to: Vector2 = line["to"]
		draw_line(from, to, TELEGRAPH_COLOR, float(line["width"]) * 2.0)
	for bullet: Dictionary in _bullets:
		var pos: Vector2 = bullet["pos"]
		var radius: float = bullet["radius"]
		draw_circle(pos, radius, BULLET_COLOR)
		draw_circle(pos, radius * 0.5, BULLET_CORE)

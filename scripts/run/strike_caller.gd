class_name StrikeCaller
extends Node2D
## Called-in strikes from the hero's weapon line in later ages:
## - tank: drives across the view below the hero (its row follows the hero), firing explosive shells;
## - jet: flies across the view through a creature, hitting all along its path;
## - missiles: a volley of explosive missiles from the hero at the nearest creatures.
## Numbers come from the strike data; cooldowns scale with the hero's cooldown.
## Vehicles are drawn on a screen layer above the night's darkness so they stay
## visible away from the hero's light; their world position is kept in "pos".

const FIRST_DELAY: float = 3.0
const TANK_SPEED: float = 260.0
const TANK_ROW: float = 0.3
const SHELL_SPEED: float = 1000.0
const SHELL_RANGE: float = 900.0
const JET_SPEED: float = 1500.0
const MISSILE_SPEED: float = 950.0
const MISSILE_RANGE: float = 1100.0
const PROJECTILE_RADIUS: float = 18.0
const PROJECTILE_LIFE: float = 1.6
## Above the darkness (layer 1); the run UI shares layer 2 and is added later, so it stays on top.
const OVERLAY_LAYER: int = 2

var run: RunManager
## [{"data": strike, "left": seconds}]
var _strikes: Array[Dictionary] = []
## Moving vehicles: {"type", "sprite", "vel", "end_x", "fire_every", "fire_left", "data", "hit"}
var _vehicles: Array[Dictionary] = []
var _overlay: CanvasLayer


func _ready() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = OVERLAY_LAYER
	add_child(_overlay)


func setup(p_run: RunManager, strikes: Array[Dictionary]) -> void:
	run = p_run
	for strike: Dictionary in strikes:
		_strikes.append({"data": strike, "left": FIRST_DELAY})


func strike_count() -> int:
	return _strikes.size()


func vehicle_count() -> int:
	return _vehicles.size()


func step(delta: float) -> void:
	for entry: Dictionary in _strikes:
		entry["left"] = float(entry["left"]) - delta
		if float(entry["left"]) <= 0.0 and call_strike(entry["data"]):
			entry["left"] = float((entry["data"] as Dictionary).get("cooldown", 10.0)) * run.player.stats.cooldown_mult
	for i: int in range(_vehicles.size() - 1, -1, -1):
		if not _move(_vehicles[i], delta):
			(_vehicles[i]["sprite"] as Sprite2D).queue_free()
			_vehicles.remove_at(i)


func _damage(strike: Dictionary) -> float:
	return float(strike.get("damage", 0.0)) * run.player.stats.damage_mult


## Starts one strike. Returns false when there is nothing to strike yet.
func call_strike(strike: Dictionary) -> bool:
	match str(strike.get("type", "")):
		"tank":
			return _start_tank(strike)
		"jet":
			return _start_jet(strike)
		"missiles":
			return _fire_missiles(strike)
	return false


func _vehicle(strike: Dictionary, texture_name: String, pos: Vector2, vel: Vector2, end_x: float) -> Dictionary:
	var sprite_node: Sprite2D = Sprite2D.new()
	sprite_node.texture = BaseWeapon.tex(texture_name)
	sprite_node.flip_h = vel.x < 0.0
	_overlay.add_child(sprite_node)
	var vehicle: Dictionary = {"type": str(strike["type"]), "sprite": sprite_node, "pos": pos, "vel": vel, "end_x": end_x,
		"data": strike, "hit": {}, "fire_every": 0.0, "fire_left": 0.0}
	_vehicles.append(vehicle)
	_place(vehicle)
	return vehicle


## Screen position and size of a vehicle from its world position.
func _place(vehicle: Dictionary) -> void:
	var sprite_node: Sprite2D = vehicle["sprite"]
	sprite_node.position = run.to_screen(vehicle["pos"])
	sprite_node.scale = Vector2.ONE * run.zoom


## The tank's path is kept relative to the hero ("offset"), so it crosses the
## screen even while the hero runs.
func _start_tank(strike: Dictionary) -> bool:
	var view: Rect2 = run.view_rect()
	var left_to_right: bool = run.rng.randf() < 0.5
	var half: float = view.size.x * 0.5 + 80.0
	var start_x: float = -half if left_to_right else half
	var end_x: float = half if left_to_right else -half
	var vel: Vector2 = Vector2(TANK_SPEED if left_to_right else -TANK_SPEED, 0.0)
	var offset: Vector2 = Vector2(start_x, view.size.y * TANK_ROW)
	var vehicle: Dictionary = _vehicle(strike, "tank", run.player.position + offset, vel, end_x)
	vehicle["offset"] = offset
	var crossing: float = absf(end_x - start_x) / TANK_SPEED
	vehicle["fire_every"] = crossing / maxf(float(strike.get("count", 4)), 1.0)
	vehicle["fire_left"] = float(vehicle["fire_every"]) * 0.5
	AudioManager.play("drum", 0.7)
	return true


func _start_jet(strike: Dictionary) -> bool:
	var target: Enemy = run.enemies.random_in_rect(run.view_rect(), run.rng)
	if target == null:
		return false
	var view: Rect2 = run.view_rect()
	var left_to_right: bool = run.rng.randf() < 0.5
	var start_x: float = view.position.x - 120.0 if left_to_right else view.end.x + 120.0
	var end_x: float = view.end.x + 120.0 if left_to_right else view.position.x - 120.0
	_vehicle(strike, "jet", Vector2(start_x, target.position.y), Vector2(JET_SPEED if left_to_right else -JET_SPEED, 0.0), end_x)
	AudioManager.play("whoosh", 0.6)
	return true


func _fire_missiles(strike: Dictionary) -> bool:
	var origin: Vector2 = run.player.position
	var targets: Array[Enemy] = run.enemies.nearest(origin, MISSILE_RANGE, int(strike.get("count", 3)))
	if targets.is_empty():
		return false
	for target: Enemy in targets:
		_shell(origin, target.position, strike, "missile", MISSILE_SPEED)
	AudioManager.play("whoosh", 0.8)
	return true


func _shell(from: Vector2, to: Vector2, strike: Dictionary, texture_name: String, speed: float) -> void:
	var direction: Vector2 = (to - from).normalized()
	var projectile: Projectile = run.projectiles.fire(BaseWeapon.tex(texture_name), from, direction * speed,
		_damage(strike), 1, PROJECTILE_RADIUS, PROJECTILE_LIFE)
	projectile.explode_radius = float(strike.get("area", 80.0)) * run.player.stats.area_mult


## Moves one vehicle and lets it act. Returns false once it has left the view.
func _move(vehicle: Dictionary, delta: float) -> bool:
	var vel: Vector2 = vehicle["vel"]
	var pos: Vector2 = (vehicle["pos"] as Vector2) + vel * delta
	var progress_x: float = pos.x
	if vehicle.has("offset"):
		var offset: Vector2 = (vehicle["offset"] as Vector2) + vel * delta
		vehicle["offset"] = offset
		pos = run.player.position + offset
		progress_x = offset.x
	vehicle["pos"] = pos
	_place(vehicle)
	var strike: Dictionary = vehicle["data"]
	match str(vehicle["type"]):
		"tank":
			vehicle["fire_left"] = float(vehicle["fire_left"]) - delta
			if float(vehicle["fire_left"]) <= 0.0:
				vehicle["fire_left"] = vehicle["fire_every"]
				var targets: Array[Enemy] = run.enemies.nearest(pos, SHELL_RANGE, 1)
				if not targets.is_empty():
					_shell(pos, targets[0].position, strike, "shell", SHELL_SPEED)
		"jet":
			var hit: Dictionary = vehicle["hit"]
			var amount: float = _damage(strike)
			for enemy: Enemy in run.enemies.query_circle(pos, float(strike.get("area", 100.0)) * run.player.stats.area_mult):
				var key: int = enemy.get_instance_id()
				if not hit.has(key):
					hit[key] = true
					run.enemies.damage(enemy, amount)
	var end_x: float = vehicle["end_x"]
	return progress_x < end_x if vel.x > 0.0 else progress_x > end_x

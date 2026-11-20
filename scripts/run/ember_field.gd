class_name EmberField
extends MultiMeshInstance2D
## Spirit Embers (XP). Stored as flat arrays and drawn with one MultiMesh, so
## hundreds of embers cost a single draw call. Merges when the map gets crowded.

const CAPACITY: int = 512
const EMBER_SIZE: float = 30.0

var _pos: PackedVector2Array = PackedVector2Array()
var _value: PackedFloat32Array = PackedFloat32Array()
var _pulled: PackedByteArray = PackedByteArray()
var _merge_threshold: int
var _merge_group: int
var _magnet_speed: float
var _collect_dist: float
## How many embers the last step() collected.
var collected_count: int = 0


func _ready() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(EMBER_SIZE, EMBER_SIZE)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.mesh = quad
	multimesh.instance_count = CAPACITY
	multimesh.visible_instance_count = 0
	texture = load("res://assets/sprites/ember.svg") as Texture2D
	_merge_threshold = int(GameData.num("embers", "merge_threshold"))
	_merge_group = int(GameData.num("embers", "merge_group"))
	_magnet_speed = GameData.num("embers", "magnet_speed")
	_collect_dist = GameData.num("embers", "collect_distance")


func count() -> int:
	return _pos.size()


func add(pos: Vector2, value: float) -> void:
	if value <= 0.0:
		return
	_pos.append(pos)
	_value.append(value)
	_pulled.append(0)
	if _pos.size() > _merge_threshold:
		_merge()


## Moves pulled embers toward the hero; returns the XP value collected this step.
func step(delta: float, hero: Vector2, pickup_radius: float) -> float:
	var gained: float = 0.0
	collected_count = 0
	var pickup_sq: float = pickup_radius * pickup_radius
	var collect_sq: float = _collect_dist * _collect_dist
	var i: int = _pos.size() - 1
	while i >= 0:
		var offset: Vector2 = hero - _pos[i]
		var dist_sq: float = offset.length_squared()
		if _pulled[i] == 0 and dist_sq <= pickup_sq:
			_pulled[i] = 1
		if _pulled[i] == 1:
			if dist_sq <= collect_sq:
				gained += _value[i]
				collected_count += 1
				_remove(i)
				i -= 1
				continue
			_pos[i] += offset.normalized() * minf(_magnet_speed * delta, sqrt(dist_sq))
		i -= 1
	_sync()
	return gained


## Position of the closest ember within range, or Vector2.INF.
func nearest(pos: Vector2, max_range: float) -> Vector2:
	var best: Vector2 = Vector2.INF
	var best_dist: float = max_range * max_range
	for i: int in _pos.size():
		var dist: float = _pos[i].distance_squared_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = _pos[i]
	return best


## Removes embers in a circle and returns their total value (Lantern Thief).
func steal(pos: Vector2, radius: float) -> float:
	var taken: float = 0.0
	var radius_sq: float = radius * radius
	for i: int in range(_pos.size() - 1, -1, -1):
		if _pos[i].distance_squared_to(pos) <= radius_sq:
			taken += _value[i]
			_remove(i)
	return taken


func _remove(index: int) -> void:
	var last: int = _pos.size() - 1
	_pos[index] = _pos[last]
	_value[index] = _value[last]
	_pulled[index] = _pulled[last]
	_pos.resize(last)
	_value.resize(last)
	_pulled.resize(last)


## Folds the oldest embers together, `_merge_group` at a time.
func _merge() -> void:
	var groups: int = 10
	for g: int in groups:
		if _pos.size() <= _merge_group:
			return
		var total: float = 0.0
		var centre: Vector2 = Vector2.ZERO
		for k: int in _merge_group:
			total += _value[0]
			centre += _pos[0]
			_remove(0)
		add(centre / float(_merge_group), total)


func _sync() -> void:
	var n: int = mini(_pos.size(), CAPACITY)
	multimesh.visible_instance_count = n
	for i: int in n:
		var s: float = clampf(0.8 + _value[i] * 0.06, 0.8, 2.2)
		multimesh.set_instance_transform_2d(i, Transform2D(0.0, Vector2(s, -s), 0.0, _pos[i]))

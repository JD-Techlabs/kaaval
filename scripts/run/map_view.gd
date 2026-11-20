class_name MapView
extends Node2D
## "Forest Edge": a clearing bounded by tree walls, with non-colliding props.

const GROUND_OUTSIDE: Color = Color(0.03, 0.09, 0.09)
const GROUND: Color = Color(0.09, 0.2, 0.17)
const GROUND_PATCH: Color = Color(0.11, 0.24, 0.19)
const TREE_SPACING: float = 130.0
const PATCHES: int = 90
const PROPS: int = 70
const MARGIN: float = 1400.0

var map_size: Vector2 = Vector2(4000, 4000)
var _patches: Array[Vector3] = []


func setup(p_map_size: Vector2) -> void:
	map_size = p_map_size
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20240
	for i: int in PATCHES:
		_patches.append(Vector3(rng.randf() * map_size.x, rng.randf() * map_size.y, rng.randf_range(60.0, 220.0)))
	var prop_textures: Array[Texture2D] = [
		load("res://assets/sprites/rock.svg") as Texture2D,
		load("res://assets/sprites/bush.svg") as Texture2D,
		load("res://assets/sprites/lamp.svg") as Texture2D,
	]
	for i: int in PROPS:
		_add_sprite(prop_textures[rng.randi() % prop_textures.size()],
			Vector2(rng.randf_range(150.0, map_size.x - 150.0), rng.randf_range(150.0, map_size.y - 150.0)), 1.0)
	var tree: Texture2D = load("res://assets/sprites/tree.svg") as Texture2D
	var steps_x: int = ceili(map_size.x / TREE_SPACING)
	var steps_y: int = ceili(map_size.y / TREE_SPACING)
	for row: int in 2:
		var inset: float = -40.0 - row * 110.0
		for i: int in steps_x + 1:
			var x: float = i * TREE_SPACING + rng.randf_range(-25.0, 25.0)
			_add_sprite(tree, Vector2(x, inset), rng.randf_range(0.9, 1.25))
			_add_sprite(tree, Vector2(x, map_size.y - inset), rng.randf_range(0.9, 1.25))
		for i: int in steps_y + 1:
			var y: float = i * TREE_SPACING + rng.randf_range(-25.0, 25.0)
			_add_sprite(tree, Vector2(inset, y), rng.randf_range(0.9, 1.25))
			_add_sprite(tree, Vector2(map_size.x - inset, y), rng.randf_range(0.9, 1.25))
	queue_redraw()


func _add_sprite(tex: Texture2D, pos: Vector2, size: float) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	sprite.scale = Vector2(size, size)
	add_child(sprite)


func _draw() -> void:
	draw_rect(Rect2(Vector2(-MARGIN, -MARGIN), map_size + Vector2(MARGIN, MARGIN) * 2.0), GROUND_OUTSIDE)
	draw_rect(Rect2(Vector2.ZERO, map_size), GROUND)
	for patch: Vector3 in _patches:
		draw_circle(Vector2(patch.x, patch.y), patch.z, GROUND_PATCH)

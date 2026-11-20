class_name RunEvents
extends RefCounted
## Carries out spawn requests from the Spawner (regular spawns, crow lines,
## ring swarms, bosses with their 2 s warning) and manages boss chests.

const CHEST_TEXTURE: String = "res://assets/sprites/chest.svg"

var run: RunManager
var _pending_bosses: Array[Dictionary] = []
var _chests: Array[Sprite2D] = []


func _init(p_run: RunManager) -> void:
	run = p_run


func execute(request: Dictionary) -> void:
	var id: String = str(request["id"])
	match str(request["type"]):
		"enemy":
			if _has_room(1):
				# The wave table sets the pace; the hero's level decides who shows up.
				var choice: Dictionary = Roster.pick(run.state.level, id, run.rng.randf(), run.rng.randf())
				run.enemies.spawn(GameData.enemy(str(choice["enemy"])), run.random_ring_point(), int(choice["rank"]))
		"ring":
			_ring(GameData.enemy(id), int(request["count"]))
		"crow_line":
			_crow_line(GameData.enemy(id), int(request["count"]))
		"boss":
			var boss: BossData = GameData.boss(id)
			_pending_bosses.append({"data": boss, "t": GameData.num("run", "boss_warning_seconds")})
			run.banner_requested.emit(boss.warning_text)
			AudioManager.play("boss")
			AudioManager.haptic(40)


func step(delta: float) -> void:
	for i: int in range(_pending_bosses.size() - 1, -1, -1):
		var entry: Dictionary = _pending_bosses[i]
		entry["t"] = float(entry["t"]) - delta
		if float(entry["t"]) <= 0.0:
			run.enemies.spawn_boss(entry["data"], run.random_ring_point())
			_pending_bosses.remove_at(i)
	var reach: float = GameData.num("boss_chest", "pickup_radius")
	for i: int in range(_chests.size() - 1, -1, -1):
		if _chests[i].position.distance_to(run.player.position) <= reach:
			_chests[i].queue_free()
			_chests.remove_at(i)
			run.open_chest()
			return


func chest_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for chest: Sprite2D in _chests:
		out.append(chest.position)
	return out


func drop_chest(pos: Vector2) -> void:
	var chest: Sprite2D = Sprite2D.new()
	chest.texture = load(CHEST_TEXTURE) as Texture2D
	chest.position = pos
	run.hazards.add_sibling(chest)
	_chests.append(chest)


func _has_room(amount: int) -> bool:
	return run.enemies.room() >= amount


func _ring(data: EnemyData, amount: int) -> void:
	run.enemies.spawn_around(data, run.player.position, amount, run.wave.ring_radius)


## A row of crows that flies straight across the screen.
func _crow_line(data: EnemyData, amount: int) -> void:
	if not _has_room(amount):
		return
	var view: Rect2 = run.view_rect().grow(GameData.num("spawn", "ring_margin"))
	var horizontal: bool = run.rng.randf() < 0.5
	var forward: bool = run.rng.randf() < 0.5
	var direction: Vector2 = (Vector2.RIGHT if horizontal else Vector2.DOWN) * (1.0 if forward else -1.0)
	var across: Vector2 = Vector2.DOWN if horizontal else Vector2.RIGHT
	var start: Vector2 = run.player.position - direction * (view.size.x if horizontal else view.size.y) * 0.5
	var travel: float = (view.size.x if horizontal else view.size.y) + 300.0
	for i: int in amount:
		var offset: float = (float(i) - float(amount - 1) * 0.5) * run.wave.crow_line_spacing
		var crow: Enemy = run.enemies.spawn(data, start + across * offset)
		crow.direction = direction
		crow.travel_left = travel
		crow.flip_h = direction.x < 0.0

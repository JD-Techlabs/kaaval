extends BaseWeapon
## Thorn Whip: a horizontal lash in front of the hero (both sides from L3).

const SHOW_SECONDS: float = 0.16
const WHIP_COLOR: Color = Color(0.5, 0.9, 0.45)

var _show_left: float = 0.0
var _sides: Array[float] = []
var _width: float = 0.0
var _height: float = 0.0


func fire() -> bool:
	_width = area("width")
	_height = area("height")
	_sides = [run.player.facing_x]
	if int(stat("sides")) >= 2:
		_sides.append(-run.player.facing_x)
	var origin: Vector2 = run.player.position
	var hit_damage: float = damage()
	for enemy: Enemy in run.enemies.query_circle(origin, _width + _height):
		var offset: Vector2 = enemy.position - origin
		if absf(offset.y) > _height * 0.5 + enemy.radius:
			continue
		for side: float in _sides:
			var along: float = offset.x * side
			if along >= -enemy.radius and along <= _width + enemy.radius:
				run.enemies.damage(enemy, hit_damage, Vector2(side * 120.0, 0.0))
				break
	_show_left = SHOW_SECONDS
	queue_redraw()
	AudioManager.play("whoosh", 0.7)
	return true


func step(delta: float) -> void:
	super.step(delta)
	if _show_left > 0.0:
		_show_left -= delta
		queue_redraw()


func _draw() -> void:
	if _show_left <= 0.0:
		return
	var alpha: float = _show_left / SHOW_SECONDS
	for side: float in _sides:
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 13:
			var t: float = float(i) / 12.0
			points.append(Vector2(side * (20.0 + _width * t), -sin(t * PI) * _height * 0.5 + _height * 0.15))
		draw_polyline(points, Color(WHIP_COLOR, alpha), 14.0)
		draw_polyline(points, Color(1.0, 1.0, 0.8, alpha), 4.0)

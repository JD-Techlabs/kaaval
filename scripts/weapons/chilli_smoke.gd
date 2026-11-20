extends BaseWeapon
## Chilli Smoke / Ghost Pepper Miasma: damaging aura around the hero.

const SMOKE_COLOR: Color = Color(0.9, 0.3, 0.2, 0.14)
const SMOKE_EDGE: Color = Color(1.0, 0.45, 0.3, 0.4)
const MIASMA_COLOR: Color = Color(0.6, 0.9, 0.4, 0.14)
const MIASMA_EDGE: Color = Color(0.7, 1.0, 0.5, 0.4)

var _tick_left: float = 0.0
var _kills: int = 0
var _radius: float = 0.0


func refresh() -> void:
	queue_redraw()


func step(delta: float) -> void:
	var radius: float = area("radius")
	if not is_equal_approx(radius, _radius):
		_radius = radius
		queue_redraw()
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = stat("tick")
	var hit_damage: float = damage()
	for enemy: Enemy in run.enemies.query_circle(run.player.position, _radius):
		if run.enemies.damage(enemy, hit_damage):
			_kills += 1
	var heal_kills: int = int(stat("heal_kills"))
	if heal_kills > 0 and _kills >= heal_kills:
		@warning_ignore("integer_division")
		var heals: int = _kills / heal_kills
		_kills -= heals * heal_kills
		run.player.heal(stat("heal_amount") * heals)


func _draw() -> void:
	if _radius <= 0.0:
		return
	var evolved: bool = evolution != null
	draw_circle(Vector2.ZERO, _radius, MIASMA_COLOR if evolved else SMOKE_COLOR)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, MIASMA_EDGE if evolved else SMOKE_EDGE, 4.0)

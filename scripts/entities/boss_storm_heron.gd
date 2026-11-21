extends Boss
## Storm Heron: sprays a turning spiral of feathers in bursts and dives at the
## hero between bursts. More spiral arms and more speed below 30% HP.

const ENRAGE_TINT: Color = Color(0.7, 0.85, 1.0)

var _phase_timer: float = 0.0
var _shot_timer: float = 0.0
var _angle: float = 0.0
var _firing: bool = true
var _enraged: bool = false


func attack(delta: float, mgr: EnemyManager) -> void:
	if not _enraged and hp <= max_hp * param("enrage_hp_pct"):
		_enraged = true
		speed *= param("enrage_speed_mult")
		modulate = ENRAGE_TINT
	if charge_state != Charge.NONE:
		return
	_phase_timer += delta
	if not _firing:
		if _phase_timer >= param("rest_time"):
			_firing = true
			_phase_timer = 0.0
		return
	_angle += param("spiral_turn") * delta
	_shot_timer -= delta
	if _shot_timer <= 0.0:
		_shot_timer = param("shot_interval")
		_fire(mgr)
	if _phase_timer >= param("burst_time"):
		_firing = false
		_phase_timer = 0.0
		begin_charge(mgr)


func _fire(mgr: EnemyManager) -> void:
	var arms: int = int(param("arms") + (param("enrage_extra_arms") if _enraged else 0.0))
	if mgr.run.hazards.bullet_count() + arms > int(param("max_bullets")):
		return
	for i: int in arms:
		var direction: Vector2 = Vector2.from_angle(_angle + TAU * float(i) / float(arms))
		mgr.run.hazards.add_bullet(position + direction * radius, direction * param("bullet_speed"),
			param("bullet_radius"), param("bullet_damage"), param("bullet_life"))

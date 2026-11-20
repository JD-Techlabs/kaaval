extends Boss
## Eclipse Beast: blacks out the screen (handled by Darkness via its
## light_radius param), cycles three attacks, enrages at 30% HP.

const ENRAGE_TINT: Color = Color(1.0, 0.55, 0.55)

var _timer: float = 0.0
var _pattern: int = 0
var _enraged: bool = false


func attack(delta: float, mgr: EnemyManager) -> void:
	if not _enraged and hp <= max_hp * param("enrage_hp_pct"):
		_enraged = true
		speed *= param("enrage_speed_mult")
		modulate = ENRAGE_TINT
	if charge_state != Charge.NONE:
		return
	_timer += delta
	var interval: float = param("pattern_interval") * (param("enrage_interval_mult") if _enraged else 1.0)
	if _timer < interval:
		return
	_timer = 0.0
	match _pattern:
		0:
			begin_charge(mgr)
		1:
			_bullet_ring(mgr)
		2:
			_roots(mgr)
	_pattern = (_pattern + 1) % 3


func _bullet_ring(mgr: EnemyManager) -> void:
	var amount: int = int(param("ring_bullets"))
	for i: int in amount:
		var direction: Vector2 = Vector2.from_angle(TAU * float(i) / float(amount))
		mgr.run.hazards.add_bullet(position + direction * radius, direction * param("bullet_speed"),
			param("bullet_radius"), param("bullet_damage"), param("bullet_life"))


func _roots(mgr: EnemyManager) -> void:
	var amount: int = int(param("root_count"))
	mgr.run.hazards.add_circle(mgr.target, param("root_radius"), param("root_delay"), param("root_damage"))
	for i: int in amount - 1:
		var offset: Vector2 = Vector2.from_angle(mgr.run.rng.randf() * TAU) * param("root_spread")
		mgr.run.hazards.add_circle(mgr.target + offset, param("root_radius"), param("root_delay"), param("root_damage"))

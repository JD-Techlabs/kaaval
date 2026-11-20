class_name Boss
extends Enemy
## Shared boss behaviour: slow chase plus a telegraphed line charge that the
## Thorn Queen and Eclipse Beast both use. Subclasses add their own attacks.

enum Charge { NONE, TELEGRAPH, RUSH }

var charge_state: Charge = Charge.NONE
var _charge_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO


func param(key: String) -> float:
	return float(data.params.get(key, 0.0))


func step(delta: float, mgr: EnemyManager) -> void:
	attack(delta, mgr)
	if charge_state == Charge.NONE:
		move_toward_point(mgr.target, delta)
	else:
		_step_charge(delta, mgr)


## Subclass hook, called every frame before movement.
func attack(_delta: float, _mgr: EnemyManager) -> void:
	pass


func begin_charge(mgr: EnemyManager) -> void:
	charge_state = Charge.TELEGRAPH
	_charge_timer = param("telegraph")
	_charge_dir = (mgr.target - position).normalized()
	var reach: float = param("charge_speed") * param("charge_time")
	mgr.run.hazards.add_line(position, position + _charge_dir * reach, radius, _charge_timer)


func _step_charge(delta: float, mgr: EnemyManager) -> void:
	_charge_timer -= delta
	if charge_state == Charge.TELEGRAPH:
		if _charge_timer <= 0.0:
			charge_state = Charge.RUSH
			_charge_timer = param("charge_time")
	else:
		position = mgr.run.clamp_to_map(position + _charge_dir * param("charge_speed") * delta)
		if _charge_timer <= 0.0:
			charge_state = Charge.NONE

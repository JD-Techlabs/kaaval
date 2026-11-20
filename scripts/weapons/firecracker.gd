extends BaseWeapon
## Firecracker Burst: lands on a random on-screen creature, then explodes.

const BURST_COLOR: Color = Color(1.0, 0.45, 0.3)

var _pending: Array[Dictionary] = []


func fire() -> bool:
	var target: Enemy = run.enemies.random_in_rect(run.view_rect(), run.rng)
	if target == null:
		return false
	_pending.append({"pos": target.position, "t": stat("fuse")})
	return true


func step(delta: float) -> void:
	super.step(delta)
	for i: int in range(_pending.size() - 1, -1, -1):
		var entry: Dictionary = _pending[i]
		entry["t"] = float(entry["t"]) - delta
		if float(entry["t"]) <= 0.0:
			_explode(entry["pos"])
			_pending.remove_at(i)


func _explode(pos: Vector2) -> void:
	var radius: float = area("area")
	var hit_damage: float = damage()
	for enemy: Enemy in run.enemies.query_circle(pos, radius):
		run.enemies.damage(enemy, hit_damage)
	run.fx.ring(pos, radius, BURST_COLOR)
	run.fx.burst(pos, Color(1.0, 0.85, 0.4), 10, 320.0)
	AudioManager.play("explode", 1.3)
